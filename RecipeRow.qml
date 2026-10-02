import QtQuick
import qs.Commons

// One recipe in a list: thumbnail, name, star. Hover highlights the row.
Rectangle {
    id: row
    property var meal: ({})
    property color fg: "white"
    property string fontFamily: ""
    property bool starred: false
    signal opened()
    signal starToggled()

    height: Style.space(60)
    radius: Style.cornerRadius
    color: hover.hovered ? Style.hoverFillFor(fg, Color.accent) : "transparent"

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.opened()
    }

    Image {
        id: thumb
        anchors.left: parent.left
        anchors.leftMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(44)
        height: Style.space(44)
        source: row.meal && row.meal.strMealThumb ? row.meal.strMealThumb + "/small" : ""
        sourceSize.width: Style.space(44) * 2
        sourceSize.height: Style.space(44) * 2
        fillMode: Image.PreserveAspectCrop
    }

    Column {
        anchors.left: thumb.right
        anchors.leftMargin: Style.space(12)
        anchors.right: star.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
            width: parent.width
            text: row.meal ? row.meal.strMeal : ""
            color: row.fg
            elide: Text.ElideRight
            font.family: row.fontFamily
            font.pixelSize: Style.font.body
        }
        Text {
            text: "VIEW RECIPE"
            color: Qt.darker(row.fg, 1.8)
            font.family: row.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
        }
    }

    Text {
        id: star
        anchors.right: parent.right
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        text: row.starred ? "★" : "☆"
        color: row.starred ? Color.accent : Qt.darker(row.fg, 1.6)
        font.family: row.fontFamily
        font.pixelSize: Style.font.title

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: row.starToggled()
        }
    }
}
