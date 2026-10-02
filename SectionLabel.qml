import QtQuick
import qs.Commons

// Small muted uppercase heading ("KNOWN NETWORKS" style).
Text {
    property color fg: "white"
    color: Qt.darker(fg, 1.5)
    font.pixelSize: Style.font.bodySmall
    font.letterSpacing: 1
    font.capitalization: Font.AllUppercase
}
