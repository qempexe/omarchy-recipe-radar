import QtQuick
import qs.Commons

Item {
    id: detail

    property var recipe: null
    property var pantryItems: []
    property var favorites: []
    property color fg: "white"
    property string fontFamily: ""

    signal backRequested()
    signal favoriteToggled(var meal)
    signal randomRequested()

    function inPantry(ingredient) {
        var lower = String(ingredient).trim().toLowerCase()
        for (var p = 0; p < pantryItems.length; p++)
            if (lower.indexOf(pantryItems[p]) !== -1 || pantryItems[p].indexOf(lower) !== -1)
                return true
        return false
    }

    function isFav(meal) {
        if (!meal) return false
        for (var i = 0; i < favorites.length; i++)
            if (favorites[i].idMeal === meal.idMeal) return true
        return false
    }

    function ingredientModel() {
        if (!recipe) return []
        var items = []
        for (var i = 1; i <= 20; i++) {
            var ing = recipe["strIngredient" + i]
            var meas = recipe["strMeasure" + i]
            if (ing && ing.trim() !== "")
                items.push({ ingredient: ing.trim(), measure: (meas || "").trim(), have: inPantry(ing) })
        }
        return items
    }

    readonly property var ingredients: ingredientModel()
    readonly property int haveCount: {
        var c = 0
        for (var i = 0; i < ingredients.length; i++) if (ingredients[i].have) c++
        return c
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: scroller.width
            spacing: Style.space(12)

            // Header: back, title, star
            Item {
                width: parent.width
                height: Style.space(36)

                RRButton {
                    id: backBtn
                    label: "← BACK"
                    fg: detail.fg
                    fontFamily: detail.fontFamily
                    height: Style.space(30)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: detail.backRequested()
                }
                Text {
                    anchors.left: backBtn.right
                    anchors.leftMargin: Style.space(12)
                    anchors.right: star.left
                    anchors.rightMargin: Style.space(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: detail.recipe ? detail.recipe.strMeal : "Loading…"
                    color: detail.fg
                    elide: Text.ElideRight
                    font.family: detail.fontFamily
                    font.pixelSize: Style.font.title
                }
                Text {
                    id: star
                    visible: !!detail.recipe
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: detail.isFav(detail.recipe) ? "★" : "☆"
                    color: detail.isFav(detail.recipe) ? Color.accent : Qt.darker(detail.fg, 1.6)
                    font.pixelSize: Style.font.title
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (detail.recipe) detail.favoriteToggled(detail.recipe)
                    }
                }
            }

            Image {
                visible: !!detail.recipe && !!detail.recipe.strMealThumb
                width: parent.width
                height: visible ? Style.space(150) : 0
                source: detail.recipe && detail.recipe.strMealThumb ? detail.recipe.strMealThumb + "/medium" : ""
                fillMode: Image.PreserveAspectCrop
            }

            Text {
                visible: !!detail.recipe && detail.haveCount > 0
                text: "✓ " + detail.haveCount + " OF " + detail.ingredients.length + " INGREDIENTS IN YOUR PANTRY"
                color: Color.accent
                font.family: detail.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 1
            }

            Rectangle { width: parent.width; height: Style.spacing.hairline; color: detail.fg; opacity: 0.12 }

            SectionLabel { text: "Ingredients"; fg: detail.fg; font.family: detail.fontFamily }

            Column {
                width: parent.width
                spacing: Style.space(4)
                Repeater {
                    model: detail.ingredients
                    Row {
                        width: col.width
                        spacing: Style.space(8)
                        Text {
                            text: modelData.have ? "✓" : "•"
                            color: modelData.have ? Color.accent : Qt.darker(detail.fg, 1.6)
                            font.family: detail.fontFamily
                            font.pixelSize: Style.font.body
                        }
                        Text {
                            width: parent.width - Style.space(24)
                            text: modelData.measure ? modelData.measure + " " + modelData.ingredient : modelData.ingredient
                            wrapMode: Text.WordWrap
                            color: modelData.have ? Color.accent : detail.fg
                            font.family: detail.fontFamily
                            font.pixelSize: Style.font.body
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: Style.spacing.hairline; color: detail.fg; opacity: 0.12 }

            SectionLabel { text: "Instructions"; fg: detail.fg; font.family: detail.fontFamily }

            Text {
                width: parent.width
                text: detail.recipe ? detail.recipe.strInstructions : ""
                wrapMode: Text.WordWrap
                color: Qt.darker(detail.fg, 1.2)
                font.family: detail.fontFamily
                font.pixelSize: Style.font.bodySmall
                lineHeight: 1.15
            }

            Row {
                width: parent.width
                spacing: Style.space(8)
                RRButton {
                    visible: !!detail.recipe && !!detail.recipe.strYoutube
                    width: visible ? (parent.width - Style.space(8)) / 2 : 0
                    label: "▶ YOUTUBE"
                    fg: detail.fg
                    fontFamily: detail.fontFamily
                    onClicked: Qt.openUrlExternally(detail.recipe.strYoutube)
                }
                RRButton {
                    width: (!!detail.recipe && !!detail.recipe.strYoutube) ? (parent.width - Style.space(8)) / 2 : parent.width
                    label: "🎲 ANOTHER RANDOM"
                    fg: detail.fg
                    fontFamily: detail.fontFamily
                    onClicked: detail.randomRequested()
                }
            }

            Item { width: 1; height: Style.space(8) }
        }
    }
}
