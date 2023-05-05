
import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore


Rectangle{
    id: root

    property alias icon: icon.source
    property alias tooltip: tooltip.text

    signal clicked()

    width: PlasmaCore.Units.iconSizes.large
    height: width
    radius: width*0.5
    color:  rootMouseArea.containsMouse ? theme.highlightColor : 'transparent'

    PlasmaCore.IconItem {
        id: icon
        anchors.centerIn: parent
        width: PlasmaCore.Units.iconSizes.smallMedium
        opacity: 0.8
    }

    ToolTip {
        id: tooltip
        parent: root
        visible: rootMouseArea.containsMouse

    }

    MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
