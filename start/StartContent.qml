import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "StartModel.js" as Model

Rectangle {
    id: root
    property var library: null
    property var requestedPins: null
    property var inheritedPins: []
    property string userName: ""
    property bool spanish: Qt.locale().name.indexOf("es") === 0
    property bool allApps: false
    property bool suspendAvailable: false
    property bool hibernateAvailable: false
    property string activeCategory: ""
    property var allEntries: []
    property var searchEntries: []
    property var contextEntry: null
    readonly property string query: search.text.trim()
    readonly property var effectivePins: Array.isArray(requestedPins) ? Model.validIds(requestedPins) : Model.defaultPins(allEntries, inheritedPins)
    readonly property var pinnedApps: Model.pinnedEntries(allEntries, effectivePins)
    readonly property var groups: Model.categories(allEntries)
    readonly property bool listMode: allApps || query.length > 0
    readonly property var visibleEntries: listMode ? searchEntries : pinnedApps
    readonly property int columns: width >= 540 ? 6 : width >= 390 ? 4 : 3
    readonly property int categoryColumns: width >= 500 ? 3 : 2
    readonly property int sectionInset: width >= 500 ? 64 : 28
    signal launchRequested(var entry)
    signal pinsRequested(var ids)
    signal placeRequested(string place)
    signal settingsRequested
    signal systemActionRequested(string action)
    signal closeRequested

    implicitWidth: 640
    implicitHeight: 726
    radius: 8
    color: Appearance.color("#e9edf1")
    border.color: Appearance.color("#c1c8cf")
    clip: true
    onActiveFocusChanged: if (activeFocus)
        search.forceActiveFocus()

    function t(en, es) {
        return spanish ? es : en;
    }
    function showPowerMenu() {
        powerMenu.open();
    }
    function symbol(name) {
        if (name === "folder") return library ? library.iconSource("folder") : Qt.resolvedUrl("../assets/fluent/folder.svg");
        return Qt.resolvedUrl("../assets/fluent/" + (Appearance.dark ? "dark/" : "") + name + ".svg");
    }
    function catalog(text) {
        var entries = library ? library.sortedEntries(text).map(function (row) {
            return row.entry;
        }) : [];
        return activeCategory === "" ? entries : entries.filter(function (entry) {
            return Model.categoryId(entry) === root.activeCategory;
        });
    }
    function refresh() {
        allEntries = library ? library.sortedEntries("").map(function (row) {
            return row.entry;
        }) : [];
        searchEntries = catalog(query);
        apps.currentIndex = -1;
    }
    function reset() {
        allApps = false;
        activeCategory = "";
        search.text = "";
        refresh();
        body.contentY = 0;
        search.forceActiveFocus();
    }
    function iconFor(entry) {
        var id = String(entry.id || "").replace(/\.desktop$/, "");
        if (id === "org.gnome.Nautilus") return symbol("folder");
        return library ? library.iconSource(entry.icon || "") : "";
    }
    function nameFor(entry) {
        return library ? library.entryName(entry) : String(entry.name || entry.id || "");
    }
    function openCategory(id) {
        activeCategory = id;
        allApps = true;
        body.contentY = 0;
        search.forceActiveFocus();
    }
    function back() {
        activeCategory = "";
        allApps = false;
        body.contentY = 0;
    }
    function moveSelection(dx, dy) {
        apps.currentIndex = Model.movedIndex(apps.currentIndex, dx, dy, listMode ? 1 : columns, visibleEntries.length);
        if (apps.currentIndex >= 0)
            apps.positionViewAtIndex(apps.currentIndex, GridView.Contain);
    }
    function activateCurrent() {
        var at = apps.currentIndex >= 0 ? apps.currentIndex : 0;
        if (visibleEntries[at])
            launchRequested(visibleEntries[at]);
    }
    onLibraryChanged: refresh()
    onActiveCategoryChanged: searchEntries = catalog(query)
    onQueryChanged: {
        searchEntries = catalog(query);
        apps.currentIndex = -1;
    }
    onAllAppsChanged: apps.currentIndex = -1
    Connections {
        target: root.library
        ignoreUnknownSignals: true
        function onAppsChanged() {
            root.refresh();
        }
    }
    Keys.onEscapePressed: {
        if (search.text !== "")
            search.text = "";
        else if (root.allApps)
            root.back();
        else
            root.closeRequested();
    }

    TextField {
        id: search
        objectName: "startSearch"
        anchors.top: parent.top
        anchors.topMargin: 17
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        height: 32
        placeholderText: root.t("Search for apps", "Buscar aplicaciones")
        font.family: "sans-serif"
        font.pixelSize: 13
        color: Appearance.color("#20252b")
        placeholderTextColor: Appearance.color("#7b838b")
        leftPadding: 43
        rightPadding: 16
        selectByMouse: true
        background: Rectangle {
            color: Appearance.color("#f8fbfe")
            radius: height / 2
            border.color: search.activeFocus ? Appearance.color("#cbd7e2") : Appearance.color("#d4dce4")
            Image {
                anchors.left: parent.left
                anchors.leftMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                width: 19
                height: 19
                source: root.symbol("search")
                sourceSize.width: 24
                sourceSize.height: 24
            }
        }
        Keys.onDownPressed: {
            apps.currentIndex = root.visibleEntries.length > 0 ? 0 : -1;
            apps.forceActiveFocus();
        }
        Keys.onReturnPressed: root.activateCurrent()
        Keys.onEnterPressed: root.activateCurrent()
    }

    Flickable {
        id: body
        anchors.top: search.bottom
        anchors.topMargin: 36
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 4
        contentWidth: width
        contentHeight: sections.height
        clip: true
        interactive: !root.listMode
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: sections
            width: body.width
            spacing: 0

            RowLayout {
                x: root.sectionInset
                width: parent.width - x * 2
                height: 44
                Text {
                    Layout.fillWidth: true
                    text: root.query.length > 0 ? root.t("Search results", "Resultados") : root.allApps ? root.t("All", "Todas") : root.t("Pinned", "Anclado")
                    textFormat: Text.PlainText
                    font.family: "sans-serif"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Appearance.color("#20252b")
                }
                ElevenButton {
                    visible: root.listMode
                    text: root.t("Back", "Atrás")
                    subtle: true
                    onClicked: {
                        search.text = "";
                        root.back();
                        search.forceActiveFocus();
                    }
                }
            }

            GridView {
                id: apps
                objectName: "startApps"
                x: 32
                width: parent.width - 64
                height: root.listMode ? Math.max(100, body.height - 44) : Math.min(3, Math.max(1, Math.ceil(root.pinnedApps.length / root.columns))) * 88
                clip: true
                cellWidth: root.listMode ? width : width / root.columns
                cellHeight: root.listMode ? 52 : 88
                model: root.visibleEntries
                currentIndex: -1
                keyNavigationEnabled: false
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                Keys.onLeftPressed: root.moveSelection(-1, 0)
                Keys.onRightPressed: root.moveSelection(1, 0)
                Keys.onUpPressed: {
                    if (currentIndex < (root.listMode ? 1 : root.columns))
                        search.forceActiveFocus();
                    else
                        root.moveSelection(0, -1);
                }
                Keys.onDownPressed: root.moveSelection(0, 1)
                Keys.onReturnPressed: root.activateCurrent()
                Keys.onEnterPressed: root.activateCurrent()
                Keys.onSpacePressed: root.activateCurrent()
                Keys.onPressed: function (event) {
                    if (event.text.length > 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                        search.text += event.text;
                        search.forceActiveFocus();
                        event.accepted = true;
                    }
                }
                delegate: AppTile {
                    id: pinnedTile
                    required property var modelData
                    required property int index
                    width: apps.cellWidth - 2
                    height: apps.cellHeight - 2
                    wide: root.listMode
                    text: root.nameFor(modelData)
                    iconSource: root.iconFor(modelData)
                    selected: apps.currentIndex === index
                    keyboardSelected: apps.activeFocus && selected
                    onClicked: root.launchRequested(modelData)
                    onContextRequested: {
                        root.contextEntry = modelData;
                        pinMenu.popup();
                    }
                    ToolTip.visible: hovered && !tooltipDelay.running
                    ToolTip.text: text
                    Timer {
                        id: tooltipDelay
                        interval: 650
                        running: pinnedTile.hovered
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 30
                    visible: root.visibleEntries.length === 0
                    text: root.query.length > 0 ? root.t("No applications found", "No se encontraron aplicaciones") : root.t("Pin apps from the All section below.", "Ancla aplicaciones desde la sección Todas.")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "sans-serif"
                    font.pixelSize: 12
                    color: Appearance.color("#64696e")
                }
            }

            Item {
                visible: !root.listMode
                width: 1
                height: 24
            }
            Text {
                visible: !root.listMode
                x: root.sectionInset
                height: 32
                text: root.t("Recommended", "Recomendaciones")
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
                font.family: "sans-serif"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Appearance.color("#20252b")
            }
            GridLayout {
                visible: !root.listMode
                x: root.sectionInset - 10
                width: parent.width - x * 2
                columns: 2
                columnSpacing: 16
                rowSpacing: 0
                RecommendationTile {
                    Layout.fillWidth: true
                    text: root.t("Documents", "Documentos")
                    detail: root.t("Open folder", "Abrir carpeta")
                    iconSource: root.symbol("document")
                    onClicked: root.placeRequested("documents")
                }
                RecommendationTile {
                    Layout.fillWidth: true
                    text: root.t("Downloads", "Descargas")
                    detail: root.t("Open folder", "Abrir carpeta")
                    iconSource: root.symbol("download")
                    onClicked: root.placeRequested("downloads")
                }
                RecommendationTile {
                    Layout.fillWidth: true
                    text: root.t("Files", "Archivos")
                    detail: root.t("Explore your computer", "Explorar el equipo")
                    iconSource: root.symbol("folder")
                    onClicked: root.placeRequested("home")
                }
                RecommendationTile {
                    Layout.fillWidth: true
                    text: root.t("Settings", "Configuración")
                    detail: root.t("Personalize Omarchy", "Personalizar Omarchy")
                    iconSource: root.symbol("settings")
                    blueCenter: true
                    onClicked: root.settingsRequested()
                }
            }
            Item {
                visible: !root.listMode
                width: 1
                height: 48
            }
            RowLayout {
                visible: !root.listMode
                x: root.sectionInset
                width: parent.width - x * 2
                height: 40
                Text {
                    Layout.fillWidth: true
                    text: root.t("All", "Todas")
                    textFormat: Text.PlainText
                    font.family: "sans-serif"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Appearance.color("#20252b")
                }
                ElevenButton {
                    text: root.t("View: Category", "Vista: Categoría")
                    subtle: true
                    rightPadding: 24
                    onClicked: viewMenu.popup()
                    Image {
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        source: root.symbol("chevron-down")
                    }
                }
            }
            GridLayout {
                visible: !root.listMode
                x: root.sectionInset
                width: parent.width - x * 2
                columns: root.categoryColumns
                columnSpacing: 18
                rowSpacing: 8
                Repeater {
                    model: root.groups
                    CategoryTile {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: (sections.width - root.sectionInset * 2 - 18 * (root.categoryColumns - 1)) / root.categoryColumns
                        Layout.preferredHeight: width + 28
                        group: modelData
                        library: root.library
                        text: root.spanish ? modelData.nameEs : modelData.name
                        onClicked: root.openCategory(modelData.id)
                    }
                }
            }
            Item {
                visible: !root.listMode
                width: 1
                height: 8
            }
        }
    }

    Rectangle {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 1
        height: 64
        color: Appearance.color("#e4e8ed")
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Appearance.color("#d5dce3")
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.sectionInset
            anchors.rightMargin: root.sectionInset - 12
            ElevenButton {
                subtle: true
                text: root.userName || root.t("Home", "Inicio")
                implicitWidth: 150
                implicitHeight: 40
                onClicked: root.placeRequested("home")
                contentItem: Row {
                    spacing: 12
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: Appearance.color("#f7f9fb")
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: root.symbol("person")
                        }
                    }
                    Text {
                        text: root.userName || root.t("Home", "Inicio")
                        textFormat: Text.PlainText
                        font.family: "sans-serif"
                        font.pixelSize: 12
                        color: Appearance.color("#20252b")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ElevenButton {
                id: powerButton
                subtle: true
                text: root.t("Power options", "Opciones de energía")
                objectName: "startPowerButton"
                implicitWidth: 40
                implicitHeight: 40
                onClicked: powerMenu.opened ? powerMenu.close() : powerMenu.open()
                contentItem: Image {
                    source: root.symbol("power")
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                }
                leftPadding: 10
                rightPadding: 10
                topPadding: 10
                bottomPadding: 10
                background: Rectangle {
                    radius: 4
                    color: powerButton.down ? Appearance.color("#dde5ed") : powerButton.hovered ? Appearance.color("#eef2f6") : "transparent"
                    border.color: powerButton.activeFocus ? Appearance.color("#0078d4") : "transparent"
                }
                ToolTip {
                    id: powerTip
                    objectName: "startPowerTooltip"
                    parent: powerButton
                    visible: powerButton.hovered && !powerMenu.opened
                    delay: 650
                    text: root.t("Power", "Encendido")
                    x: (powerButton.width - width) / 2
                    y: -height - 6
                    padding: 8
                    background: Rectangle {
                        radius: 4
                        color: Appearance.color("#f4f7fa")
                        border.color: Appearance.color("#d1d8df")
                    }
                    contentItem: Text {
                        text: powerTip.text
                        textFormat: Text.PlainText
                        color: Appearance.color("#20252b")
                        font.family: "sans-serif"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Menu {
        id: powerMenu
        objectName: "startPowerMenu"
        parent: root
        width: 170
        x: root.width - width - 8
        y: footer.y - height + 8
        padding: 4
        background: Rectangle {
            radius: 8
            color: Appearance.color("#f4f7fa")
            border.color: Appearance.color("#d1d8df")
        }
        Repeater {
            model: Model.powerOptions(root.suspendAvailable, root.hibernateAvailable)
            MenuItem {
                id: powerItem
                required property var modelData
                width: powerMenu.width - 8
                height: 32
                text: root.spanish ? modelData.nameEs : modelData.name
                onTriggered: root.systemActionRequested(modelData.id)
                background: Rectangle {
                    radius: 4
                    color: powerItem.highlighted ? Appearance.color("#e5ebf2") : "transparent"
                }
                contentItem: RowLayout {
                    spacing: 10
                    Image {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: root.symbol(powerItem.modelData.icon)
                        sourceSize.width: 24
                        sourceSize.height: 24
                    }
                    Text {
                        Layout.fillWidth: true
                        text: powerItem.text
                        textFormat: Text.PlainText
                        font.family: "sans-serif"
                        font.pixelSize: 13
                        color: Appearance.color("#20252b")
                    }
                }
            }
        }
    }
    Menu {
        id: viewMenu
        MenuItem {
            text: root.t("All apps as a list", "Todas las aplicaciones en lista")
            onTriggered: root.openCategory("")
        }
    }
    Menu {
        id: pinMenu
        MenuItem {
            text: root.contextEntry && root.effectivePins.indexOf(root.contextEntry.id) >= 0 ? root.t("Unpin from Start", "Desanclar de Inicio") : root.t("Pin to Start", "Anclar a Inicio")
            onTriggered: if (root.contextEntry)
                root.pinsRequested(Model.togglePin(root.effectivePins, root.contextEntry.id))
        }
    }
}
