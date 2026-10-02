import QtQuick
import qs.Commons

// Flat bordered button, like the DHCP / Cloudflare / Google buttons.
Rectangle {
    id: btn
    property string label: ""
    property bool active: false
    property color fg: "white"
    property string fontFamily: ""
    signal clicked()

    implicitWidth: lbl.implicitWidth + Style.space(24)
    implicitHeight: Style.space(34)
    radius: Math.min(4, Style.cornerRadius)
    opacity: enabled ? 1 : 0.5
    color: (area.containsMouse || active) ? Style.hoverFillFor(fg, Color.accent) : "transparent"
    border.width: 1
    border.color: active ? fg : Qt.darker(fg, 2.2)

    Text {
        id: lbl
        anchors.centerIn: parent
        text: btn.label
        color: btn.fg
        font.family: btn.fontFamily
        font.pixelSize: Style.font.bodySmall
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
