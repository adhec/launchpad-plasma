/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtGraphicalEffects 1.15
// Deliberately imported after QtQuick to avoid missing restoreMode property in Binding. Fix in Qt 6.
import QtQml 2.15
import QtQuick.Layouts 1.1
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwindowsystem 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.shell 2.0
import QtQuick.Controls.Styles 1.4
import org.kde.plasma.private.kicker 0.1 as Kicker

import QtQuick.Controls 2.15

import "code/tools.js" as Tools

Kicker.DashboardWindow {
    id: root

    property bool smallScreen:  ((Math.floor(width / PlasmaCore.Units.iconSizes.huge) <= 22) || (Math.floor(height / PlasmaCore.Units.iconSizes.huge) <= 14))

    property int defaultSize: { //TODO
        switch(plasmoid.configuration.sizeApps){
        case 0:  return PlasmaCore.Units.iconSizes.smallMedium;
        case 1:  return PlasmaCore.Units.iconSizes.medium;
        case 2:  return PlasmaCore.Units.iconSizes.large;
        case 3:  return PlasmaCore.Units.iconSizes.huge;
        case 4:  return 96
        case 5:  return PlasmaCore.Units.iconSizes.enormous;
        default: return 96
        }
    }

    property int defaultSizeFavorites: { //TODO
        switch(plasmoid.configuration.sizeAppsFav){
        case 0:  return PlasmaCore.Units.iconSizes.smallMedium;
        case 1:  return PlasmaCore.Units.iconSizes.medium;
        case 2:  return PlasmaCore.Units.iconSizes.large;
        case 3:  return PlasmaCore.Units.iconSizes.huge;
        case 4:  return 96
        case 5:  return PlasmaCore.Units.iconSizes.enormous;
        default: return 96
        }
    }

    property int iconSize: defaultSize //smallScreen ? PlasmaCore.Units.iconSizes.large : PlasmaCore.Units.iconSizes.huge
    property int cellSize: iconSize + (2 * PlasmaCore.Theme.mSize(PlasmaCore.Theme.defaultFont).height)
                           + (2 * PlasmaCore.Units.smallSpacing)
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeFav: defaultSizeFavorites
                              + (2 * PlasmaCore.Units.smallSpacing)
                              + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                              highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property int columns: Math.floor(((smallScreen ? 70 : 65)/100) * Math.ceil(width / cellSize))
    property bool searching: searchField.text !== ""
    property var widgetExplorer: null
    property int main_rows: Math.floor(height*0.75/cellSize) * cellSize
    property bool showFilters: plasmoid.configuration.showFilters

    keyEventProxy: searchField
    backgroundColor:  "transparent"



    onKeyEscapePressed: {
        if (searching) {
            searchField.clear();
        } else {
            root.toggle();
        }
    }

    onVisibleChanged: {
        if(visible){
            reset();
            animatorMainColumn.start()
            globalFavoritesGrid.state = 'show'
        }else{
            globalFavoritesGrid.state = 'hide'
        }
    }

    onSearchingChanged: {
        if (!searching) {
            reset();
        } else {
            //filterList.currentIndex = -1;
        }
    }

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }


    function reset() {
        searchField.clear();
        globalFavoritesGrid.currentIndex = -1;
        mainGrid.forceLayout()
        mainGrid.currentIndex = -1
        runnerGrid.currentIndex =-1

        filterList.currentIndex = 0; // force layout - all apps

        if(root.showFilters){
            filterList.forceActiveFocus();
        }
        else{
            searchField.focus = true;
        }
    }

    mainItem: MouseArea {
        id: rootItem

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        //Connections {
        //    target: kicker

        //    function onReset() {
        //        if (!root.searching) {
        //            filterList.applyFilter();
        //            funnelModel.reset();
        //        }
        //    }

        //    function onDragSourceChanged() {
        //        if (!kicker.dragSource) {
        //            // FIXME TODO HACK: Reset all views post-DND to work around
        //            // mouse grab bug despite QQuickWindow::mouseGrabberItem==0x0.
        //            // Needs a more involved hunt through Qt Quick sources later since
        //            // it's not happening with near-identical code in the menu repr.
        //            rootModel.refresh();
        //        }
        //    }
        //}

        Rectangle {
            color: colorWithAlpha(theme.backgroundColor, plasmoid.configuration.backgroundOpacity /100)
            anchors.fill: parent
        }

        Connections {
            target: plasmoid
            function onUserConfiguringChanged() {
                if (plasmoid.userConfiguring) {
                    root.hide()
                }
            }
        }

        PlasmaComponents.Menu {
            id: contextMenu

            PlasmaComponents.MenuItem {
                action: plasmoid.action("configure")
            }
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

        Kicker.FunnelModel {
            id: funnelModel

            onSourceModelChanged: {
                mainGrid.forceLayout();
            }
        }


        Kicker.ContainmentInterface {
            id: containmentInterface
        }


        ColumnLayout{
            anchors {
                right: parent.right
                top: parent.top
                margins: PlasmaCore.Units.smallSpacing *2
            }
            spacing: 2
            MiniButton{
                icon: "system-shutdown"
                onClicked:  { pmEngine.performOperation("requestShutDown"); root.toggle();}
                tooltip: i18n("Leave ...")
            }
            MiniButton{
                icon: "system-lock-screen"
                onClicked:  { pmEngine.performOperation("lockScreen"); root.toggle();}
                tooltip: i18n("Lock Screen")
            }
            MiniButton{
                icon:  "window-pin"
                tooltip: i18n("Show filters")
                onClicked: {
                    plasmoid.configuration.showFilters = !plasmoid.configuration.showFilters
                    reset()
                }
            }
        }

        Rectangle{
            anchors.centerIn: searchField
            width: searchField.width + 2
            height: searchField.height + 4
            color: colorWithAlpha(theme.textColor, 0)
            radius: 6
            border.color: colorWithAlpha(theme.textColor, 0.4) //#TODO settings
            border.width: 1
        }

        PlasmaComponents.TextField {
            id: searchField
            anchors.bottom: mainColumn.top
            anchors.bottomMargin: PlasmaCore.Units.gridUnit * 3
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: PlasmaCore.Units.gridUnit * 16
            font.pointSize: smallScreen ? dummyHeading.font.pointSize  : Math.ceil(dummyHeading.font.pointSize) + 3
            style: TextFieldStyle {
                textColor: theme.textColor
                background: Rectangle {
                    opacity: 0
                }
            }
            //background: Rectangle {
            //    opacity: 0
            //    implicitWidth: PlasmaCore.Units.gridUnit * 16
            //    implicitHeight: PlasmaCore.Units.gridUnit + 8
            //}
            placeholderText: i18n("Search")
            horizontalAlignment: TextInput.AlignHCenter

            onTextChanged: {
                runnerModel.query = searchField.text;
            }

            function clear() {
                text = "";
            }
        }

        PlasmaCore.IconItem {
            source: 'nepomuk'
            anchors {
                left: searchField.left
                verticalCenter: searchField.verticalCenter
                leftMargin: PlasmaCore.Units.smallSpacing * 2
            }
            height: PlasmaCore.Units.iconSizes.small
            width: height
        }


        ScaleAnimator{ id: animatorMainColumn ;from: 1.05; to: 1 ; target: mainColumn; duration: PlasmaCore.Units.longDuration}

        Item {

            id: mainColumn

            //transformOrigin: Item.Top
            width: (root.columns * root.cellSize) + PlasmaCore.Units.gridUnit
            height: root.main_rows

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            property int columns: root.columns
            property Item visibleGrid: searching ? runnerGrid : mainGrid


            function tryActivate(row, col) {
                if (visibleGrid) {
                    visibleGrid.tryActivate(row, col);
                }
            }


            ItemGridView {
                id: mainGrid

                anchors {
                    top: parent.top
                    // topMargin: PlasmaCore.Units.largeSpacing
                }

                visible: !searching// opacity !== 0.0
                width: parent.width
                height: root.main_rows
                cellWidth:  root.cellSize
                cellHeight: cellWidth
                iconSize:  root.iconSize

                onCurrentIndexChanged: {

                }

                onKeyNavLeft: {
                }

                onKeyNavRight: {
                    if(root.showFilters)
                        filterListScrollArea.focus = true;
                }

                onKeyNavUp: {

                }

                onKeyNavDown: {
                    globalFavoritesGrid.tryActivate(0,0)
                }

                onItemActivated: {

                }
            }

            ItemGridView {
                id: runnerGrid

                anchors {
                    top: parent.top
                }
                width: parent.width
                height: root.main_rows
                visible: searching
                cellWidth:  root.cellSize
                cellHeight: cellWidth
                forceFocusIndex0: true
                iconSize:  root.iconSize
                model : runnerModel.count > 0 ? runnerModel.modelForRow(0) : undefined
                onLostFocus: {
                    if(root.showFilters)
                        filterList.forceActiveFocus();
                    else{
                        rootItem.focus = true
                    }
                }
            }

            Keys.onPressed: event => {
                                if(searching){
                                    event.accepted = true;
                                    return
                                }
                                if (event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    if (filterList.enabled && root.showFilters) {
                                        filterList.forceActiveFocus();
                                    } else {
                                        globalFavoritesGrid.tryActivate(0, 0);
                                    }
                                } else if (event.key === Qt.Key_Backtab) {
                                    event.accepted = true;
                                    if (globalFavoritesGrid.enabled) {
                                        globalFavoritesGrid.tryActivate(0, 0);
                                    }
                                }
                            }
        }

        Item {
            id: filterListColumn

            anchors.top: mainColumn.top
            anchors.bottom: mainColumn.bottom
            anchors.left: mainColumn.right
            anchors.leftMargin: PlasmaCore.Units.gridUnit
            anchors.topMargin: PlasmaCore.Units.gridUnit
            anchors.right: parent.right

            enabled: root.showFilters
            //visible: plasmoid.configuration.showFilters
            //onVisibleChanged: {
            //    if(visible){
            //        //animatorFilters.start()
            //    }
            //}
            //XAnimator{ id: animatorFilters ;from: 80; to: 0 ; target: filterListScrollArea;
            //    duration: PlasmaCore.Units.longDuration;
            //}
            opacity: root.showFilters ? 1 : 0
            Behavior on opacity { SmoothedAnimation { duration: PlasmaCore.Units.longDuration; velocity: 0.01 } }

            PlasmaComponents3.ScrollView {

                id: filterListScrollArea
                width: parent.width
                height: mainGrid.height

                enabled: !root.searching

                property alias currentIndex: filterList.currentIndex

                opacity: root.visible ? (root.searching ? 0.3 : 1.0) : 0.3

                Behavior on opacity { SmoothedAnimation { duration: PlasmaCore.Units.longDuration; velocity: 0.01 } }

                PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff
                PlasmaComponents3.ScrollBar.vertical.policy: PlasmaComponents3.ScrollBar.AsNeeded

                onEnabledChanged: {
                    if (!enabled) {
                        filterList.currentIndex = -1;
                    }
                }

                onCurrentIndexChanged: {
                    focus = (currentIndex !== -1);
                }

                ListView {
                    id: filterList

                    focus: true
                    property int eligibleWidth: width
                    property int hItemMargins: Math.max(highlightItemSvg.margins.left + highlightItemSvg.margins.right,
                                                        listItemSvg.margins.left + listItemSvg.margins.right)

                    boundsBehavior: Flickable.StopAtBounds
                    snapMode: ListView.SnapToItem
                    spacing: 0
                    keyNavigationWraps: true

                    highlightResizeDuration: 0
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0

                    delegate: Item {
                        id: item

                        property var m: model
                        property int textWidth: label.contentWidth
                        property int mouseCol
                        //property bool hasActionList: ((model.favoriteId !== null)
                        //                              || (("hasActionList" in model) && (model.hasActionList === true)))
                        //property Item menu: actionMenu

                        width: ListView.view.width
                        height: Math.ceil((label.paintedHeight
                                           + Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                      listItemSvg.margins.top + listItemSvg.margins.bottom)) / 2) * 2

                        Accessible.role: Accessible.MenuItem
                        Accessible.name: model.display

                        PlasmaExtras.Heading {
                            id: label

                            anchors {
                                fill: parent
                                leftMargin: highlightItemSvg.margins.left
                                rightMargin: highlightItemSvg.margins.right
                            }

                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            opacity: 1.0
                            level: 2

                            text: model.display
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: item.ListView.view.currentIndex = index
                            onContainsMouseChanged: {
                                if(containsMouse)
                                    item.ListView.view.currentIndex = index
                            }
                        }
                    }
                    highlight: PlasmaComponents.Highlight {
                        opacity: filterListScrollArea.focus ? 1.0 : 0.7
                    }

                    onCurrentIndexChanged: {
                        if(currentIndex >= 0)
                            animatorMainColumn.start()
                        applyFilter()
                    }

                    onCountChanged: {
                        var width = 0;
                        for (var i = 0; i < rootModel.count; ++i) {
                            headingMetrics.text = rootModel.labelForRow(i);
                            if (headingMetrics.width > width) {
                                width = headingMetrics.width;
                            }
                        }
                        filterListScrollArea.width = width + hItemMargins + (PlasmaCore.Units.gridUnit * 2);
                    }

                    function applyFilter() {
                        if (!root.searching && currentIndex >= 0) {
                            var model = rootModel.modelForRow(currentIndex);
                            funnelModel.sourceModel = model;
                        } else {
                            funnelModel.sourceModel = null;
                        }
                    }

                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Left) {
                                            event.accepted = true;
                                            mainColumn.tryActivate(0,0);
                                        } else if (event.key === Qt.Key_Tab) {
                                            event.accepted = true;
                                            globalFavoritesGrid.tryActivate(0,0)
                                        } else if (event.key === Qt.Key_Backtab) {
                                            event.accepted = true;
                                            mainColumn.tryActivate(0, 0);
                                        }
                                    }
                }
            }
        }




        Item {
            id: favoritesColumn

            width: Math.min(Math.floor(root.width*0.7/cellSizeFav) * cellSizeFav,globalFavoritesGrid.model.count * cellSizeFav ) + PlasmaCore.Units.gridUnit*2
            height: cellSizeFav
            anchors {
                bottom: parent.bottom
                bottomMargin: PlasmaCore.Units.smallSpacing
                horizontalCenter: parent.horizontalCenter
            }


            Rectangle{
                id: rectFavorites
                color: colorWithAlpha(theme.backgroundColor, 0.3)
                radius: 15
                width: favoritesColumn.width + PlasmaCore.Units.smallSpacing*2
                height: favoritesColumn.height
                anchors.centerIn: globalFavoritesGrid
            }
            ItemGridView {
                id: globalFavoritesGrid

                state: 'hide'
                states: [State {
                        name: "hide";
                        AnchorChanges { target: globalFavoritesGrid; anchors.top: favoritesColumn.bottom }
                        PropertyChanges { target: globalFavoritesGrid; opacity: 0 }
                    },
                    State {
                        name: "show";
                        AnchorChanges { target: globalFavoritesGrid; anchors.top: favoritesColumn.top }
                        PropertyChanges { target: globalFavoritesGrid; opacity: 1 }
                    }]

                transitions: Transition {
                    AnchorAnimation { duration: PlasmaCore.Units.longDuration}
                    PropertyAnimation { property: "opacity" ;duration: PlasmaCore.Units.longDuration}
                }


                width: parent.width
                height: cellSizeFav
                cellWidth: cellSizeFav
                cellHeight: cellSizeFav
                iconSize: defaultSizeFavorites
                showLabels: false
                dropEnabled: true
                usesPlasmaTheme: false
                opacity: enabled ? 1.0 : 0.3
                onCurrentIndexChanged: {
                }

                onKeyNavUp: {
                    mainColumn.tryActivate(0, 0);
                }

                onKeyNavRight: {
                }

                onKeyNavDown: {
                }

                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Tab) {
                                        event.accepted = true;
                                        mainColumn.tryActivate(0, 0);
                                    } else if (event.key === Qt.Key_Backtab) {
                                        event.accepted = true;
                                    }
                                }
            }
        }

        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key ===  Qt.Key_Tab ) {
                                mainColumn.tryActivate(0,0)
                                event.accepted = true;
                                return
                            }
                            if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                                searchField.focus = true;
                                return
                            }
                        }

        onPressed: mouse => {
                       if (mouse.button === Qt.RightButton) {
                           contextMenu.open(mouse.x, mouse.y);
                       }
                   }

        onClicked: mouse => {
                       if (mouse.button === Qt.LeftButton) {
                           root.toggle();
                       }
                   }


    }

    function setModels(){
        globalFavoritesGrid.model = globalFavorites
        filterList.model = rootModel
        funnelModel.sourceModel = rootModel.modelForRow(0)
        mainGrid.model = funnelModel

    }
    Component.onCompleted: {
        rootModel.refreshed.connect(setModels)
        rootModel.refresh();
        reset()
    }

}
