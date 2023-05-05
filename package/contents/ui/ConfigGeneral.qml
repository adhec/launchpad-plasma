/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15

import org.kde.draganddrop 2.0 as DragDrop
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.0
import org.kde.plasma.private.kicker 0.1 as Kicker

Kirigami.FormLayout {
    id: configGeneral

    anchors.left: parent.left
    anchors.right: parent.right

    property bool isDash: (plasmoid.pluginName === "org.kde.plasma.kickerdash")

    property string cfg_icon: plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage: plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage: plasmoid.configuration.customButtonImage

    property alias cfg_backgroundOpacity:       backgroundOpacity.value
    property alias cfg_sizeApps: sizeApps.currentIndex
    property alias cfg_sizeAppsFav: sizeAppsFav.currentIndex

    Button {
        id: iconButton

        Kirigami.FormData.label: i18n("Icon:")

        implicitWidth: previewFrame.width + PlasmaCore.Units.smallSpacing * 2
        implicitHeight: previewFrame.height + PlasmaCore.Units.smallSpacing * 2

        // Just to provide some visual feedback when dragging;
        // cannot have checked without checkable enabled
        checkable: true
        checked: dropArea.containsAcceptableDrag

        onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

        DragDrop.DropArea {
            id: dropArea

            property bool containsAcceptableDrag: false

            anchors.fill: parent

            onDragEnter: {
                // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                var urlString = event.mimeData.url.toString();

                // This list is also hardcoded in KIconDialog.
                var extensions = [".png", ".xpm", ".svg", ".svgz"];
                containsAcceptableDrag = urlString.indexOf("file:///") === 0 && extensions.some(function (extension) {
                    return urlString.indexOf(extension) === urlString.length - extension.length; // "endsWith"
                });

                if (!containsAcceptableDrag) {
                    event.ignore();
                }
            }
            onDragLeave: containsAcceptableDrag = false

            onDrop: {
                if (containsAcceptableDrag) {
                    // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                    iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                }
                containsAcceptableDrag = false;
            }
        }

        KQuickAddons.IconDialog {
            id: iconDialog

            function setCustomButtonImage(image) {
                configGeneral.cfg_customButtonImage = image || configGeneral.cfg_icon || "start-here-kde"
                configGeneral.cfg_useCustomButtonImage = true;
            }

            onIconNameChanged: setCustomButtonImage(iconName);
        }

        PlasmaCore.FrameSvgItem {
            id: previewFrame
            anchors.centerIn: parent
            imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
                       ? "widgets/panel-background" : "widgets/background"
            width: PlasmaCore.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
            height: PlasmaCore.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

            PlasmaCore.IconItem {
                anchors.centerIn: parent
                width: PlasmaCore.Units.iconSizes.large
                height: width
                source: configGeneral.cfg_useCustomButtonImage ? configGeneral.cfg_customButtonImage : configGeneral.cfg_icon
            }
        }

        Menu {
            id: iconMenu

            // Appear below the button
            y: +parent.height

            onClosed: iconButton.checked = false;

            MenuItem {
                text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                icon.name: "document-open-folder"
                onClicked: iconDialog.open()
            }
            MenuItem {
                text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                icon.name: "edit-clear"
                onClicked: {
                    configGeneral.cfg_icon = "start-here-kde"
                    configGeneral.cfg_useCustomButtonImage = false
                }
            }
        }
    }


    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout{
        Layout.fillWidth: true
        Kirigami.FormData.label: i18n("Background opacity:")
        Slider{
            id: backgroundOpacity
            from: 0
            to: 100
            stepSize: 5
            implicitWidth: 100
        }
        Label {
            text: backgroundOpacity.value + "% "
        }
    }

    ComboBox {
        id: sizeApps
        Kirigami.FormData.label: i18n("Size icons:")
        model: [i18n("SmallMedium"), i18n("Medium"), i18n("Large"), i18n("Huge"), i18n("X Huge"), i18n("Enormous") ]
    }

    ComboBox {
        id: sizeAppsFav
        Kirigami.FormData.label: i18n("Size icons favorites:")
        model: [i18n("SmallMedium"), i18n("Medium"), i18n("Large"), i18n("Huge"), i18n("X Huge"), i18n("Enormous") ]
    }

    RowLayout{
        Button {
            text: i18n("Unhide all applications")
            onClicked: {
                plasmoid.configuration.hiddenApplications = [];
                unhideAllAppsPopup.text = i18n("Unhidden!");
            }
        }
        Label {
            id: unhideAllAppsPopup
        }
    }


}
