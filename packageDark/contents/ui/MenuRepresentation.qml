/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.4
import QtQuick.Controls 2.0

import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker

import "../code/tools.js" as Tools
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.4
//import QtQuick.Controls 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3


Kicker.DashboardWindow {
    
    id: root

    property int iconSize:    plasmoid.configuration.iconSize
    property int iconSizeFavorites:    plasmoid.configuration.iconSizeFavorites
    property int spaceWidth:  plasmoid.configuration.spaceWidth
    property int spaceHeight: plasmoid.configuration.spaceHeight
    property int cellSizeWidth: spaceWidth + iconSize + theme.mSize(theme.defaultFont).height
                                + (2 * units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeHeight: spaceHeight + iconSize + theme.mSize(theme.defaultFont).height
                                 + (2 * units.smallSpacing)
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))


    property bool searching: (searchField.text != "")

    keyEventProxy: searchField
    backgroundColor: "transparent"

    property bool linkUseCustomSizeGrid: plasmoid.configuration.useCustomSizeGrid
    property int gridNumCols:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberColumns : Math.floor(width  * 0.85  / cellSizeWidth)
    property int gridNumRows:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberRows : Math.floor(height * 0.8  /  cellSizeHeight)
    property int widthScreen:  gridNumCols * cellSizeWidth
    property int heightScreen: gridNumRows * cellSizeHeight
    property bool showFavorites: plasmoid.configuration.showFavorites
    property int startIndex: 1 //(showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onKeyEscapePressed: {
        if (searching) {
            searchField.text = ""
        } else {
            root.toggle();
        }
    }

    onVisibleChanged: {
        animationSearch.start()
        reset();
        rootModel.pageSize = gridNumCols*gridNumRows
    }

    onSearchingChanged: {
        if (searching) {
            pageList.model = runnerModel;
            paginationBar.model = runnerModel;
        } else {
            reset();
        }
        
    }

    function reset() {
        if (!searching) {
            pageList.model = rootModel.modelForRow(0);
            paginationBar.model = rootModel.modelForRow(0);
        }
        searchField.text = "";
        pageListScrollArea.focus = true;
        pageList.currentIndex = startIndex;
        pageList.positionViewAtIndex(pageList.currentIndex, ListView.Contain);
        pageList.currentItem.itemGrid.currentIndex = -1;
    }



    mainItem: Rectangle{

        anchors.fill: parent
        color: 'transparent'

        Image {
            source: "br.png"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: plasmoid.configuration.showRoundedCorners
            z:2
        }
        Image {
            source: "bl.png"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: plasmoid.configuration.showRoundedCorners
            z:2
        }
        Image {
            source: "tr.png"
            anchors.right: parent.right
            anchors.top: parent.top
            visible: plasmoid.configuration.showRoundedCorners
            z:2
        }
        Image {
            source: "tl.png"
            anchors.left: parent.left
            anchors.top: parent.top
            visible: plasmoid.configuration.showRoundedCorners
            z:2
        }

        ScaleAnimator{
            id: animationSearch
            from: 1.1
            to: 1
            target: mainPage
        }

        MouseArea {

            id: rootMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            hoverEnabled: true

            onClicked: {
                root.toggle();
            }

            Rectangle{
                anchors.fill: parent
                color: colorWithAlpha('#000000', plasmoid.configuration.backgroundOpacity / 100)
            }

            PlasmaExtras.Heading {
                id: dummyHeading
                visible: false
                width: 0
                level: 5
            }

            TextMetrics {
                id: headingMetrics
                font: dummyHeading.font
            }

            ActionMenu {
                id: actionMenu
                onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
                onClosed: {
                    if (pageList.currentItem) {
                        pageList.currentItem.itemGrid.currentIndex = -1;
                    }
                }
            }
            Rectangle{
                anchors.centerIn: searchField
                width: searchField.width + 2
                height: searchField.height + 2
                color: '#11ffffff'
                radius: 6
            }

            PlasmaComponents.TextField {
                id: searchField

                anchors.top: parent.top
                anchors.topMargin: units.iconSizes.large
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gridUnit * 18
                font.pointSize: Math.ceil(dummyHeading.font.pointSize) + 3
                style: TextFieldStyle {
                    textColor: '#fcfcfc'
                    background: Rectangle {
                        opacity: 0
                    }
                }
                placeholderText: i18n("<font color='#dcdcdc'>Search</font>")
                horizontalAlignment: TextInput.AlignHCenter
                onTextChanged: {
                    runnerModel.query = text;
                }


                Keys.onPressed: {
                    if (event.key == Qt.Key_Down || (event.key == Qt.Key_Right && cursorPosition == length)) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                        if (text != "" && pageList.currentItem.itemGrid.count > 0) {
                            event.accepted = true;
                            if(pageList.currentItem.itemGrid.currentIndex == -1) {
                                pageList.currentItem.itemGrid.tryActivate(0, 0);
                            }
                            pageList.currentItem.itemGrid.model.trigger(pageList.currentItem.itemGrid.currentIndex, "", null);
                            root.toggle();
                        }
                    } else if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    } else if (event.key == Qt.Key_Backtab) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);

                    }
                }

                function backspace() {
                    if (!root.visible) {
                        return;
                    }
                    focus = true;
                    text = text.slice(0, -1);

                }

                function appendText(newText) {
                    if (!root.visible) {
                        return;
                    }
                    focus = true;
                    text = text + newText;
                }
            }

            Rectangle{

                id: mainPage

                width:   widthScreen
                height:  heightScreen
                color: "transparent"
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                PlasmaExtras.ScrollArea {
                    id: pageListScrollArea
                    width: parent.width
                    height: parent.height
                    focus: true;
                    frameVisible: false;
                    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                    verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                    ListView {
                        id: pageList
                        anchors.fill: parent
                        snapMode: ListView.SnapOneItem
                        orientation: Qt.Horizontal


                        //highlightMoveDuration : plasmoid.configuration.scrollAnimationDuration
                        //highlightMoveVelocity: -1
                        highlightFollowsCurrentItem: false
                        highlightRangeMode : ListView.StrictlyEnforceRange
                        highlight: Component {
                            id: highlight
                            Rectangle {
                                width: widthScreen; height: heightScreen
                                color: "transparent"
                                x: pageList.currentItem.x
                                Behavior on x { PropertyAnimation {
                                        duration: plasmoid.configuration.scrollAnimationDuration
                                        easing.type: Easing.OutCubic
                                    } }
                            }
                        }


                        onCurrentItemChanged: {
                            if (!currentItem) {
                                return;
                            }
                            currentItem.itemGrid.focus = true;
                        }
                        onModelChanged: {
                            if(searching)
                                currentIndex = 0;
                            else{
                                currentIndex = startIndex;
                                positionViewAtIndex(currentIndex, ListView.Contain);
                            }
                        }

                        onFlickingChanged: {
                            if (!flicking) {
                                var pos = mapToItem(contentItem, root.width / 2, root.height / 2);
                                var itemIndex = indexAt(pos.x, pos.y);
                                currentIndex = itemIndex;
                            }
                        }

                        onMovingChanged: {
                            if (!moving) {
                                // Counter the case where mouse hovers over another grid as
                                // flick ends, causing loss of focus on flicked in grid
                                currentItem.itemGrid.focus = true;
                            }
                        }

                        function cycle() {
                            enabled = false;
                            enabled = true;
                        }

                        // Attempts to change index based on next. If next is true, increments,
                        // otherwise decrements. Stops on list boundaries. If activate is true,
                        // also tries to activate what appears to be the next selected gridItem
                        function activateNextPrev(next, activate = true) {
                            // Carry over row data for smooth transition.
                            var lastRow = pageList.currentItem.itemGrid.currentRow();
                            if (activate)
                                pageList.currentItem.itemGrid.hoverEnabled = false;

                            var oldItem = pageList.currentItem;
                            if (next) {
                                var newIndex = pageList.currentIndex + 1;

                                if (newIndex < pageList.count) {
                                    pageList.currentIndex = newIndex;
                                }
                            } else {
                                var newIndex = pageList.currentIndex - 1;

                                if (newIndex >= (showFavorites ? 0 : 1)) {
                                    pageList.currentIndex = newIndex;
                                }
                            }

                            // Give old values to next grid if we changed
                            if(oldItem != pageList.currentItem && activate) {
                                pageList.currentItem.itemGrid.hoverEnabled = false;
                                pageList.currentItem.itemGrid.tryActivate(lastRow, next ? 0 : gridNumCols - 1);
                            }
                        }

                        delegate: Item {

                            width:   gridNumCols * cellSizeWidth
                            height:  gridNumRows * cellSizeHeight

                            property Item itemGrid: gridView

                            visible: (showFavorites || searching) ? true : (index != 0)

                            ItemGridView {
                                id: gridView

                                property bool isCurrent: (pageList.currentIndex == index)
                                hoverEnabled: isCurrent

                                visible: model.count > 0
                                anchors.fill: parent

                                cellWidth:  cellSizeWidth
                                cellHeight: cellSizeHeight

                                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                                dragEnabled: (index == 0) && plasmoid.configuration.showFavorites

                                model: searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)
                                onCurrentIndexChanged: {
                                    if (currentIndex != -1 && !searching) {
                                        pageListScrollArea.focus = true;
                                        focus = true;
                                    }
                                }

                                onCountChanged: {
                                    if (index == 0) {
                                        if (searching) {
                                            currentIndex = 0;
                                        } else if (count == 0) {
                                            root.showFavorites = false;
                                            root.startIndex = 1;
                                            if (pageList.currentIndex == 0) {
                                                pageList.currentIndex = 1;
                                            }
                                        } else {
                                            root.showFavorites = plasmoid.configuration.showFavorites;
                                            root.startIndex = 1 //<> (showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1
                                        }
                                    }
                                }

                                onKeyNavUp: {
                                    currentIndex = -1;
                                    searchField.focus = true;
                                }

                                onKeyNavDown: {
                                }
                                onKeyNavRight: {
                                    pageList.activateNextPrev(1);
                                }

                                onKeyNavLeft: {
                                    pageList.activateNextPrev(0);
                                }
                            }

                            Kicker.WheelInterceptor {
                                anchors.fill: parent
                                z: 1

                                onWheelMoved: {
                                    //event.accepted = false;
                                    rootMouseArea.wheelDelta = rootMouseArea.scrollByWheel(rootMouseArea.wheelDelta, delta);
                                }
                            }
                        }
                    }
                }

            }

            Rectangle{
                width: gridViewFavorites.width + units.smallSpacing*2
                height: gridViewFavorites.height
                anchors.centerIn: gridViewFavorites
                color: colorWithAlpha('#000000', 0.3)
                radius: 8 // TODO: from settings
                border.color: "#aa505050" // TODO: from settings
                border.width: 1
                visible: plasmoid.configuration.showFavorites
            }

            ItemGridView {
                id: gridViewFavorites
                visible: plasmoid.configuration.showFavorites

                anchors {
                    bottom: parent.bottom
                    bottomMargin: units.smallSpacing * 2
                    horizontalCenter: parent.horizontalCenter
                }
                focus: true
                width: globalFavorites.count * cellWidth > root.widthScreen * 0.8  ? root.widthScreen * 0.8 : globalFavorites.count * cellWidth
                height: root.iconSizeFavorites + units.largeSpacing

                usesPlasmaTheme: false
                cellWidth: height + units.smallSpacing
                cellHeight: height
                iconSize: root.iconSizeFavorites
                showLabels: false
                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                model: globalFavorites

                onKeyNavDown: {
                    documentsFavoritesGrid.tryActivate(0,0)
                }

                Keys.onPressed: {
                    if (event.key == Qt.Key_Backspace) {
                        event.accepted = true;
                        searchField.backspace();
                    } else if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        documentsFavoritesGrid.tryActivate(0,0);
                    } else if (event.key == Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.visible = false;
                        }
                    } else if (event.text != "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }

                }
            }

            Rectangle{
                id: buttonPower
                anchors {
                    right: parent.right
                    top: parent.top
                    margins: 2
                }
                width: units.iconSizes.large
                height: width
                visible: plasmoid.configuration.showSystemActions
                radius: width*0.5
                color:  buttonPowerMouseArea.containsMouse ? theme.highlightColor : 'transparent'

                PlasmaCore.IconItem {
                    anchors.centerIn: parent
                    width: units.iconSizes.smallMedium
                    source: "system-shutdown"
                }

                ToolTip {
                    parent: buttonPower
                    visible: buttonPowerMouseArea.containsMouse
                    text: 'Leave ...'
                }

                MouseArea {
                    id: buttonPowerMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked:  { pmEngine.performOperation("requestShutDown"); root.toggle();}
                }
            }

            Rectangle{
                id: buttonLock
                anchors{
                    top: buttonPower.bottom
                    right: buttonPower.right
                }
                width: units.iconSizes.large
                height: width
                visible: plasmoid.configuration.showSystemActions && pmEngine.data["Sleep States"]["LockScreen"]
                radius: width*0.5
                color:  buttonLockMouseArea.containsMouse ? theme.highlightColor : 'transparent'

                PlasmaCore.IconItem {
                    anchors.centerIn: parent
                    width: units.iconSizes.smallMedium
                    source: "system-lock-screen"
                }

                ToolTip {
                    parent: buttonLock
                    visible: buttonLockMouseArea.containsMouse
                    text: 'Lock Screen'
                }

                MouseArea {
                    id: buttonLockMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { pmEngine.performOperation("lockScreen"); root.toggle();}
                }
            }



            ListView {
                id: paginationBar

                anchors {
                    right: parent.right
                    rightMargin: units.largeSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: model.count * units.iconSizes.smallMedium
                width:  units.largeSpacing
                orientation: Qt.Vertical

                delegate: Item {
                    width: units.iconSizes.small
                    height: width

                    Rectangle {
                        id: pageDelegate
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            margins: 10
                        }
                        width: parent.width  * 0.7
                        height: width

                        property bool isCurrent: (pageList.currentIndex == index)

                        radius: width / 2
                        color: '#dcdcdc'
                        visible: index != 0 // (showFavorites || searching) ? true : (index != 0)
                        opacity: 0.5
                        Behavior on width { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
                        Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                        states: [
                            State {
                                when: pageDelegate.isCurrent
                                PropertyChanges { target: pageDelegate; width: parent.width - (units.smallSpacing * 1.75) }
                                PropertyChanges { target: pageDelegate; opacity: 1 }
                            }
                        ]
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageList.currentIndex = index;
                    }
                }
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Escape) {
                    event.accepted = true;

                    if (searching) {
                        reset();
                    } else {
                        root.toggle();
                    }

                    return;
                }

                if (searchField.focus) {
                    return;
                }

                if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    searchField.backspace();
                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    if (pageList.currentItem.itemGrid.currentIndex == -1) {
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    } else {
                        //pageList.currentItem.itemGrid.keyNavDown();
                        pageList.currentItem.itemGrid.currentIndex = -1;
                        searchField.focus = true;

                    }
                } else if (event.key == Qt.Key_Backtab) {
                    event.accepted = true;
                    pageList.currentItem.itemGrid.keyNavUp();
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }
            }

            property int wheelDelta: 0

            function scrollByWheel(wheelDelta, eventDelta) {
                // magic number 120 for common "one click"
                // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                wheelDelta += (Math.abs(eventDelta.x) > Math.abs(eventDelta.y)) ? eventDelta.x : eventDelta.y;

                var increment = 0;

                while (wheelDelta >= 120) {
                    wheelDelta -= 120;
                    increment++;
                }

                while (wheelDelta <= -120) {
                    wheelDelta += 120;
                    increment--;
                }

                while (increment != 0) {
                    pageList.activateNextPrev(increment < 0, false);
                    increment += (increment < 0) ? 1 : -1;
                }

                return wheelDelta;
            }

            onWheel: {
                wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta);
            }

            onPositionChanged: {
                var pos = mapToItem(pageList.contentItem, mouse.x, mouse.y);
                var hoveredPage = pageList.itemAt(pos.x, pos.y);
                if (hoveredPage == null)
                    return;

                // Note: onPositionChanged will not be triggered if the mouse is
                // currently over a gridView with hover enabled, so we know that
                // any hoveredGrid under the mouse at this point has hover disabled

                // Reset hover for the current grid if we disabled it earlier in activateNextPrev
                if (pageList.currentItem == hoveredPage) {
                    hoveredPage.itemGrid.hoverEnabled = true;
                }
            }

        }

    }
    Component.onCompleted: {
        rootModel.pageSize = gridNumCols*gridNumRows
        pageList.model = rootModel.modelForRow(0);
        paginationBar.model = rootModel.modelForRow(0);
        searchField.text = "";
        pageListScrollArea.focus = true;
        pageList.currentIndex = startIndex;
        kicker.reset.connect(reset);
    }
}
