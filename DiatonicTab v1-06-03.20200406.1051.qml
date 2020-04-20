//---------------------------------------------------------------------
// DiatonicTab, MuseScore 3 plugin
//---------------------------------------------------------------------

//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Create Tablature for diatonic accordion from a MuseScore music score
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
/* Ce plugin ajoute le numéro des touches pour accordéon diatonique
    afin de créer une forme très simplifiée de tablature
    Ce plugin utlise le textes de paroles pour mettre les numéros de touches
    afin de pouvoir aligner verticalement différement les tirés et les poussés

  Auteur : Jean-Michel Bencetti
  Version courrante : 1.04
  Date : v1.00 : 2019-06-13 : développement initial
         v1.02 : 2019-09-02 : tient compte des accords main gauche pour proposer les notes en tiré ou en poussé
         v1.03 : 2019-10-11 : ajoute la possibilité de ne traiter que des mesures sélectionnées
	    v1.04 : 2020-02-24 : propose une fenêtre de dialogue pour utiliser différents critères
	    v1.05 : 2020-03-02 : gestion de plans de claviers différents
	                      mémorisation des parametres dans un fichier format json
	                      préparation à la traduction du plugin
	    v1.05.04 : 20200316: ajouts de claviers et corrections de quelques dysfonctionnements
      v1.06 : Externalisation des claviers
      v1.06.01 : 20200324 version initiale à partie de la version v1.06
      v1.06.02 : 20200326 externalisation des claviers main gauche
      v1.06.04 : 20200406 choix de souligner ou pas les tirés en C.A.D.B.

  Description version v1.02 :
    Pour les accords main gauche A, Am, D, Dm, seules les touches en tirées sont proposées
    Pour les accords main gauche E, Em, E7, C, seules les touches en poussé sont proposées
    Pour les accords main gauche G et F, les deux numéros de touches sont proposées lorsqu'elles existes
    Les notes altérées (sauf F#) ne sont pas proposées car trop de plan de claviers différents existent
    Pour la note G, les deux propositions sont faites sur le premier et deuxième rang

  Après le passage du plugin, il reste donc à faire le ménage pour supprimer les numéros de touches en trop
  pour les accords F et G et sur les notes G main droite

  Description version v1.03 :
  - pour limiter le travail du plugin, il est possible de sélectionner les mesures à traiter.
  - sans sélection, le plugin travaille sur toute la partition sauf la dernière portée.
  - la dernière portée n'est pas traitée car elle est sencée être en clé de Fa avec des Basses et des Accords.
  - pour traiter quand même la dernière portée, il suffit de la sélectionner.
  Description version v1.04 :
  - propose une tablature sur une ou deux lignes
  - propose de n'afficher qu'une seule alternative lorsque des notes existent sous plusieurs touches
  - propose de tirer ou de pousser les G et les F ou d'indiquer les deux possibilités
  - propose de privilégier le rang de G ou celui de C ou de favoriser le jeu en croisé
  - propose un clavier 2 rangs ou 3 rangs (plan castagnari)
  - utiliser les accords A B Bb C D E f G G# pour déterminer le sens

  Description version v1.05
  - Modification de la structure des plans de clavier main droite et main gauche pour admettre plusieurs type d'accordéons
  - Adaptation du formulaire de choix en conséquence
  - Adaptation du code pour prendre en compte les nouvelles structures
  - Mémorisation des parametres dans un fichier DiatonicTab.json
  - Ajouts plans de claviers
  - Traduction en anglais
  - Traitement des accords enrichis
  - Nettoyage du code
  - Tablatures CADB, Corgeron et DES (Rémi Sallard)

  Description version v1.06
  - Externalisation des plans de clavier, 1 par fichier
  - 20200326 v1.06.03.001 Gestion des accords main droite corgeron et cadb
  - v1.06.03.20200327 : Travail sur le design de la boite de dialogue
  - v1.06.03.20200328.0924 : Travail sur le design de la boite de dialogue
  - v1.06.03.20200328.1117 : Ajout des offsetY dans les parametres
  - v1.06.03.20200328.1230 : SUpression du clavier en A/D
  - v1.06.03.20200328.1739 : Mise au points de détails
  - v1.06.03.20200329.1023 : Modification de l'ordre d'affichage des options à l'écran
  - V1.06.03.20200402.1646 : Mise de la langue dans les parametres
  - V1.06.03.20200406.1051 : Choix de souligner ou pas les Tirés dans le modèle C.A.D.B.

  ----------------------------------------------------------------------------*/
import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import FileIO 3.0
import QtQuick.Dialogs 1.2

