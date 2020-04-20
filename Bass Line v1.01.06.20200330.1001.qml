//---------------------------------------------------------------------
// BassLine\n MuseScore 3 plugin
//---------------------------------------------------------------------

//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Create bass line for diatonic accordion tablature from a MuseScore music score
//
//  Copyright (C) 2020  Jean-Michel Bencetti
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//=============================================================================

//--------------------------------------------------------------------------
/* Ce plugin ajoute une ligne Basse-Accord à une tablature obtenue par DiatonicTab sous MuseScore

  Auteur : Jean-Michel Bencetti
  Version courrante : 0.02
  Date : v0.00 : 2020-03-18 : développement initial
         v0.00.01 : avance par mesure
         v0.00.02 : avance elément
         v0.00.03 : ne regarde pas les mesures, mais la longeur du pattern
         v0.00.04 : utilise la voix 1 de la 2ème portée
         v0.00.05 : ajoute les silences tout seuls sur la portée tablature
         v0.00.06 : demande à l'utilisateur le pas pour mettre les silences
         v0.00.06.002 :  20200326 place la ligne Basse/Accord en verse 4 à cause de Corgeron qui utilise les 3 premiers
         v1.01.06.003 : déplacement des silences sur le bas de la porté
         v1.01.06.20200328 :  Relookage de la fenêtre
         v1.01.06.20200328.1407 :  Ajout du paramètre offsetY
         v1.01.06.20200330.1001 : débug sélection

----------------------------------------------------------------------------  */
 import QtQuick 2.2
 import MuseScore 3.0
 import QtQuick.Controls 1.1
 import QtQuick.Controls.Styles 1.3
 import QtQuick.Layouts 1.1
 import FileIO 3.0


 MuseScore {
 version: "1.01.06.20200330.1001"
 description: "Write Bass/Chord line on a diatonic accordion tablature"
 menuPath: "Plugins.DiatonicTab.BassLine"
 pluginType: "dialog"


 property int margin: 10

    width:  460
    height: 350

 //-----------------------------------------------------
 // Set here the language : FR = French, EN = English
    property string lang: "FR"
 //-----------------------------------------------------

property var globalCursor: null
property var startTick: 0
property var endTick: 0
property var fullScore:true

 //-----------------------------------------------------
 // Fichiers JSON pour la mémorisation des parametres
 //-----------------------------------------------------
    FileIO {
         id: myParameterFile
         source: homePath() + "/BassLine.json"
         onError: console.log(msg)
         }
 //-----------------------------------------------------
 // Critères à choisir dans la boîte de dialogue
 //-----------------------------------------------------
   property var parametres: {
         "numPattern" : 0,           // numéro du pattern
         "thePattern" : "",          // Pattern s'il provient de la saisie
         "pasSilence" : "1/4",       // pas pour poser les silences, noire par défaut
         "anacrouse"  : "OUI",       // Il y a une anacrouse dans la sélection
         "AccordsComplets" : "OUI",  // In affiche les accords complets ou simplifiés
         "offsetY"    : "-13.3",     // offsetY pour calage des la ligne Basses/AccordsComplets
   }

 // -------------------------------------------------------------------
 // Description de la fenêtre de dialogue
 //--------------------------------------------------------------------
  GridLayout {
       anchors.fill: parent
       anchors.margins: 10
       columns: 2
 Label {
       Layout.columnSpan : 2
       width: parent.width
       elide: Text.ElideNone
       horizontalAlignment: Qt.AlignCenter
       font.bold: true
       font.pointSize: 12.2
       text:  (lang == "FR") ? qsTr("Ligne Basses/Accords pour accordéon diatonique") :
                               qsTr("Bass/Chords line for diatonic accordion")
       }

      //------------------------------------------------
      // Choix du Pattern Basse/Accord
      //------------------------------------------------
      GroupBox {
          Layout.columnSpan : 2
          Layout.fillWidth: true
          width: parent.width
          title : (lang == "FR") ? qsTr("Choix du Pattern : ") :
                                   qsTr("Pattern choice : ")
        GridLayout {
            columns : 2
            Layout.fillWidth: true
            width: parent.width
            Label {
                   width: parent.width
                   wrapMode: Label.Wrap
                   horizontalAlignment: Qt.AlignRight
                   text:  (lang == "FR") ? qsTr("Patterns de base : ") :
                                           qsTr("Basic patterns : ")
             }
             ComboBox {
                    id: comboChoixPattern
                    editable: false
                    model:  [
                    // La liste de choix doit être dans le même ordre que le tableau tabmodeleClavier
                    // La liste de choix doit être dans le même ordre que le tableau tabmodeleClavier
                          { text:  qsTr("2/2 Ba")        },
                          { text:  qsTr("2/4 BaBa")      },
                          { text:  qsTr("2/4 Ba")        },
                          { text:  qsTr("3/4 Baa")       },
                          { text:  qsTr("3/4 BaB")       },
                          { text:  qsTr("3/4 B-B")       },
                          { text:  qsTr("4/4 BaBa")      },
                          { text:  qsTr("4/4 Ba-a")      },
                          { text:  qsTr("5/4 BaaBa")     },
                          { text:  qsTr("5/4 BaBaa")     },
                          { text:  qsTr("6/8 B-aB-a")    },
                          { text:  qsTr("6/8 BaaBaa")    },
                          { text:  qsTr("7/8 BaaBaBa")   },
                          { text:  qsTr("7/8 BaBaBaa")   },
                          { text:  qsTr("7/8 B-aBaBa")   },
                          { text:  qsTr("7/8 B--a-a-")   },
                          { text:  qsTr("8/8 BaaBaaBa")  },
                          { text:  qsTr("8/8 BaaBaBaa")  },
                          { text:  qsTr("9/8 B-aB-aB-a") },
                          { text:  qsTr("9/8 BaaBaaBaa") },
                          { text:  qsTr("12/8 B-aB-aB-aB-a")},
                    ]
                   // Récupère le code du modèle de clavier
                   onActivated: { parametres["numPattern"] = index
                                  parametres["thePattern"] = model[index].text
                                  console.log("Pattern : " + model[index].text)
                                  inputTextPattern.text = model[index].text.replace(/(\d+)\/(\d+)\s(\w+)/,"$3")
                                 }

               } // comboBox
           Label {
                   width: parent.width
                   Layout.columnSpan : 2
                   Layout.fillWidth: true
                   wrapMode: Label.Wrap
                   horizontalAlignment: Qt.AlignCenter
                   text:  (lang == "FR") ? qsTr("Ou") :
                                           qsTr("Or")
           }
           //------------------------------------------------
           // Pattern personnalisé
           //------------------------------------------------
          Label {
                    width: parent.width / 2
                    wrapMode: Label.Wrap
                    horizontalAlignment: Qt.AlignRight
                    text:  (lang == "FR") ? qsTr("Pattern personnalisé : ") :
                                            qsTr("Personalised pattern : ")
          }
          TextField {
                    id : inputTextPattern

                    placeholderText : "BaaBaa"
                    onEditingFinished : {
                         console.log("inputTextPattern = " + text)
                         parametres["thePattern"] = text
                    }
          }
        } // GridLayout
 } // GroupBox
 GroupBox {
     Layout.columnSpan : 2
     Layout.fillWidth: true
     width: parent.width
     title : (lang == "FR") ? qsTr("Basses/Accords : ") :
                              qsTr("Bass/Chords : ")
   GridLayout {
       columns : 2
       Layout.fillWidth: true
       width: parent.width

       //------------------------------------------------
       // Choix du pas pour poser les Basses/Accords
       //------------------------------------------------
       Label {
                           width: parent.width
                           wrapMode: Label.Wrap
                           horizontalAlignment: Qt.AlignRight
                           text:  (lang == "FR") ? qsTr("Durée des Basses et des Accords : ") :
                                                   qsTr("Bass and chords length : ")
       }
       ComboBox {
                     id: comboChoixPasSilence
                     editable: false
                           model:  [
                           // La liste de choix doit être dans le même ordre que le tableau tabmodeleClavier
                           { text: (lang=="FR") ? "Noire":"Quarter note", value:"1/4"      }, // soupir
                           { text: (lang=="FR") ? "Croche":"Eighth note", value:"1/8"      }, // demi soupir
                           { text: (lang=="FR") ? "Double croche":"sixteenth note", value:"1/16"     }, // Quart de soupir
                           ]
                    // Récupère le code du modèle de clavier
                    onActivated: { parametres["pasSilence"] = index
                                   parametres["pasSilence"] = model[index].value
                                   // console.log("pasSilence : " + model[index].text)
                                  }

        }
      } // GroupBox
 } // GridLayout
 //------------------------------------------------
 // Anacrouze et accords complets
 //------------------------------------------------
 GroupBox {
     Layout.columnSpan : 2
     Layout.fillWidth: true
     width: parent.width
     title : (lang == "FR") ? qsTr("Autre : ") :
                              qsTr("Other : ")
     GridLayout {
       Layout.fillWidth: true
       width: parent.width
       columns: 2
        CheckBox {
             id: cbAnacrouse
             Layout.columnSpan: 1
             text: (lang == "FR" ) ? qsTr("Il y a une anacrouse") :
                                     qsTr("Anacrouse on first measure")
             checked: parametres.anacrouse == "OUI"

        }
        CheckBox {
             id: cbAccordsComplets
             Layout.columnSpan: 1
             text: (lang == "FR" ) ? qsTr("Afficher les accords complets") :
                                     qsTr("Write full chords")
             checked: parametres.AccordsComplets == "OUI"

        }

        Label {
              // width: parent.width /2
              wrapMode: Label.Wrap
              Layout.fillWidth: true
              horizontalAlignment: Qt.AlignRight
              text:  (lang == "FR") ? qsTr("Position de la ligne (Décalage Y) : ") :
                                      qsTr("Line position (Y Offset)          : ")
        }
        TextField {
              // width:parent.width/2
              // Layout.fillWidth: true
              // ToolTip.visible: down
              // ToolTip.text: qsTr("espacement comme dans l'inspecteur")
              id : inputTextoffsetY
              text : parametres.offsetY
              horizontalAlignment: Qt.AlignRight
              onEditingFinished : {
                  parametres.offsetY = text
                  console.log("Décalage y = " + parametres.offsetY)
              }
        }

      } // RowLayout
    } // GroupBox
         //-----------------------------------------------
   RowLayout {
       Layout.fillWidth: true
       width: parent.width
       Layout.alignment: Qt.AlignCenter
       Layout.columnSpan: 2

       Button {
          id: okButton
          isDefault: true
          text: qsTr("OK")
          onClicked: {
              // Mémorise les parametres pour la prochaine fois
              parametres.thePattern = inputTextPattern.text
              parametres.offsetY    = inputTextoffsetY.text
             curScore.startCmd();
             // Gestion du curseur global
              // -----------------------------------------------------------------------
              // Cherche à savoir s'il s'agit de la partition entière ou d'une sélection
              globalCursor = curScore.newCursor()
              globalCursor.staffIdx = 1                     // On ne traite que la portée numéro 2
              globalCursor.rewind(Cursor.SELECTION_START)           // rembobine au début de la sélection
              if (!globalCursor.segment) {                          // pas de sélection
                  fullScore = true
              } else {
                  fullScore = false
                  globalCursor.rewind(Cursor.SELECTION_END)         // passe derrière le dernier segment et fixe tick = 0
                  if (globalCursor.tick === 0) {                    // ceci survient lorsque la sélection contient la dernière mesure
                       endTick = curScore.lastSegment.tick + 1;
                  } else {
                       endTick = globalCursor.tick
                  }
              }
              // -----------------------------------------------------------------------
              if (fullScore) {                             // si pas de sélection
                console.log("Pas de sélection")
                  globalCursor.rewind(Cursor.SCORE_START)        // rembobine au début de la partition
              } else {                                     // si sélection
                 console.log("Il y a une sélection")
                  globalCursor.rewind(Cursor.SELECTION_START)    // rembobine au début de la sélection
              }
              startTick = globalCursor.tick
              // Ajoute les silences
              if (!addSilences()) {
                   console.log(qsTr("Il faut au moins 2 portées dans la partition"))
                   Qt.quit()
              }
              // Création de la ligne Basse/Accord
             doBassLine();
              // ---------------------------------
             curScore.endCmd();

             myParameterFile.write(JSON.stringify(parametres))
             Qt.quit();
          }
       }
 Button {
          id: cancelButton
          text: (lang=="FR")?qsTr( "Annuler"):qsTr("Cancel")
          onClicked: {
             Qt.quit();
          }
       }
     } // RowLayout des boutons

   Label {
       Layout.columnSpan: 2
       Layout.fillWidth: true
       width: parent.width
       wrapMode: Label.Wrap
       horizontalAlignment: Qt.AlignCenter
       text:  "v" + version
   }
 } // GridLayout général

 // ---------------------------------------------------------------------
 // Fonction addSilence
 // Cette fonction ajoute des silences sur la portée numéro 2 pour y placer
 // les Basses et les Accords de la ligne Basses/Accords
 // Ne fonctionne que s'il y a deux portées dans la partition
 // ---------------------------------------------------------------------
 function addSilences() {

      if (curScore.nbstaves <2) return false  // Il faut que la portée numéro 2 existe
      globalCursor.staffIdx = 1                     // On ne traite que la portée numéro 2
       // -----------------------------------------------------------------------
       if (fullScore) {                             // si pas de sélection
            console.log("Pas de sélection")
            globalCursor.rewind(Cursor.SCORE_START)        // rembobine au début de la partition
       } else {                                     // si sélection
            console.log("Il y a une sélection")
            globalCursor.rewind(Cursor.SCORE_START)
            while (globalCursor.element && (globalCursor.tick < startTick)) globalCursor.next()
       }
       // -----------------------------------------------------------------------
       // Ajouts de notes selon le pas demandé
       var nume = 1
       var deno = parametres.pasSilence.split("/")[1]
       var stop = 0
       // console.log("curScore.nmeasure = "+curScore.nmeasures)
     while (globalCursor.element && (fullScore || globalCursor.tick < endTick) && (++stop < (curScore.nmeasures * deno)) )  {
 //          console.log("numérateur = " + cursor.measure.timesigActual.numerator + " Dénominateur = " + cursor.measure.timesigActual.denominator )
           globalCursor.setDuration(nume,deno)
           // cursor.setDuration(1, cursor.measure.timesigActual.denominator)
 //          cursor.duration = fraction (1, cursor.measure.timesigActual.denominator)
           globalCursor.addNote(65);
       }

       if (fullScore) {                             // si pas de sélection
           globalCursor.rewind(Cursor.SCORE_START)       // rembobine au début de la partition
       } else {                                     // si sélection
           globalCursor.rewind(Cursor.SCORE_START)
           while (globalCursor.element && (globalCursor.tick < startTick)) globalCursor.next()
       }

       // -----------------------------------------------------------------------
       // Suppression des notes  :
       stop = 0
       while (globalCursor.element && (fullScore || globalCursor.tick < endTick) && (++stop < (curScore.nmeasures * deno)))  {
          if (globalCursor.element && globalCursor.element.type == Element.CHORD) {
             globalCursor.staffIdx = 1
             var chord = globalCursor.element;
             while (chord.notes.length > 1)
                  chord.remove(chord.notes[0])
             removeElement(chord.notes[0])
          }
          globalCursor.next()
       }
       // -----------------------------------------------------------------------

       // -----------------------------------------------------------------------
       if (fullScore) {                             // si pas de sélection
           globalCursor.rewind(Cursor.SCORE_START)       // rembobine au début de la partition
       } else {                                     // si sélection
         globalCursor.rewind(Cursor.SCORE_START)
         while (globalCursor.element && (globalCursor.tick < startTick)) globalCursor.next()
       }

       // -----------------------------------------------------------------------
       // Rendre invisible les silences et les déplacer vers le bas
       stop = 0
       while (globalCursor.element && (fullScore || globalCursor.tick < endTick)&& (++stop < (curScore.nmeasures * deno)))  {
            if (globalCursor.element && globalCursor.element.type == Element.REST) {
                     globalCursor.element.visible = false
                     globalCursor.element.offsetY = 5.5
            }
            globalCursor.next()
       }
      // -----------------------------------------------------------------------

      return true

 }
 // ---------------------------------------------------------------------
 // Fonction doBassLine
 // Cette fonction fait l'essentiel du travail, elle est appellée dans onRun
 //----------------------------------------------------------------------
 function doBassLine() {
       var staff = 0,                           // Numéro de la portée en cours de traitement
           accordMg = "",                       // Accord à décomposer en Basse-Accord
           oldAccordMg = "",                    // Accord précédent
           basseAJouer = "" ,                   // Basse à jouer
           accordAJouer = "";                   // Accord à jouer

 //     console.log("Entrée dans la fonction doBasseLine")

       // Cherche les portées, on ne travaillera pas sur la dernière portée (en général clé de Fa, Basses et Accords)
       var nbPortees = curScore.nstaves
 //      console.log("Nombre de portées =",nbPortees)
       staff = curScore.nstaves - 1
       staff = 1                                       // La ligne de tablature est une portée qui comprend un silence par temps
       globalCursor.voice    = 0                             // on ne traite que la porté 2 qui doit contenir des silences
       globalCursor.staffIdx = 1                           // on traite la seconde portée

       // -----------------------------------------------------------------------
       if (fullScore) {                             // si pas de sélection
           globalCursor.rewind(Cursor.SCORE_START)       // rembobine au début de la partition
       } else {                                     // si sélection
         globalCursor.rewind(Cursor.SCORE_START)
         while (globalCursor.element && (globalCursor.tick < startTick)) globalCursor.next()
       }

 //     console.log("Debut de boucle pour la derniere portée numéro : " + (staff + 1))

      var thePattern = inputTextPattern.text
 //     console.log("Pattern choisit dans doBassLine(): " + thePattern)

      parametres.anacrouse = (cbAnacrouse.checkedState) ? "OUI" : "NON"
      parametres.AccordsComplets = (cbAccordsComplets.checkedState) ? "OUI" : "NON"
 //     console.log("cbAnacrouse = " + cbAnacrouse.checkedState)

 //     cursor.voice = 1
      // S'il y a une Anacrouse, on avance à la première "vraie" mesure
      if ((fullScore)&&(parametres.anacrouse == "OUI")) globalCursor.nextMeasure()

      // ----------------------------------------------------------------------
      // Boucle pour chaque mesure de la portée ou de la sélection en cours
      // ----------------------------------------------------------------------
      var temps = 0
      globalCursor.staffIdx = 1                           // on traite la seconde portée

      while (globalCursor.measure && (fullScore || globalCursor.tick < endTick))  {

                // Recherche des accords main gauche (genre Am ou Em ou E7 ...)
                var aCount = 0;
                if (globalCursor.segment) {
                     var annotation = globalCursor.segment.annotations[aCount];
                     while (annotation) {
                          if (annotation.type == Element.HARMONY){
 //                         console.log("Symbole d'accord : " + annotation.text);
                               accordMg = annotation.text.toUpperCase()
                          }
                          annotation = globalCursor.segment.annotations[++aCount];
                     }
                }


                // Si on a trouvé un nouvel accord, on cherche la basse et on l'ajoute
                if (accordMg != oldAccordMg) {
                     // Cherche si renversement
                     if (accordMg.match("/")) {
                          accordAJouer = accordMg.split("/")[0]
                          basseAJouer = accordMg.split("/")[1]
                          if (parametres.AccordsComplets != "OUI" )
                               accordAJouer = (accordAJouer.match("^[A-Ga-g]#")) ? accordAJouer[0]+"#" :
                                              (accordAJouer.match("^[A-Ga-g][Bb]")) ? accordAJouer[0] + "b" :
                                              accordAJouer
                          if (accordAJouer) accordAJouer = accordAJouer.toLowerCase()
                     } else {
                          // console.log("accordMG : " + accordMg)
                          if (accordMg) {
                          basseAJouer = (accordMg.match("^[A-Ga-g]#")) ? accordMg[0]+"#" :
                                        (accordMg.match("^[A-Ga-g][Bb]")) ? accordMg[0] + "b" :
                                        accordMg[0].toUpperCase()
                          accordAJouer = (parametres.AccordsComplets == "OUI" ) ?
                                         accordMg.toLowerCase()  :
                                         basseAJouer.toLowerCase()
                                       }
                     }
                     oldAccordMg = accordMg
 //                    console.log("Basse : " + basseAJouer + " Accord : " + accordAJouer)
                }

                // Fabrication de la ligne Basses/Accords
                var basse = newElement(Element.LYRICS)
                basse.verse = 3                     // 4ème ligne des paroles
                basse.voice = 1                     // 2ème voix
                basse.autoplace = false             // Se place où il faut
                basse.offsetY =  (parametres.offsetY)?parametres.offsetY:-13.5 // Se déplace un peu vers le bas (compatibilité avec DiatonicTab

                // Selon le choix "BaBa" ou "Baa" ou "B-aB-a" ou etc ...
 //               console.log("Basse ou Accord : " + thePattern[temps] + " Temps : " + temps)
                switch (thePattern[temps]) {
                          case "B" :
                               basse.text = basseAJouer
                               break
                          case "a":
                               basse.text = accordAJouer
                               break
                          default:
                               basse.text = thePattern[temps]
                               break
                }
 //               console.log("A afficher : " + basse.text)
                globalCursor.add(basse)

                // ----------------------------------------------------------
                globalCursor.next()               // pour aller à l'élément suivant

             temps = (temps+1) % thePattern.length
 //            console.log("temps : " + temps + "thePattern.length = " + thePattern.length)


      } // fin du while cursor.smeasure et (fullScore || cursor.tick < endTick)



 } // end function doBassLine()
 //----------------------------------------------------------------------

   onRun: {
      console.log("Kenavo")

      //------------------------------------------------------------------------------
      // Lecture du fichier de parametres
      //------------------------------------------------------------------------------
 //     console.log("Lecture du fichier de parametres")
      parametres = JSON.parse(myParameterFile.read())

      inputTextPattern.text = parametres["thePattern"]


      //  Récupère le clavier Rigth Hand dans la comboBox
      var numPattern = 0
      comboChoixPattern.currentIndex = 0
      for (numPattern = 0; numPattern < comboChoixPattern.model.length; numPattern ++) {
            var lePattern = comboChoixPattern.model[numPattern].text.replace(/(\d+)\/(\d+)\s(\w+)/,"$3")
            if (lePattern == parametres.thePattern)
                 comboChoixPattern.currentIndex = numPattern
     }
      //------------------------------------------------------------------------------

      //------------------------------------------------------------------------------
      //  Remet le bon pas de silence dans la comboBox
      //------------------------------------------------------------------------------
      var numPasSilence
      comboChoixPasSilence.currentIndex = 0
      for (numPasSilence = 0; numPasSilence < comboChoixPasSilence.model.length; numPasSilence++){
         if (comboChoixPasSilence.model[numPasSilence].value == parametres.pasSilence){
           comboChoixPasSilence.currentIndex = numPasSilence
         }
     }

   } // end onRun

 } // MuseScore
