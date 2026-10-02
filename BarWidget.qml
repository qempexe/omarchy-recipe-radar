import QtQuick
import Quickshell
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.qempexe.recipe-radar"

    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

    function open() { if (panelLoader.item) panelLoader.item.open() }
    function close() { if (panelLoader.item) panelLoader.item.close() }
    function toggle() { if (panelLoader.item) panelLoader.item.toggle() }

    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
    }

    // Use the button's natural size so the icon matches its neighbours;
    // only fall back to a small default if it reports 0 (so it never vanishes).
    implicitWidth: button.implicitWidth > 0 ? button.implicitWidth : 24
    implicitHeight: button.implicitHeight > 0 ? button.implicitHeight : 24

    onBarChanged: injectPanel()
    Component.onCompleted: Qt.callLater(injectPanel)

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰩰" // nf-md-silverware_fork_knife (U+F0A70); alt: "\uDB82\uDE70"
        tooltipText: "Recipe Radar"
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton)
                root.toggle()
        }
    }
}
