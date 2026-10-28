import QtQuick
import QtQuick.Window
import QtTest
import "../../start"

TestCase {
    id: test
    name: "ElevenSettings"
    visible: true
    width: 900
    height: 680
    when: windowShown

    SettingsContent {
        id: settings
        anchors.fill: parent
    }

    SignalSpy {
        id: routeRequested
        target: settings
        signalName: "openRequested"
    }

    function test_categories_link_to_native_panels_and_commands() {
        compare(settings.categories.length, 6);
        var routes = [];
        settings.categories.forEach(function(category) {
            category.entries.forEach(function(entry) {
                routes.push(entry.route);
                verify(entry.kind === "command" || entry.kind === "panel");
            });
        });
        verify(routes.indexOf("config.monitors") >= 0);
        verify(routes.indexOf("config.input") >= 0);
        verify(routes.indexOf("config.bindings") >= 0);
        verify(routes.indexOf("style.theme") >= 0);
        verify(routes.indexOf("apps.defaults") >= 0);
        verify(routes.indexOf("config.ssh") >= 0);
        verify(routes.indexOf("config.hyprland") >= 0);
        verify(routes.indexOf("omarchy.audio") >= 0);
        verify(routes.indexOf("omarchy.bluetooth") >= 0);
        verify(routes.indexOf("omarchy.network") >= 0);
        verify(routes.indexOf("about") >= 0);
        verify(settings.categories.every(function(category) { return category.id !== "about"; }));
        verify(routes.indexOf("setup.network.dns") < 0);
        verify(routes.indexOf("setup.plugin") < 0);
    }

    function test_card_route_is_forwarded_without_running_a_system_command() {
        settings.openRequested("command", "config.input");
        compare(routeRequested.count, 1);
        compare(routeRequested.signalArguments[0][0], "command");
        compare(routeRequested.signalArguments[0][1], "config.input");
    }

    function test_category_selection_changes_page_and_exposes_its_native_actions() {
        settings.selectCategory(1);
        compare(settings.currentCategory.id, "devices");
        compare(settings.visibleEntries.length, 2);
        settings.openRequested(settings.visibleEntries[0].kind, settings.visibleEntries[0].route);
        compare(routeRequested.count, 2);
        compare(routeRequested.signalArguments[1][1], "omarchy.bluetooth");
    }

    function test_search_finds_settings_across_categories() {
        settings.filterText = "SSH";
        compare(settings.searchResults.length, 1);
        compare(settings.visibleEntries[0].route, "config.ssh");
        compare(settings.filteredCategories.length, 1);
        compare(settings.filteredCategories[0].id, "security");
        settings.filterText = "";
        settings.selectCategory(0);
        compare(settings.visibleEntries.length, 6);
    }

    function test_layout_and_mode_colors() {
        verify(settings.implicitWidth >= 800);
        verify(settings.implicitHeight >= 600);
        Session.mode = "dark";
        compare(settings.color, "#2b2b2b");
        Session.mode = "light";
        compare(settings.color, "#f4f7fa");
    }
}
