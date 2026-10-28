pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Local

Rectangle {
    id: root
    property bool spanish: Qt.locale().name.indexOf("es") === 0
    property string userName: "Linux"
    property string deviceName: "Omarchy PC"
    property int selectedCategory: 0
    property string filterText: ""
    signal closeRequested
    signal backRequested
    signal minimizeRequested
    signal maximizeRequested
    signal openRequested(string kind, string route)

    readonly property var categories: [
        { id: "system", title: t("System", "Sistema"), subtitle: t("Display, sound, input and shortcuts", "Pantalla, sonido, entrada y atajos"), icon: "\uf108", entries: [
            { title: t("Display", "Pantalla"), detail: t("Monitor layout and resolution", "Distribución y resolución de monitores"), route: "config.monitors", kind: "command", icon: "\uf108" },
            { title: t("Sound", "Sonido"), detail: t("Volume, output, input and app mixer", "Volumen, salida, entrada y mezcla de aplicaciones"), route: "omarchy.audio", kind: "panel", icon: "\uf028" },
            { title: t("Input", "Entrada"), detail: t("Keyboard, mouse and touchpad", "Teclado, ratón y panel táctil"), route: "config.input", kind: "command", icon: "\uf11c" },
            { title: t("Keyboard shortcuts", "Atajos de teclado"), detail: t("View and edit Omarchy shortcuts", "Consulta y edita los atajos de Omarchy"), route: "config.bindings", kind: "command", icon: "\uf11c" },
            { title: t("System configuration", "Configuración del sistema"), detail: t("Edit Hyprland settings", "Edita los ajustes de Hyprland"), route: "config.hyprland", kind: "command", icon: "\uf013" },
            { title: t("About", "Acerca de"), detail: t("Information about Omarchy and this computer", "Información sobre Omarchy y este equipo"), route: "about", kind: "command", icon: "\uf05a" }
        ] },
        { id: "devices", title: t("Bluetooth & devices", "Bluetooth y dispositivos"), subtitle: t("Connect Bluetooth devices and configure input", "Conecta dispositivos Bluetooth y configura la entrada"), icon: "\uf293", entries: [
            { title: t("Bluetooth", "Bluetooth"), detail: t("Connect or disconnect nearby devices", "Conecta o desconecta dispositivos cercanos"), route: "omarchy.bluetooth", kind: "panel", icon: "\uf293" },
            { title: t("Input", "Entrada"), detail: t("Keyboard, mouse and touchpad settings", "Ajustes de teclado, ratón y panel táctil"), route: "config.input", kind: "command", icon: "\uf11c" }
        ] },
        { id: "network", title: t("Network & internet", "Red e Internet"), subtitle: t("Wi-Fi connections and DNS options", "Conexiones Wi-Fi y opciones DNS"), icon: "\uf1eb", entries: [
            { title: t("Wi-Fi and network", "Wi-Fi y red"), detail: t("Connection status and available networks", "Estado de conexión y redes disponibles"), route: "omarchy.network", kind: "panel", icon: "\uf1eb" },
        ] },
        { id: "personalization", title: t("Personalization", "Personalización"), subtitle: t("Theme, background, fonts and desktop style", "Tema, fondo, fuentes y estilo del escritorio"), icon: "\uf1fc", entries: [
            { title: t("Theme", "Tema"), detail: t("Choose an installed Omarchy theme", "Elige un tema instalado de Omarchy"), route: "style.theme", kind: "command", icon: "\uf1fc" },
            { title: t("Background", "Fondo"), detail: t("Choose a background from the active theme", "Elige un fondo del tema activo"), route: "style.background", kind: "command", icon: "\uf03e" },
            { title: t("Bar configuration", "Configuración de la barra"), detail: t("Edit Omarchy shell and bar configuration", "Edita la configuración del shell y la barra Omarchy"), route: "style.bar", kind: "command", icon: "\uf0c9" },
            { title: t("Screensaver", "Salvapantallas"), detail: t("Edit screensaver text or image", "Edita el texto o imagen del salvapantallas"), route: "style.screensaver", kind: "command", icon: "\uf108" }
        ] },
        { id: "apps", title: t("Apps", "Aplicaciones"), subtitle: t("Installed apps and default choices", "Aplicaciones instaladas y opciones predeterminadas"), icon: "\uf00a", entries: [
            { title: t("Default terminal", "Terminal predeterminada"), detail: t("Edit the terminal preference used by Omarchy", "Edita la preferencia de terminal usada por Omarchy"), route: "apps.defaults", kind: "command", icon: "\uf00a" }
        ] },
        { id: "security", title: t("Security", "Seguridad"), subtitle: t("Security setup options available on this system", "Opciones de seguridad disponibles en este sistema"), icon: "\uf132", entries: [
            { title: t("SSH configuration", "Configuración de SSH"), detail: t("Edit per-user SSH client options", "Edita las opciones personales del cliente SSH"), route: "config.ssh", kind: "command", icon: "\uf132" }
        ] },
    ]
    readonly property var currentCategory: categories && categories.length
        ? categories[Math.min(selectedCategory, categories.length - 1)]
        : ({ id: "system", title: t("System", "Sistema"), subtitle: "", icon: "\uf108", entries: [] })
    readonly property var searchResults: {
        var query = filterText.toLowerCase()
        var matches = []
        if (query.length === 0) return matches
        for (var i = 0; i < categories.length; i++) {
            var category = categories[i]
            var categoryMatches = category.title.toLowerCase().indexOf(query) >= 0
            for (var j = 0; j < category.entries.length; j++) {
                var entry = category.entries[j]
                if (categoryMatches || entry.title.toLowerCase().indexOf(query) >= 0 || entry.detail.toLowerCase().indexOf(query) >= 0)
                    matches.push({ category: category.title, entry: Object.assign({}, entry, { searchCategory: category.title }) })
            }
        }
        return matches
    }
    readonly property var visibleEntries: filterText.length > 0
        ? searchResults.map(function (row) { return row.entry; })
        : currentCategory.entries
    readonly property var filteredCategories: (categories || []).filter(function (category) {
        if (root.filterText === "") return true
        var query = root.filterText.toLowerCase()
        if (category.title.toLowerCase().indexOf(query) >= 0) return true
        return category.entries.some(function (entry) {
            return entry.title.toLowerCase().indexOf(query) >= 0 || entry.detail.toLowerCase().indexOf(query) >= 0
        })
    })

    function t(en, es) { return spanish ? es : en; }

    function selectCategory(index) {
        if (index < 0 || index >= categories.length) return
        selectedCategory = index
        filterText = ""
    }

    implicitWidth: 1080
    implicitHeight: 840
    color: Local.Appearance.color("#f4f7fa")
    radius: 8
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 10

            ToolButton {
                text: "‹"
                font.pixelSize: 25
                implicitWidth: 34
                implicitHeight: 34
                onClicked: root.backRequested()
            }
            Text {
                text: root.t("Settings", "Configuración")
                font.pixelSize: 13
                color: Local.Appearance.color("#20252b")
                Layout.preferredWidth: 90
            }
            Item { Layout.fillWidth: true }
            TextField {
                id: search
                Layout.preferredWidth: 390
                Layout.preferredHeight: 34
                placeholderText: root.t("Find a setting", "Buscar un ajuste")
                leftPadding: 34
                font.pixelSize: 12
                color: Local.Appearance.color("#20252b")
                placeholderTextColor: Local.Appearance.color("#7b838b")
                background: Rectangle {
                    radius: height / 2
                    color: Local.Appearance.color("#f8fbfe")
                    border.color: search.activeFocus ? Local.Appearance.color("#cbd7e2") : Local.Appearance.color("#d4dce4")
                }
                onTextChanged: root.filterText = text.trim()
                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    source: Qt.resolvedUrl("../assets/fluent/" + (Local.Appearance.dark ? "dark/" : "") + "search.svg")
                }
            }
            Item { Layout.fillWidth: true }
            ToolButton {
                text: "—"
                font.pixelSize: 15
                implicitWidth: 34
                implicitHeight: 34
                onClicked: root.minimizeRequested()
            }
            ToolButton {
                text: "□"
                font.pixelSize: 15
                implicitWidth: 34
                implicitHeight: 34
                onClicked: root.maximizeRequested()
            }
            ToolButton {
                text: "×"
                font.pixelSize: 21
                implicitWidth: 34
                implicitHeight: 34
                onClicked: root.closeRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 246
                Layout.fillHeight: true
                color: Local.Appearance.color("#e9edf1")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 17
                    anchors.rightMargin: 17
                    anchors.topMargin: 7
                    anchors.bottomMargin: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 66
                        spacing: 11
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Local.Appearance.color("#d6eaff")
                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: Qt.resolvedUrl("../assets/fluent/" + (Local.Appearance.dark ? "dark/" : "") + "person.svg")
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text {
                                text: root.userName || "Linux"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Local.Appearance.color("#20252b")
                            }
                            Text {
                                text: "Omarchy Linux"
                                font.pixelSize: 10
                                color: Local.Appearance.color("#64696e")
                            }
                        }
                    }

                    ListView {
                        id: nav
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 3
                        model: root.filteredCategories
                        delegate: Button {
                            id: categoryDelegate
                            required property var modelData
                            required property int index
                            objectName: "SettingsCategory_" + modelData.id
                            width: nav.width
                            implicitHeight: 48
                            padding: 0
                            focusPolicy: Qt.TabFocus
                            Accessible.role: Accessible.ListItem
                            Accessible.name: modelData.title
                            onClicked: {
                                root.selectCategory(root.categories.indexOf(modelData))
                                search.text = ""
                            }
                            background: Rectangle {
                                radius: 5
                                color: root.categories.indexOf(categoryDelegate.modelData) === root.selectedCategory
                                    ? Local.Appearance.color("#d6eaff")
                                    : categoryDelegate.hovered ? Local.Appearance.color("#dde5ed") : "transparent"
                                border.width: categoryDelegate.activeFocus ? 1 : 0
                                border.color: Local.Appearance.color("#0078d4")
                            }
                            contentItem: RowLayout {
                                anchors.leftMargin: 11
                                anchors.rightMargin: 8
                                spacing: 10
                                Text {
                                    text: categoryDelegate.modelData.icon
                                    font.family: "omarchy"
                                    font.pixelSize: 16
                                    color: Local.Appearance.color("#0078d4")
                                    Layout.preferredWidth: 21
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: categoryDelegate.modelData.title
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Local.Appearance.color("#20252b")
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    Text {
                        text: root.t("Eleven settings · Omarchy", "Configuración Eleven · Omarchy")
                        font.pixelSize: 9
                        color: Local.Appearance.color("#7b838b")
                        Layout.leftMargin: 7
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Local.Appearance.color("#f4f7fa")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    anchors.topMargin: 22
                    anchors.bottomMargin: 20
                    spacing: 12

                    Text {
                        text: root.t("Settings", "Configuración") + "  ›  " + (root.filterText.length ? root.t("Search results", "Resultados") : root.currentCategory.title)
                        font.pixelSize: 10
                        color: Local.Appearance.color("#64696e")
                    }

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: root.filterText.length ? root.t("Search results", "Resultados") : root.currentCategory.title
                            font.pixelSize: 27
                            font.weight: Font.DemiBold
                            color: Local.Appearance.color("#20252b")
                        }
                        Text {
                            text: root.filterText.length
                                ? root.t("Matching options available on this system", "Opciones disponibles que coinciden con la búsqueda")
                                : root.currentCategory.subtitle
                            font.pixelSize: 11
                            color: Local.Appearance.color("#64696e")
                        }
                    }

                    Rectangle {
                        visible: root.filterText.length === 0 && root.currentCategory.id === "system"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        radius: 5
                        color: Local.Appearance.color("#ffffff")
                        border.color: Local.Appearance.color("#d9e0e8")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 17
                            Item {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 62
                                Rectangle {
                                    x: 7; y: 2; width: 58; height: 42
                                    radius: 4
                                    color: Local.Appearance.color("#d6eaff")
                                    border.color: Local.Appearance.color("#0078d4")
                                    Text {
                                        anchors.centerIn: parent
                                        text: "OM"
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                        color: Local.Appearance.color("#0078d4")
                                    }
                                }
                                Rectangle { x: 31; y: 45; width: 10; height: 8; color: Local.Appearance.color("#7b838b") }
                                Rectangle { x: 21; y: 52; width: 30; height: 3; radius: 2; color: Local.Appearance.color("#7b838b") }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text {
                                    text: root.deviceName || "Omarchy PC"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    color: Local.Appearance.color("#20252b")
                                }
                                Text {
                                    text: "Omarchy Linux  ·  Hyprland"
                                    font.pixelSize: 10
                                    color: Local.Appearance.color("#64696e")
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.filterText.length ? root.t("Results", "Resultados") : root.t("Related settings", "Ajustes relacionados")
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Local.Appearance.color("#20252b")
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: root.filterText.length > 0
                            text: String(root.visibleEntries.length)
                            font.pixelSize: 10
                            color: Local.Appearance.color("#64696e")
                        }
                    }

                    Flickable {
                        id: rows
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: cards.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        Column {
                            id: cards
                            width: rows.width
                            spacing: 4
                            Repeater {
                                model: root.visibleEntries
                                delegate: Button {
                                    id: settingDelegate
                                    required property var modelData
                                    objectName: "SettingsEntry_" + settingDelegate.modelData.route.replace(/[^A-Za-z0-9_]/g, "_")
                                    focusPolicy: Qt.TabFocus
                                    Accessible.role: Accessible.Button
                                    Accessible.name: settingDelegate.modelData.title + ". " + settingDelegate.modelData.detail
                                    width: cards.width
                                    implicitHeight: 64
                                    padding: 0
                                    onClicked: root.openRequested(settingDelegate.modelData.kind, settingDelegate.modelData.route)
                                    background: Rectangle {
                                        radius: 4
                                        color: settingDelegate.activeFocus || settingDelegate.hovered
                                            ? Local.Appearance.color("#e6edf6") : Local.Appearance.color("#ffffff")
                                        border.color: settingDelegate.activeFocus
                                            ? Local.Appearance.color("#0078d4") : Local.Appearance.color("#d9e0e8")
                                    }
                                    contentItem: RowLayout {
                                        anchors.leftMargin: 13
                                        anchors.rightMargin: 12
                                        spacing: 13
                                        Text {
                                            text: settingDelegate.modelData.icon
                                            font.family: "omarchy"
                                            font.pixelSize: 17
                                            color: Local.Appearance.color("#1b1b1b")
                                            Layout.preferredWidth: 24
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: settingDelegate.modelData.title
                                                font.pixelSize: 11
                                                color: Local.Appearance.color("#20252b")
                                            }
                                            Text {
                                                text: settingDelegate.modelData.searchCategory
                                                    ? settingDelegate.modelData.searchCategory + "  ·  " + settingDelegate.modelData.detail
                                                    : settingDelegate.modelData.detail
                                                font.pixelSize: 9
                                                color: Local.Appearance.color("#64696e")
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                        Text {
                                            text: "›"
                                            font.pixelSize: 20
                                            color: Local.Appearance.color("#64696e")
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: root.visibleEntries.length === 0
                                text: root.t("No matching settings", "No hay ajustes que coincidan")
                                font.pixelSize: 11
                                color: Local.Appearance.color("#64696e")
                                padding: 16
                            }
                        }
                    }
                }
            }
        }
    }
}
