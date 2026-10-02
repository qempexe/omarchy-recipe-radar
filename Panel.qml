import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.qempexe.recipe-radar"
    ipcTarget: "io.github.qempexe.recipe-radar"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null

    // ── Theme (same tokens the first-party panels use) ──
    readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
    readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    readonly property color mutedText: Qt.darker(foreground, 1.5)

    // ── State ──
    property int activeTab: 0
    property bool detailOpen: false
    property var pantryItems: []
    property var favorites: []
    property var suggestions: []
    property var currentRecipe: null
    property bool isFetching: false
    property var allIngredients: []
    property var hints: []
    property int fetchToken: 0

    // ── Persistence ──
    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.config/recipe-radar.json"
        blockLoading: true
        printErrors: false
    }

    function loadStore() {
        try {
            var d = JSON.parse(store.text())
            pantryItems = d.pantry || []
            favorites = d.favorites || []
        } catch (e) {
            pantryItems = []
            favorites = []
        }
    }

    function saveStore() {
        try { store.setText(JSON.stringify({ pantry: pantryItems, favorites: favorites })) } catch (e) {}
    }

    // ── Lifecycle ──
    function open() {
        detailOpen = false
        root.controller.show()
        loadStore()
        if (allIngredients.length === 0) fetchIngredientList()
        fetchSuggestions()
    }

    function close() {
        root.controller.hide()
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.hostWidget || root, direction)
        return false
    }

    IpcHandler {
        target: root.ipcTarget
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.toggle() }
    }

    // ── Data ──
    function addIngredient(name) {
        var n = name.trim().toLowerCase()
        if (n && pantryItems.indexOf(n) === -1) {
            pantryItems = pantryItems.concat([n])
            saveStore()
        }
    }

    function removeIngredient(name) {
        pantryItems = pantryItems.filter(function(p) { return p !== name })
        saveStore()
    }

    function isFavorite(mealId) {
        for (var i = 0; i < favorites.length; i++)
            if (favorites[i].idMeal === mealId) return true
        return false
    }

    function toggleFavorite(meal) {
        if (isFavorite(meal.idMeal)) {
            favorites = favorites.filter(function(f) { return f.idMeal !== meal.idMeal })
        } else {
            favorites = favorites.concat([{ idMeal: meal.idMeal, strMeal: meal.strMeal, strMealThumb: meal.strMealThumb }])
        }
        saveStore()
    }

    function normalizeIngredient(raw) {
        var s = raw.trim().toLowerCase()
        var strip = ["fresh","chopped","diced","minced","sliced","ground","whole","large","small","medium","canned","frozen","dried","raw","cooked"]
        for (var i = 0; i < strip.length; i++)
            s = s.replace(new RegExp("\\b" + strip[i] + "\\b", "g"), "")
        return s.replace(/\s+/g, " ").trim().replace(/ /g, "_")
    }

    function getJson(url, cb) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var d = null
            if (xhr.status === 200) { try { d = JSON.parse(xhr.responseText) } catch (e) {} }
            cb(d)
        }
        xhr.send()
    }

    function fetchSuggestions() {
        var token = ++fetchToken
        if (pantryItems.length === 0) { suggestions = []; isFetching = false; return }
        isFetching = true
        var ingredients = pantryItems.slice(0, 3)
        var allResults = []
        var done = 0
        for (var i = 0; i < ingredients.length; i++) {
            var url = "https://www.themealdb.com/api/json/v1/1/filter.php?i=" + encodeURIComponent(normalizeIngredient(ingredients[i]))
            getJson(url, function(d) {
                if (token !== fetchToken) return
                if (d && d.meals) allResults.push(d.meals)
                done++
                if (done === ingredients.length) {
                    suggestions = intersect(allResults)
                    isFetching = false
                }
            })
        }
    }

    function intersect(sets) {
        if (sets.length === 0) return []
        if (sets.length === 1) return sets[0]
        var first = sets[0], result = []
        for (var i = 0; i < first.length; i++) {
            var id = first[i].idMeal, ok = true
            for (var j = 1; j < sets.length; j++) {
                var found = false
                for (var k = 0; k < sets[j].length; k++)
                    if (sets[j][k].idMeal === id) { found = true; break }
                if (!found) { ok = false; break }
            }
            if (ok) result.push(first[i])
        }
        if (result.length === 0) {
            var seen = {}
            for (var r = 0; r < sets.length; r++)
                for (var m = 0; m < sets[r].length; m++) {
                    var mid = sets[r][m].idMeal
                    if (!seen[mid]) { seen[mid] = true; result.push(sets[r][m]) }
                }
        }
        return result
    }

    function openRecipe(mealId) {
        currentRecipe = null
        detailOpen = true
        getJson("https://www.themealdb.com/api/json/v1/1/lookup.php?i=" + mealId, function(d) {
            if (d && d.meals && d.meals.length > 0) currentRecipe = d.meals[0]
        })
    }

    function fetchRandomRecipe() {
        currentRecipe = null
        detailOpen = true
        getJson("https://www.themealdb.com/api/json/v1/1/random.php", function(d) {
            if (d && d.meals && d.meals.length > 0) currentRecipe = d.meals[0]
        })
    }

    function fetchIngredientList() {
        getJson("https://www.themealdb.com/api/json/v1/1/list.php?i=list", function(d) {
            if (!d || !d.meals) return
            var names = []
            for (var i = 0; i < d.meals.length; i++) names.push(d.meals[i].strIngredient)
            allIngredients = names
        })
    }

    function searchIngredients(query) {
        if (!query || query.length < 2) return []
        var q = query.toLowerCase(), r = []
        for (var i = 0; i < allIngredients.length && r.length < 6; i++)
            if (allIngredients[i].toLowerCase().indexOf(q) !== -1) r.push(allIngredients[i])
        return r
    }

    function addFromInput(name) {
        addIngredient(name)
        ingredientInput.text = ""
        hints = []
        fetchSuggestions()
    }

    // ══════════════════════════════════════════════════════════
    // UI
    // ══════════════════════════════════════════════════════════

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(420))
        contentHeight: panel.fittedContentHeight(Style.space(560))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            blocked: ingredientInput.activeFocus
            onCloseRequested: {
                if (root.detailOpen) root.detailOpen = false
                else root.close()
            }
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Item {
                id: page
                anchors.fill: parent
                anchors.margins: Style.space(16)

                // ── Header ──
                Item {
                    id: header
                    width: parent.width
                    height: Style.space(44)

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(2)
                        Text {
                            text: "Recipe Radar"
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.title
                        }
                        SectionLabel {
                            text: root.pantryItems.length + " in pantry · " + root.favorites.length + " saved"
                            fg: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                        }
                    }

                    RRButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "🎲 RANDOM"
                        fg: root.foreground
                        fontFamily: root.fontFamily
                        onClicked: root.fetchRandomRecipe()
                    }
                }

                // ── Tabs (segmented, like the DNS provider buttons) ──
                Row {
                    id: tabs
                    visible: !root.detailOpen
                    anchors.top: header.bottom
                    anchors.topMargin: Style.space(12)
                    width: parent.width
                    spacing: Style.space(6)

                    RRButton {
                        width: (parent.width - Style.space(6)) / 2
                        label: "PANTRY"
                        active: root.activeTab === 0
                        fg: root.foreground
                        fontFamily: root.fontFamily
                        onClicked: root.activeTab = 0
                    }
                    RRButton {
                        width: (parent.width - Style.space(6)) / 2
                        label: "FAVORITES"
                        active: root.activeTab === 1
                        fg: root.foreground
                        fontFamily: root.fontFamily
                        onClicked: root.activeTab = 1
                    }
                }

                // ── Body area ──
                Item {
                    id: body
                    anchors.top: root.detailOpen ? header.bottom : tabs.bottom
                    anchors.topMargin: Style.space(14)
                    anchors.bottom: parent.bottom
                    width: parent.width

                    // PANTRY TAB
                    Flickable {
                        id: pantryView
                        anchors.fill: parent
                        visible: !root.detailOpen && root.activeTab === 0
                        contentWidth: width
                        contentHeight: pantryCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: pantryCol
                            width: pantryView.width
                            spacing: Style.space(12)

                            TextField {
                                id: ingredientInput
                                width: parent.width
                                placeholderText: "Add ingredient…"
                                foreground: root.foreground
                                font.family: root.fontFamily
                                onTextChanged: root.hints = root.searchIngredients(text)
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.hints.length > 0) root.addFromInput(root.hints[0])
                                        else if (text.trim() !== "") root.addFromInput(text)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        if (text !== "") text = ""
                                        else keyCatcher.forceActiveFocus()
                                        event.accepted = true
                                    }
                                }
                            }

                            // Autocomplete hints
                            Column {
                                visible: root.hints.length > 0
                                width: parent.width
                                spacing: Style.space(2)
                                Repeater {
                                    model: root.hints
                                    Rectangle {
                                        width: parent.width
                                        height: Style.space(28)
                                        radius: Style.cornerRadius
                                        color: hintHover.hovered ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"
                                        HoverHandler { id: hintHover }
                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: Style.space(10)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.bodySmall
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addFromInput(modelData)
                                        }
                                    }
                                }
                            }

                            SectionLabel {
                                text: "Your pantry"
                                fg: root.foreground
                                font.family: root.fontFamily
                            }

                            Text {
                                visible: root.pantryItems.length === 0
                                text: "Nothing yet. Add what you have at home."
                                color: root.mutedText
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.italic: true
                            }

                            Flow {
                                width: parent.width
                                spacing: Style.space(6)
                                Repeater {
                                    model: root.pantryItems
                                    Rectangle {
                                        width: chipRow.width + Style.space(20)
                                        height: Style.space(28)
                                        radius: Math.min(6, Style.cornerRadius)
                                        color: chipHover.hovered ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"
                                        border.width: 1
                                        border.color: Qt.darker(root.foreground, 2.2)
                                        HoverHandler { id: chipHover }
                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: Style.space(6)
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData
                                                color: root.foreground
                                                font.family: root.fontFamily
                                                font.pixelSize: Style.font.bodySmall
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "✕"
                                                color: Qt.darker(root.foreground, 1.6)
                                                font.family: root.fontFamily
                                                font.pixelSize: Style.font.caption
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.removeIngredient(modelData)
                                                root.fetchSuggestions()
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: Style.spacing.hairline; color: root.foreground; opacity: 0.12 }

                            Item {
                                width: parent.width
                                height: Style.space(24)
                                SectionLabel {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Suggestions"
                                    fg: root.foreground
                                    font.family: root.fontFamily
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.isFetching ? "FETCHING…" : "↻ REFRESH"
                                    color: root.isFetching ? root.mutedText : Color.accent
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    font.letterSpacing: 1
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        enabled: !root.isFetching
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.fetchSuggestions()
                                    }
                                }
                            }

                            Text {
                                visible: !root.isFetching && root.suggestions.length === 0
                                text: root.pantryItems.length === 0 ? "Add an ingredient to get suggestions." : "No recipes found for these ingredients."
                                color: root.mutedText
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.italic: true
                            }

                            Column {
                                width: parent.width
                                spacing: Style.space(4)
                                Repeater {
                                    model: root.suggestions
                                    RecipeRow {
                                        width: parent.width
                                        meal: modelData
                                        fg: root.foreground
                                        fontFamily: root.fontFamily
                                        starred: root.isFavorite(modelData.idMeal)
                                        onOpened: root.openRecipe(modelData.idMeal)
                                        onStarToggled: root.toggleFavorite(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // FAVORITES TAB
                    Flickable {
                        id: favView
                        anchors.fill: parent
                        visible: !root.detailOpen && root.activeTab === 1
                        contentWidth: width
                        contentHeight: favCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: favCol
                            width: favView.width
                            spacing: Style.space(8)

                            SectionLabel {
                                text: "Saved recipes"
                                fg: root.foreground
                                font.family: root.fontFamily
                            }

                            Text {
                                visible: root.favorites.length === 0
                                text: "No favorites yet. Tap ☆ on any suggestion to save it."
                                wrapMode: Text.WordWrap
                                width: parent.width
                                color: root.mutedText
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.italic: true
                            }

                            Column {
                                width: parent.width
                                spacing: Style.space(4)
                                Repeater {
                                    model: root.favorites
                                    RecipeRow {
                                        width: parent.width
                                        meal: modelData
                                        fg: root.foreground
                                        fontFamily: root.fontFamily
                                        starred: true
                                        onOpened: root.openRecipe(modelData.idMeal)
                                        onStarToggled: root.toggleFavorite(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // DETAIL VIEW
                    RecipeDetail {
                        anchors.fill: parent
                        visible: root.detailOpen
                        recipe: root.currentRecipe
                        pantryItems: root.pantryItems
                        favorites: root.favorites
                        fg: root.foreground
                        fontFamily: root.fontFamily
                        onBackRequested: root.detailOpen = false
                        onFavoriteToggled: function(meal) { root.toggleFavorite(meal) }
                        onRandomRequested: root.fetchRandomRecipe()
                    }
                }
            }
        }
    }
}
