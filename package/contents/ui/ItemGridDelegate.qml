/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    property bool showLabel: true

    readonly property int itemIndex: model.index
    readonly property url url: model.url != undefined ? model.url : ""
    property bool pressed: false
    readonly property bool hasActionList: ((model.favoriteId != null)
                                           || (("hasActionList" in model) && (model.hasActionList == true)))

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        return Tools.triggerAction(plasmoid, GridView.view.model, model.index, actionId, actionArgument);
    }

    Rectangle{
        id: box
        height: parent.height
        width:  parent.width
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:"transparent"
    }
    PlasmaCore.IconItem {
        id: icon
        y: iconSize*0.2
        anchors.horizontalCenter: box.horizontalCenter
        anchors.verticalCenter: !showLabel ? box.verticalCenter : undefined
        width: iconSize
        height: width
        animated: false
        usesPlasmaTheme: item.GridView.view.usesPlasmaTheme
        source: model.decoration
    }

    Rectangle {
        color: colorWithAlpha(theme.backgroundColor, 0.2)
        width: label.implicitWidth + units.smallSpacing*2 > cellSizeWidth ? cellSizeWidth : label.implicitWidth + units.smallSpacing*2 // + units.smallSpacing*2 > iconSize ? label.implicitWidth + units.smallSpacing*2 : iconSize
        height: label.height
        anchors.centerIn: label
        visible: showLabel && plasmoid.configuration.showBackLabels
        radius: 6        
    }

    ToolTip {
        parent: icon
        visible: item.GridView.isCurrentItem && model.description
        text: model.description
    }

    PlasmaComponents.Label {
        id: label
        visible: showLabel
        anchors {
            top: icon.bottom
            topMargin: units.smallSpacing
            left: box.left
            leftMargin: highlightItemSvg.margins.left
            right: box.right
            rightMargin: highlightItemSvg.margins.right
        }

        horizontalAlignment: Text.AlignHCenter

        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        text: model.display
    }


    Keys.onPressed: {
        if (event.key == Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
            event.accepted = true;
            GridView.view.model.trigger(index, "", null);
            root.toggle();

        }
    }
}
