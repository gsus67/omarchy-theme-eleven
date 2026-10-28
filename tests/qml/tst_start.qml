import QtQuick
import QtQuick.Window
import QtTest
import "../../start"

TestCase {
    id: test
    name: "ElevenStart"
    visible: true
    width: 640
    height: 726
    Component.onCompleted: { test.Window.window.width = 640; test.Window.window.height = 726; }
    when: windowShown

    QtObject {
        id: library
        property var entries: [
            {id: "chromium", name: "Browser", icon: ""},
            {id: "org.gnome.Nautilus", name: "Files", icon: ""},
            {id: "org.gnome.Calculator", name: "Calculator", icon: ""}
        ]
        function sortedEntries(query) {
            return entries.filter(function(entry) {
                return entry.name.toLowerCase().indexOf(query.toLowerCase()) >= 0;
            }).map(function(entry) { return {entry: entry, score: 0}; });
        }
        function entryName(entry) { return entry.name; }
        function iconSource(icon) { return ""; }
    }
    StartContent {
        id: menu
        anchors.fill: parent
        library: library
        inheritedPins: ["chromium", "missing-app"]
        userName: "Test"
    }
    SignalSpy { id: launched; target: menu; signalName: "launchRequested" }
    SignalSpy { id: closed; target: menu; signalName: "closeRequested" }
    SignalSpy { id: pins; target: menu; signalName: "pinsRequested" }
    SignalSpy { id: powerClicks; signalName: "clicked" }
    SignalSpy { id: systemAction; target: menu; signalName: "systemActionRequested" }

    function init() {
        test.width = 640;
        menu.requestedPins = null;
        menu.reset();
        launched.clear();
        closed.clear();
        pins.clear();
        systemAction.clear();
        powerClicks.target = findChild(menu, "startPowerButton"); powerClicks.clear();
        menu.suspendAvailable = false;
        menu.hibernateAvailable = false;
        wait(1);
    }
    function cleanup() { findChild(menu, "startPowerMenu").close(); }
    function typeText(value) {
        for (var i = 0; i < value.length; i++) keyClick(value.charAt(i));
    }
    function test_mode_switch_updates_existing_start_without_recreating_it() {
        Session.mode = "dark";
        compare(menu.color, "#242424");
        compare(Appearance.color("#20252b"), "#f3f3f3");
        verify(menu.symbol("power").toString().indexOf("/dark/power.svg") >= 0);
        var entries = menu.allEntries.length;
        Session.mode = "light";
        compare(menu.color, "#e9edf1");
        compare(menu.allEntries.length, entries);
    }
    function test_inherited_pins_do_not_include_missing_apps() {
        compare(menu.pinnedApps[0].id, "chromium");
        compare(menu.pinnedApps.length, 3);
    }
    function test_search_and_enter_launch_the_matching_desktop_entry() {
        var search = findChild(menu, "startSearch");
        typeText("Calc");
        compare(search.text, "Calc");
        compare(menu.visibleEntries.length, 1);
        compare(menu.visibleEntries[0].id, "org.gnome.Calculator");
        keyClick(Qt.Key_Return);
        compare(launched.count, 1);
        compare(launched.signalArguments[0][0].id, "org.gnome.Calculator");
    }
    function test_escape_clears_search_then_leaves_all_apps_then_closes() {
        menu.allApps = true;
        typeText("Browser");
        keyClick(Qt.Key_Escape);
        compare(menu.query, "");
        compare(menu.allApps, true);
        keyClick(Qt.Key_Escape);
        compare(menu.allApps, false);
        keyClick(Qt.Key_Escape);
        compare(closed.count, 1);
    }
    function test_keyboard_selection_and_activation() {
        menu.requestedPins = ["chromium", "org.gnome.Nautilus"];
        keyClick(Qt.Key_Down);
        var grid = findChild(menu, "startApps");
        compare(grid.currentIndex, 0);
        keyClick(Qt.Key_Right);
        compare(grid.currentIndex, 1);
        keyClick(Qt.Key_Return);
        compare(launched.count, 1);
        compare(launched.signalArguments[0][0].id, "org.gnome.Nautilus");
    }
    function test_explicit_empty_pins_stay_empty() {
        menu.requestedPins = [];
        compare(menu.pinnedApps.length, 0);
        menu.activateCurrent();
        compare(launched.count, 0);
    }
    function test_narrow_screen_reduces_grid_columns() {
        test.width = 360;
        compare(menu.columns, 3);
        test.width = 640;
        compare(menu.columns, 6);
    }
    function test_category_navigation_filters_and_escape_returns_home() {
        menu.openCategory("utilities");
        compare(menu.allApps, true);
        compare(menu.visibleEntries.length, 3);
        keyClick(Qt.Key_Escape);
        compare(menu.allApps, false);
        compare(menu.activeCategory, "");
    }
    function test_power_menu_opens_without_closing_start_or_executing_actions() {
        mouseClick(findChild(menu, "startPowerButton"));
        var popup = findChild(menu, "startPowerMenu");
        tryCompare(popup, "opened", true);
        compare(popup.count, 5);
        compare(systemAction.count, 0);
        compare(closed.count, 0);
        menu.suspendAvailable = true;
        menu.hibernateAvailable = true;
        compare(popup.count, 7);
        waitForRendering(popup.contentItem);
        mouseClick(popup.itemAt(1));
        compare(systemAction.count, 1);
        compare(systemAction.signalArguments[0][0], "lock");
    }
    function test_escape_closes_power_flyout_before_start() {
        mouseClick(findChild(menu, "startPowerButton"));
        var popup = findChild(menu, "startPowerMenu");
        tryCompare(popup, "opened", true);
        keyClick(Qt.Key_Escape);
        tryCompare(popup, "opened", false);
        compare(closed.count, 0);
    }
    function test_power_hover_shows_a_label_without_executing_an_action() {
        var button = findChild(menu, "startPowerButton");
        mouseMove(button, 20, 20);
        var tooltip = findChild(menu, "startPowerTooltip");
        tryCompare(tooltip, "visible", true);
        compare(tooltip.text, menu.spanish ? "Encendido" : "Power");
        compare(systemAction.count, 0);
        mouseMove(findChild(menu, "startSearch"), 20, 20);
        tryCompare(tooltip, "visible", false);
    }
}