MuseScore {


//-----------------------------------------------------

//   description: qsTr("Tablatures pour accordéon diatonique")
   description: qsTr("Tablatures for diatonic accordion")

   menuPath: "Plugins.DiatonicTab.Tablature"
   requiresScore: true
   version: "1.06.04.20200406.1646-Mariano"
   pluginType: "dialog"

   property int margin: 10

   width:  500
   height: 640

//---------------------------------------------------------------
// Parametres, variables globales à tout le plugin. Ces données sont
// mémorisées dans le fichier DiatonicTab.json. Elles sont présentes
// ici au cas où le fichier json soit absent
//---------------------------------------------------------------
property var parametres: {
         "offsetY" : { "CADBT" : 5.85,
                       "CADBP" : 5.85,
                       "DES":0,
                       "CorgeronAlt": 2.25,
                       "CorgeronC": 2.25,
                       "CorgeronG": 2.25,
                      },           // Décallage vers le bas dans la partition
         "sensFa"  : 3,               // 1 Fa Tirés  / 2 Fa Poussés / 3 Fa dans les deux sens
         "sensSol" : 3,               // 1 Sol Tirés  / 2 Sol Poussés / 3 Sol dans les deux sens
         "typeJeu" : 3,               // 1 C privilégié  / 2 G privilégié / 3 Jeu croisé
         "typePossibilite": 2,        // 2 Afficher toutes les possibilités  / 1 n'afficher qu'une seule possibilité
         "typeTablature":  "DES",     // tablature CADB ou Corgeron ou DES (mono ligne)
         "clavierMD"  : {},           // Contenu du clavier main droite
         "clavierMG" : {},            // Contenu du clavier main gauche
         "soulignerTireCADB" : 1,     // Souligner les tirés en C.A.D.B.
         //-----------------------------------------------------
         // Set here the parametres.language : FR = French, EN = English
         "lang": "FR",                // Langue de l'utilisateur
}
//---------------------------------------------------------------
// Descripteurs des fichiers : parametres et claviers
//---------------------------------------------------------------
// Fichiers JSON pour la mémorisation des parametres
FileIO {
        id: myParameterFile
        source: homePath() + "/DiatonicTab.json"
        onError: console.log(msg)
}
// Fichiers RH_*.keyboard pour le clavier main droite
// Fichiers LH_*.keyboard pour le clavier main gauche
FileIO {
    // Fichiers format JSON pour la mémorisation des claviers
    id: fichierClavier
    onError: console.log(msg)
}
// ------------------------------------------------------
// Boite de dialogue pour le choix du fichier clavier main droite
// ------------------------------------------------------
FileDialog {
      id: fileDialogClavierMD
      title: qsTr("RH Keyboard")
      folder: shortcuts.documents + "/MuseScore3/plugins/DiatonicTab/"
      nameFilters: [ "Layout (RH_*.keyboard)", "All files (*)" ]
      selectedNameFilter: "Layout (RH_*.keyboard)"
      selectExisting: true
      selectFolder: false
      selectMultiple: false
        onAccepted: {
                debug("OK : " + fileUrl)
                if (fileUrl.toString().indexOf("file:///") != -1)
                  fichierClavier.source = fileUrl.toString().substring(fileUrl.toString().charAt(9) === ':' ? 8 : 7)
                else
                  fichierClavier.source = fileUrl
                // Lecture du plan de clavier
                parametres.clavierMD = JSON.parse(fichierClavier.read())
                // Met à jour l'affichage dans la boîte de dialogue
                textDescriptionClavierMD.text = parametres.clavierMD.description
        }
        onRejected: {
            console.log("Canceled")
            Qt.quit()
        }
}
// ------------------------------------------------------
// Boite de dialogue pour le choix du fichier clavier main gauche
// ------------------------------------------------------
FileDialog {
        id: fileDialogClavierMG
        title: qsTr("LF Keyboard")
        folder: shortcuts.documents + "/MuseScore3/plugins/DiatonicTab/"
        nameFilters: [ "Layout (LH_*.keyboard)", "All files (*)" ]
        selectedNameFilter: "Layout (LH_*.keyboard)"
        selectExisting: true
        selectFolder: false
        selectMultiple: false
          onAccepted: {
                  debug("OK : " + fileUrl)
                  if (fileUrl.toString().indexOf("file:///") != -1)
                    fichierClavier.source = fileUrl.toString().substring(fileUrl.toString().charAt(9) === ':' ? 8 : 7)
                  else
                    fichierClavier.source = fileUrl
                  // Lecture du plan de clavier
                  parametres.clavierMG = JSON.parse(fichierClavier.read())
                  // Met à jour l'affichage dans la boîte de dialogue
                  textDescriptionClavierMG.text = parametres.clavierMG.description
          }
          onRejected: {
              console.log("Canceled")
              Qt.quit()
          }
  }

// -------------------------------------------------------------------
// Description de la fenêtre de dialogue
//--------------------------------------------------------------------
 GridLayout {
      id: 'mainLayout'
      anchors.fill: parent
      anchors.margins: 10
      columns: 3

Label {
     Layout.columnSpan : 3
     width: parent.width
     elide: Text.ElideNone
     horizontalAlignment: Qt.AlignCenter
     font.bold: true
     font.pointSize: 16
     text:  (parametres.lang == "FR") ? qsTr("Tablatures pour accordéons diatoniques") :
                             qsTr("Tablature for diatonic accordion")
      }

//------------------------------------------------
// Type d'accordéon et plan de clavier Main DROITE
//------------------------------------------------
GroupBox {
  Layout.columnSpan : 3
  Layout.fillWidth: true
  width: parent.width
  title : (parametres.lang == "FR") ? qsTr("Choix des claviers : ") :
                           qsTr("Diatonic keyboard : ")
   GridLayout {
       height: parent.height
       anchors.fill: parent
       width: parent.width
       columns: 3

      Label {
           horizontalAlignment: Qt.AlignRigth
           text:  (parametres.lang == "FR") ? qsTr("Clavier MD utilisé : ") :
                                   qsTr("Used RH Keyboard : ")
            }
      // -----------------------------------------------
      // Choix du clavier Main droite
      Text {
                 id : textDescriptionClavierMD
                 elide : Text.ElideNone
                 text : ""
                 font.bold: true
      }
      Button {
            id: buttonChoixFichierClavier
            Layout.alignment: Qt.AlignRight
            isDefault: false
            text: (parametres.lang == "FR") ? qsTr(" Changer Clavier MD ") :
                                    qsTr(" Change RH Keyboard ")
            onClicked: {
                // Choix du clavier parmi les fichiers RH_*.keyboard
                fileDialogClavierMD.open()
            }
      }
      // -----------------------------------------------
      // -----------------------------------------------
      // Choix du clavier Main Gauche
      Label {
             horizontalAlignment: Qt.AlignRigth
             text:  (parametres.lang == "FR") ? qsTr("Clavier MG utilisé : ") :
                                     qsTr("Used LH Keyboard  : ")
              }
      Text {
             id : textDescriptionClavierMG
             elide : Text.ElideNone
             text : ""
             font.bold: true
      }
      Button {
            id: buttonChoixFichierClavierMG
            Layout.alignment: Qt.AlignRight
            isDefault: false
            text:  (parametres.lang == "FR") ? qsTr(" Changer Clavier MG ") :
                                    qsTr(" Change LH Keyboard ")
            onClicked: {
                // Choix du clavier parmi les fichiers LH_*.keyboard
                fileDialogClavierMG.open()
            }
      }
    }   // GridLayout
}  // GroupBox des plans de clavier
// -----------------------------------------------

//-------------------------------------------------------------------------
// Sens des mesures de Sol   1 = tiré / 2 = poussé / 3 = dans les deux sens
//-------------------------------------------------------------------------
GroupBox {
    title:  (parametres.lang=="FR")?qsTr("Sens du soufflet pour passages en Sol"):
                         qsTr("Bellows direction for G measures")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupSOL }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Dans les 2 sens"):qsTr("Push AND Pull")
            checked: (parametres.sensSol==3)
            exclusiveGroup: tabPositionGroupSOL
            onClicked : {
              parametres.sensSol = 3
            }
        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le tiré"):qsTr("Pull priority")
            checked: (parametres.sensSol==1)
            exclusiveGroup: tabPositionGroupSOL
            onClicked : {
              parametres.sensSol = 1
            }
          }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le poussé"):qsTr("Push priority")
            exclusiveGroup: tabPositionGroupSOL
            checked: (parametres.sensSol==2)
            onClicked : {
              parametres.sensSol = 2
            }
        }
    } // RowLayout
} // GroupBox du choix sens Sol
//------------------------------------------------
// Sens des mesures de Fa   1 = tiré / 2 = poussé / 3 = dans les deux sens
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Sens du souffler pour les passages en Fa"):
                        qsTr("Bellows direction for F measures")
     Layout.columnSpan : 3
     Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupFA }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Dans les 2 sens"):qsTr("Push AND Pull")
            checked: (parametres.sensFa==3)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 3
            }
        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le tiré"):qsTr("Pull priority")
            checked: (parametres.sensFa==1)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 1
            }

        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le poussé"):qsTr("Push priority")
            checked: (parametres.sensFa==2)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 2
            }
        }
    } // RowLayout
} // GroupBox du choix sens Fa
//------------------------------------------------
// Simple ou double possibilité
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Lorsque plusieurs touches correspondent à une même note"):
                        qsTr("When several keys correspond to a same note")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupPossibilite }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Afficher toutes les possibilités"):
                              qsTr("Show all possibilities")
            checked : (parametres.typePossibilite==2)
            exclusiveGroup: tabPositionGroupPossibilite
            onClicked : {
              parametres.typePossibilite = 2
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("N'afficher qu'une seule possibilité"):
                              qsTr("Show only one possibility")
            checked : (parametres.typePossibilite==1)
            exclusiveGroup: tabPositionGroupPossibilite
            onClicked : {
              parametres.typePossibilite = 1
            }
        }
    } // RowLayout
} // GroupBox Nombre de possibilités
//------------------------------------------------
// Sens type de jeu   1 = C / 2 = G / 3 = Croisé
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Jeu Tiré/Poussé ou Croisé"):qsTr("Crossed or Push/Pull playing")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {

        ExclusiveGroup { id: tabPositionGroupCroise }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Jeu en croisé"):qsTr("Crossed playing")
            exclusiveGroup: tabPositionGroupCroise
             checked: (parametres.typeJeu==3)
            onClicked : {
              parametres.typeJeu = 3
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Privilégier rang 1"):qsTr("Row #1 priority")
            checked: (parametres.typeJeu==1)
            exclusiveGroup: tabPositionGroupCroise
            onClicked : {
              parametres.typeJeu = 1
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Privilégier rang 2"):qsTr("Row #2 priority")
            checked: (parametres.typeJeu==2)
            exclusiveGroup: tabPositionGroupCroise
            onClicked : {
              parametres.typeJeu = 2
            }
        }
    } // RowLayout
} // GroupBox Type de jeu
//------------------------------------------------
// Type de tablature
//------------------------------------------------
GroupBox {
    Layout.columnSpan : 3
    Layout.fillWidth: true
    title: (parametres.lang=="FR")?qsTr("Tablature : "):
                        qsTr("Tablature : ")
    GridLayout {
        Layout.fillWidth: true
        width:parent.width
        columns : 3
        ExclusiveGroup { id: tabPositionGroupNbLigne }
        GroupBox {
              title: " "
              width:parent.width
              Layout.fillWidth: true
              anchors.left: parent.left
              anchors.top: parent.top
              ColumnLayout {
                    width:parent.width
                    Layout.fillWidth: true
                    RadioButton {
                          text:(parametres.lang=="FR")?qsTr("C.A.D.B."):
                                            qsTr("C.A.D.B.")
                          exclusiveGroup: tabPositionGroupNbLigne
                          checked : (parametres.typeTablature =="CADB")
                          onClicked : {
                            parametres.typeTablature = "CADB"
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage Y ligne P :") :
                                                  qsTr("Y Offset P line   :")
                    }
                    TextField {
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCADBP
                          text : (parametres.offsetY.CADBP)?parametres.offsetY.CADBP:0
                          horizontalAlignment: Qt.AlignRight
                          onEditingFinished : {
                              parametres.offsetY.CADBP = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage Y ligne T :") :
                                                  qsTr("Y Offset T line   :")
                    }
                    TextField {
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCADBT
                          text : parametres.offsetY.CADBT
                          horizontalAlignment: Qt.AlignRight
                          onEditingFinished : {
                              parametres.offsetY.CADBT = text
                          }
                    }
                    CheckBox {
                        id: cbSoulignerTireCADB
                        width:parent.width
                        Layout.fillWidth: true
                        Layout.columnSpan : 2
                        text: (parametres.lang=="FR")? qsTr("Souligner les Tirer"):
                                            qsTr("Underline Pull")
                        checked: (parametres.soulignerTireCADB == "1")
                    }
              }   // RowLayout CADB
        } // GroupBox CADB
        GroupBox {
            title: " "
            width:parent.width
            Layout.fillWidth: true
            anchors.top: parent.top
            ColumnLayout {
                   width:parent.width
                   Layout.fillWidth: true
                   RadioButton {
                          text:(parametres.lang=="FR")?qsTr("Corgeron"):
                                            qsTr("Corgeron")
                          exclusiveGroup: tabPositionGroupNbLigne
                          checked : (parametres.typeTablature =="Corgeron")
                          onClicked : {
                             parametres.typeTablature = "Corgeron"
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne Alt :") :
                                                  qsTr("Y Offset Alt line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronAlt
                          text : parametres.offsetY.CorgeronAlt
                          onEditingFinished : {
                               parametres.offsetY.CorgeronAlt = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne C :") :
                                                  qsTr("Y Offset C line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronC
                          text : parametres.offsetY.CorgeronC
                          onEditingFinished : {
                               parametres.offsetY.CorgeronC = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne G :") :
                                                  qsTr("Y Offset G line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronG
                          text : parametres.offsetY.CorgeronG
                          onEditingFinished : {
                               parametres.offsetY.CorgeronG = text
                          }
                    }
              } // RowLayout
        } // GroupBox
        GroupBox {
              anchors.right: parent.right
              width:parent.width
              Layout.fillWidth: true
              anchors.top: parent.top
              title: " "
              ColumnLayout {
                  Layout.fillWidth: true
                  width:parent.width
                  RadioButton {
                        width:parent.width
                        text:(parametres.lang=="FR")?qsTr("D.E.S."):
                                          qsTr("D.E.S.")
                        checked : (parametres.typeTablature=="DES")
                        exclusiveGroup: tabPositionGroupNbLigne
                        onClicked : {
                            parametres.typeTablature = "DES"
                        }
                  }
                  // OffsetY
                  Label {
                      Layout.fillWidth: true
                      width: parent.width
                      wrapMode: Label.Wrap
                      text:  (parametres.lang == "FR") ? qsTr("Position (décalage Y) :") :
                                              qsTr("Position (Y offset)   :")
                  }

                  TextField {
                        width:parent.width
                        horizontalAlignment: Qt.AlignRight
                        Layout.fillWidth: true
                        id : inputTextoffsetYDES
                        text : parametres.offsetY.DES
                        onEditingFinished : {
                             parametres.offsetY.DES = text
                        }
                  }
              } // RowLayout
          } // GroupBox DES
    } // GridLayout du choix type de tablature
  } // GroupBox

//-----------------------------------------------
RowLayout {
  Layout.fillWidth: true
  width: parent.width
  Layout.alignment: Qt.AlignCenter
  Layout.columnSpan: 3

   Button {
         id: okButton
         isDefault: true
         text: qsTr("OK")
         onClicked: {
            // Mémorise les parametres pour la prochaine fois
            memoriseParametres()
            // Ecrit la tablature
            curScore.startCmd()
            doTablature()
            curScore.endCmd()
            // fin de séquence
            Qt.quit();
         }
      }
   Button {
         id: cancelButton
         text: (parametres.lang=="FR")?qsTr( "Annuler"):qsTr("Cancel")
         onClicked: {
           memoriseParametres()
           Qt.quit();
         }
      }
    }
    Label {
      id: labelVersion
      Layout.columnSpan: 3
      Layout.alignment: Qt.AlignCenter
      text : "v"+ version + " " + parametres.lang
      MouseArea {
          anchors.fill: parent
          onClicked: { parametres.lang = (parametres.lang == "FR")? "EN" : "FR"
                      labelVersion.text = "v"+ version + " " + parametres.lang }
      }
    }
    // Rectangle {
    // width: 10; height: 10
    // color: "green"
    // //anchors.fill: parent
    // text: "FR"
    // MouseArea {
    //     anchors.fill: parent
    //     onClicked: { parametres.lang = (parametres.lang == "FR")? "EN" : "FR"
    //                 labelVersion.text = "v"+ version + " " + parametres.lang }
    // }
// }
  } // GridLayout


function debug(message) {
  if (true) {
    console.log(message) 
  }
}

function addElement(cursor, element) {
  debug("Ajout de l'élément: " + element.name + "(" + element.text + ")")
  cursor.add(element)
}

// -----------------------------------------------------------------------------
// Fonction de mémorisation des Parametres
// Cette fonction replace les éléments de la boite de dialogue dans les Parametres
// ce qui n'est pas toujours fait lorsqu'on clique sur OK ou Annuler
// -----------------------------------------------------------------------------
function memoriseParametres(){
  parametres.offsetY.CADBP     = inputTextoffsetYCADBP.text
  parametres.offsetY.CADBT     = inputTextoffsetYCADBT.text
    parametres.offsetY.DES      = inputTextoffsetYDES.text
    parametres.offsetY.CorgeronAlt = inputTextoffsetYCorgeronAlt.text
    parametres.offsetY.CorgeronC = inputTextoffsetYCorgeronC.text
    parametres.offsetY.CorgeronG = inputTextoffsetYCorgeronG.text
    parametres.soulignerTireCADB = (cbSoulignerTireCADB.checkedState == Qt.Checked) ? "1" : "0"
    myParameterFile.write(JSON.stringify(parametres).replace(/,/gi ,",\n"))

}
// ------------------------------------------------------------------------------
// fonction addTouche(cursor, notes, accord)
// Cette fonction ajoute le numéro de la touche à actionner en fonction de l'accord main gauche
// Entrée : curseur positionné à l'endroit où il faut insérer le numéro de la touche
//              notes à traiter, cette fonction ne traite tout le CHORD
//              le dernier accord main gauche rencontré pour choisir entre tiré et poussé lorsque c'est possible
// Si la note n'existe pas en poussé mais qu'elle existe en tiré, celle-ci est proposée quelque soit l'accord (A, F, F#))
// et réciproquement
// Les critères définis par l'utilisateur dans la boite de dialogue sont utilisés ici
//------------------------------------------------------------------------------
 function addTouche(cursor, notes, accord) {

     var textPousse, textTire, textAlt
     var numNote                // Compteur sur les notes du CHORD
     var tabRangC = []          // Pour le système Corgeron, on crée 3 tableaux de Rang
     var tabRangG = []
     var tabRangAlt = []
     var ia = 0, ic = 0, ig = 0 // et trois index pour placer les numéros de touche
     var tabRangT = []          // Pour le système CADB, on crée 2 tableaux
     var tabRangP = []
     var iT = 0, iP = 0         // et deux index pour placer les numéros de touche

     // ------------------------------------------------------------------------
     // Boucle sur chaque note de l'accord
     // ------------------------------------------------------------------------
     for (numNote = 0;  numNote < notes.length; numNote ++){
        var note = notes[numNote]
        // ------------------------------------------------------------------------
        // Choix entre STAFF_TEXT et LYRICS : Si tablature sur 2 lignes, LYRICS, sinon STAFF
        //------------------------------------------------------------------------------
        if (parametres.typeTablature=="DES") {
          textPousse =  newElement(Element.STAFF_TEXT)
          textTire   =  newElement(Element.STAFF_TEXT)
          textAlt    =  newElement(Element.STAFF_TEXT)
        } else {
          textPousse =  newElement(Element.LYRICS)
          textTire   =  newElement(Element.LYRICS)
          textAlt    =  newElement(Element.LYRICS)
        }

        textPousse.text = textTire.text = textAlt.text = ""

        // ------------------------------------------------------------------------
        // Nettoyage des accords enrichis, transformation en accord de base
        //------------------------------------------------------------------------------
        // Supression de la basse dans la notation Am/C
           accord = accord.split("\/")[0]
        // Transforme les bémols en dièses
           var transBemol = { "AB":"G#","BB":"A#","CB":"B","DB":"C#","EB":"D#","FB":"E","GB":"F#" }
           if (accord.match(/^[A-G]B/)) accord = transBemol[accord[0]+"B"]
        // Supression de M m - sus add 7 6 9 etc dans Am7(b5)
           if (!accord.match("#")) accord = accord[0]
           else accord = accord[0] + "#"

        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Fabrication par calcul du nom de la note de C0 à B9
        //------------------------------------------------------------------------------
        // note.pitch contient le numéro de la note dans l'univers MuseScore.
         var noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
         var octave = Math.floor(note.pitch / 12) - 1      // Numéro de l'octave
         var noteName = noteNames[note.pitch % 12]         // Cherche la note dans le tableau du nom des notes
         if (noteName.match("#"))                          // Ajoute l'octave à ce nom de note (conservation du #)
               noteName = noteName[0] + octave + noteName[1]
          else
               noteName += octave
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Récupération du numéro des touches diato à afficher selon le modèle de clavier choisi
        //------------------------------------------------------------------------------
        var noBouton = parametres.clavierMD[noteName]
        if (!noBouton) noBouton = ""
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Variable pour le jeu en Tiré/Poussé
        var indexDoubleSens = 0

        // ------------------------------------------------------------------------
        // Recherche des boutons Tirés et Poussés, formatage du numéro des touches
        // la variable noBouton peut contenir :
        // xP ou xT pour une seule touche X en Tiré ou en Poussé
        // xP/xT ou xT/xP pour deux touches en Tiré Poussé
        // xP/yP ou xT/yT pour deux touches en Poussé Tiré
        // xP/yP/zT pour trois touches , etc...
        var tabBouton = noBouton.split("/")             // Découpage selon les slash
        var i = 0
        for (i = 0 ; i < tabBouton.length ; i++) {
               if (tabBouton[i].match("P")) textPousse.text += tabBouton[i].replace("P","") + "/"
               if (tabBouton[i].match("T")) textTire.text   += tabBouton[i].replace("T","") + "/"
        }
        if (textPousse.text.match("/$"))  textPousse.text = textPousse.text.substr(0,textPousse.text.length -1)
        if (textTire.text.match("/$"))  textTire.text = textTire.text.substr(0,textTire.text.length -1)
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Type de Jeu croise, tiré/poussé
        // Si le jeu est en croisé, on tient compte des accords pour choisir le sens
        // Si le jeu est en tiré poussé, on ne tient pas compte des accords
           switch (parametres.typeJeu) {

           case 3 : // Jeu en croisé, on tient compte des accords
                if (parametres.clavierMG["Tire"].match("-"+accord+"-"))
        					if (textTire.text != "")
        						textPousse.text    = "";

                if (parametres.clavierMG["Pousse"].match("-"+accord+"-"))
        					if (textPousse.text != "")
        						textTire.text      = "";

                 if (parametres.clavierMG["2sens"].match("-"+accord+"-"))
                 {
                    if (accord.match(/F/i)) {
                      switch (parametres.sensFa) {
                        case 1 :          // Fa (Sol/Do)  en tiré uniquement
                               if (textTire.text != "") textPousse.text = ""; // supression du texte poussé
                        break
                        case 2 :          // Fa (Sol/Do)  en poussé uniquement
                               if (textPousse.text != "") textTire.text = "";  // supression du texte tiré
                        break
                        case 3 : // Fa dans les deux sensSol
                        break
                      }
                    }
                    if (accord.match(/G/i))
                    {
                      switch (parametres.sensSol) {
                        case 1 :          // Sol (Sol/Do)  en tiré uniquement
                               if (textTire.text != "") textPousse.text      = ""; // supression du texte poussé
                        break
                        case 2 :          // Sol (Sol/Do)  en poussé uniquement
                                if (textPousse.text != "") textTire.text      = "";  // supression du texte tiré
                        break
                        case 3 :            // Sol dans les deux sensSol

                        break
                      }
                    }
                 }

           break;
           // jeu en tiré poussé sur le rang 2 (de C sur un GC)
           case 2 :
                 //Si double possibilité , on ne garde que le rang 2
                 if (textTire.text.match("/"))
                    textTire.text = textTire.text.split("/")[(textTire.text.match(/'$/))?1:0]
	         if (textPousse.text.match("/"))
	                textPousse.text = textPousse.text.split("/")[(textPousse.text.match(/'$/))?1:0]
	         if (textTire.text.match("'")  && (!textPousse.text.match("'"))) textPousse.text = ""
	         if (textPousse.text.match("'")  && (!textTire.text.match("'"))) textTire.text = ""
	         indexDoubleSens = (textTire.text.match(/\/.*'$/) || textPousse.text.match(/\/.*'$/)) ? 1 : 0
           break;
           // jeu en tiré poussé sur le rang 1 (de G sur un GC)
           case 1 :
                 //Si double possibilité en tiré, on ne garde que le rang de 1 (pas de ')
                 if (textTire.text.match("/"))
                        textTire.text   = textTire.text.split("/")[(textTire.text.match(/'$/))?0:1]

                 //Si double possibilité en poussé, on ne garde que le rang de 1 (pas de ')
                 if (textPousse.text.match("/"))
	                textPousse.text = textPousse.text.split("/")[(textPousse.text.match(/'$/))?0:1]


	         if (!(textTire.text.match(".'"))  && (textPousse.text.match(".'"))) textPousse.text = ""

	         if ( !(textPousse.text.match(".'"))  && (textTire.text.match(".'"))) textTire.text = ""

	         indexDoubleSens = (textTire.text.match(/\/.*'$/) || textPousse.text.match(/\/.*'$/)) ? 1 : 0

           break;
           }
         // Fin du swith "type de jeu"
         // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
	   // Gestion des doubles possibilités pour les notes en double sur le clavier
	   // Si on ne veut qu'une seule possibilité, on ne garde que la première définie dans le tableau des touches
	   if (parametres.typePossibilite == 1) {
	        if (textTire.text.match("/"))   textTire.text   = textTire.text.split("/")[indexDoubleSens]
	        if (textPousse.text.match("/")) textPousse.text = textPousse.text.split("/")[indexDoubleSens]
	   }
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
        // Gestion du positionnement selon le nombre de lignes de la tablature
	   switch(parametres.typeTablature) {
	         case "Corgeron":
	               var tabPossibiliteTire   = textTire.text.split("/")
	               var tabPossibilitePousse = textPousse.text.split("/")
	               // Répartition entre les rangs Alt, C et G
                 // les index ia, ic et ig sont mis à 0 en tout de but de fonction
                 // les tablesux tabRangG tabRangC et tabRangAlt sont initialisés en début de fonction
	               var i
	               for (i = 0 ; i < tabPossibiliteTire.length ; i++) {
	                   if (tabPossibiliteTire[i] != "")
	                   if (tabPossibiliteTire[i].match("''")) {
                     tabRangAlt[ia++] = "<u>" + tabPossibiliteTire[i] + "</u>"
                     tabRangAlt[ia++] = tabPossibiliteTire[i] }
	                   else if (tabPossibiliteTire[i].match("'")) {
                     tabRangC[ic++] = "<u>" + tabPossibiliteTire[i] + "</u>"
                     tabRangC[ic++] = tabPossibiliteTire[i] }
	                   else {
                     tabRangG[ig++] = "<u>" + tabPossibiliteTire[i] + "</u>"
                     tabRangG[ig++] = tabPossibiliteTire[i] }
	               }

	               for (i = 0 ; i < tabPossibilitePousse.length ; i++) {
	                   if (tabPossibilitePousse[i] != "")
	                   if (tabPossibilitePousse[i].match("''"))
	                        tabRangAlt[ia++] = tabPossibilitePousse[i]
	                   else if (tabPossibilitePousse[i].match("'"))
	                        tabRangC[ic++] = tabPossibilitePousse[i]
	                   else
	                        tabRangG[ig++] = tabPossibilitePousse[i]
	               }
                 // Lorsqu'on atteint la dernière note de l'accord, on ventille les informations
                 if (numNote == notes.length-1){
                  textTire.autoplace = textPousse.autoplace = textAlt.autoplace = false
	                 textAlt.offsetY     = parametres.offsetY.CorgeronAlt
                   textPousse.offsetY  = parametres.offsetY.CorgeronC
                   textTire.offsetY    = parametres.offsetY.CorgeronG
	                 textAlt.verse = 0
	                 textAlt.text = tabRangAlt[0]
  	               for (i = 1 ; i < tabRangAlt.length ; i++) {
  	                   if (textAlt[i] != "") textAlt.text += "/" + tabRangAlt[i]
  	               }
  	               if (textAlt.text != "") {
	                   textAlt.text = textAlt.text.replace(/(.*)''(.*)/g,"$1$2")
	                   textAlt.text = textAlt.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
  	               textPousse.text = tabRangC[0]
  	               textPousse.verse = 1
  	               for (i = 1 ; i < tabRangC.length ; i++) {
  	                   if (tabRangC[i] != "") textPousse.text += "/" + tabRangC[i]
  	               }
  	               if (textPousse.text != "") {
  	                   textPousse.text = textPousse.text.replace(/(.*)''(.*)/g,"$1$2")
  	                   textPousse.text = textPousse.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
  	               textTire.text = tabRangG[0]
  	               textTire.verse = 2
  	               for (i = 1 ; i < tabRangG.length ; i++) {
  	                   if (tabRangG[i] != "") textTire.text += "/" + tabRangG[i]
  	               }
  	               if (textTire.text != "") {
  	                   textTire.text = textTire.text.replace(/(.*)''(.*)/g,"$1$2")
  	                   textTire.text = textTire.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
                 }
	          break
            case "CADB":                  // Collectif des Accordéons Diatoniques de Bretagne
                tabRangT[iT++] = textTire.text
                tabRangP[iP++] = textPousse.text
                // Lorsque c'est la dernière note de l'accord, on empile toutes Les
                // notes à afficher dans textTire.text et textPousse.text
                if (numNote == notes.length-1){
                    textTire.text = tabRangT[0]
                    for (var i = 1; i<tabRangT.length; i++)
                      if (tabRangT[i] !== "")  textTire.text += "/" +tabRangT[i]

                    textPousse.text = tabRangP[0]
                    for (var i = 1; i<tabRangP.length; i++)
                      if (tabRangP[i] !== "") textPousse.text += "/"+tabRangP[i]
                    textPousse.verse = 0
                    textTire.verse   = 1
                    textTire.offsetY    = parametres.offsetY.CADBT
                    textPousse.offsetY  = parametres.offsetY.CADBP
                    textTire.autoplace  = textPousse.autoplace = false
                    if (parametres.soulignerTireCADB == "1")
                      textTire.text = "<u>"+textTire.text+"</u>"
                }
            break
            case "DES":                         // Rémi Sallard Style
              	    textTire.offsetY   = textPousse.offsetY  = parametres.offsetY.DES
	                  textTire.autoplace = textPousse.autoplace = true
                    // Ajoute les numéros à la tablature en placement automatique
                    if (textAlt.text !=  "") addElement(cursor, textAlt)
                    if (textTire.text !=  "") {
                      textTire.text = "<u>" + textTire.text + "</u>"
                      addElement(cursor, textTire)
                    }
                    if (textPousse.text != "") addElement(cursor, textPousse)
            break
        }
        // ------------------------------------------------------------------------
      }   // Fin de la boucle for(numNote = 0; numNote<notes.length; numNote++)
        // ------------------------------------------------------------------------
        // Pour finir, on affiche le numéro de la touche dans la partition
        // pour les tablatures Corgeron et CADB, ,es DES ont déjà été ajoutées
        if (parametres.typeTablature != "DES"){
          if (textAlt.text !=  "") addElement(cursor, textAlt)
          if (textTire.text !=  "") {
              // textTire.text = "<u>" + textTire.text + "</u>"
              addElement(cursor, textTire)
          }
          if (textPousse.text != "") addElement(cursor, textPousse)
        }
        // ------------------------------------------------------------------------
}


// ---------------------------------------------------------------------
// Fonction doTablature
//
// Fonction principale appelée par le click que le bouton OK
//----------------------------------------------------------------------
function doTablature() {

      var myScore = curScore,                  // Partition en cours
          cursor = myScore.newCursor(),        // Fabrique un curseur pour se déplacer dans les mesures
          startStaff,                          // Début de partition ou début de sélection
          endStaff,                            // Fin de partition ou fin de sélection
          endTick,                             // Numéro du dernier élément de la partition ou de la sélection
          staff = 0,                           // numéro de de portée dans partition
          accordMg,                            // Détermine si on est en Poussé ou en Tiré lorsque c'est possible
          fullScore = false;                   // Partition entière ou sélection

      // Cherche les portées, on ne travaillera pas sur la dernière portée (en général clé de Fa, Basses et Accords)
      // dans le cas de tablature DES, on traite toutes les portées moins 1
      // dans le cas Corgeron ou CADB on ne traite que la portée 1 et on écrit sur la porté 2 (si elle existe)
      var nbPortees = (parametres.typeTablature == "DES") ? myScore.nstaves : (myScore.nstaves >= 2) ? 2 : 1

      // pas d'accord main gauche à priori
      accordMg = "zzz"

      // ---------------------------------------------------------------------
      // Boucle sur chacune des portées sauf la dernière s'il y en a plusieurs
      // ---------------------------------------------------------------------
      do {
            cursor.voice    =  0                          // Si CADB ou Corgeron, voix 1 de la porté 1
            cursor.staffIdx =  staff

            // Gestion d'une sélection ou du traitement de toute la partition

            cursor.rewind(Cursor.SELECTION_START)           // rembobine au début de la sélection
            if (!cursor.segment) { // pas de sélection
                  fullScore = true;
                  startStaff = 0;                           // commence à la première mesure
                  endStaff = curScore.nstaves - 1;          // et termine à la dernière
            } else {
                  startStaff = cursor.staffIdx;             // commence au début de la sélection
                  cursor.rewind(2);                         // passe derrière le dernier segment et fixe tick = 0
                  if (cursor.tick === 0) {                  // ceci survient lorsque la sélection contient la dernière mesure
                       endTick = curScore.lastSegment.tick + 1;
                  } else {
                      endTick = cursor.tick;
                  }
                 endStaff = cursor.staffIdx;
            }

            if (fullScore) {                          // si pas de sélection
                  cursor.rewind(Cursor.SCORE_START)   // rembobine au début de la partition
             } else {                                 // si sélection
                 cursor.rewind(Cursor.SELECTION_START)// rembobine au début de la sélection
             }

             // -------------------------------------------------------------------
             // Boucle pour chaque élément de la portée ou de la sélection en cours
             // -------------------------------------------------------------------
             while (cursor.segment && (fullScore || cursor.tick < endTick))  {
                    var aCount = 0;

                    // Recherche des accords main gauche (genre Am ou Em ou E7 ...)
                    var annotation = cursor.segment.annotations[aCount];
                    while (annotation) {
                           if (annotation.type == Element.HARMONY){
                                accordMg = annotation.text.toUpperCase()
                           }
                           annotation = cursor.segment.annotations[++aCount];
                    }

                  // Si le curseur pointe sur une à plusieurs notes jouées simultanément
                  if (cursor.element && cursor.element.type == Element.CHORD) {
                        var notes = cursor.element.notes
                        // On envoie toutes les notes du CHORD
                            addTouche(cursor, notes, accordMg)
                  } // end if CHORD

                  cursor.next() //Element suivant

             } // fin du while cursor.segment et (fullScore || cursor.tick < endTick)

             staff+=1 // Portée suivante

      } while ((parametres.typeTablature == "DES")
            && (staff < nbPortees-1)
            && fullScore)  // fin du for chaque portée sauf si sélection

       // Rappel : on ne traite pas la dernière portée qui est probablement en clé de fa,
       // avec basses et accords. Pour la traiter quand même, il suffit de la sélectionner

  }   // Fin de la fonction doTablature
  //-------------------------------------------------------
  // Initialisation du plugin
  //-------------------------------------------------------
     onRun: {

          if (!curScore) Qt.quit();   // Si pas de partition courrante, sortie du plugin
          if (typeof curScore === 'undefined')  Qt.quit();

          //------------------------------------------------------------------------------
          // Lecture du fichier de parametres
          //------------------------------------------------------------------------------
          parametres = JSON.parse(myParameterFile.read())
          //------------------------------------------------------------------------------
          textDescriptionClavierMD.text = parametres.clavierMD.description
          textDescriptionClavierMG.text = parametres.clavierMG.description
          inputTextoffsetYCADBT.text     = parametres.offsetY.CADBT
          inputTextoffsetYCADBP.text     = parametres.offsetY.CADBP
          inputTextoffsetYDES.text      = parametres.offsetY.DES
          inputTextoffsetYCorgeronAlt.text = parametres.offsetY.CorgeronAlt
          inputTextoffsetYCorgeronC.text = parametres.offsetY.CorgeronC
          inputTextoffsetYCorgeronG.text = parametres.offsetY.CorgeronG
          cbSoulignerTireCADB.checked = (parametres.soulignerTireCADB == "1")

          //------------------------------------------------------------------------------
      }
}  // MuseScore
