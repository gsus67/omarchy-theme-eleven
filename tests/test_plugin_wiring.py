"""Regression checks for per-monitor widget routing and singleton UI state."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PluginWiringTest(unittest.TestCase):
    def test_start_is_routed_by_the_native_bar_widget_api(self):
        manifest = json.loads((ROOT / "manifest.json").read_text())
        self.assertEqual(manifest["kinds"], ["bar-widget", "service"])
        self.assertEqual(set(manifest["entryPoints"]), {"barWidget", "service"})
        start = (ROOT / "start/Start.qml").read_text()
        lifecycle = (ROOT / "Lifecycle.qml").read_text()
        self.assertNotIn("IpcHandler", start)
        self.assertEqual(lifecycle.count("IpcHandler {"), 1)
        self.assertIn('target: "eleven-start"', lifecycle)
        self.assertIn("shell.summon(root.pluginId", lifecycle)

    def test_settings_window_and_return_target_have_single_service_owner(self):
        manifest = json.loads((ROOT / "manifest.json").read_text())
        self.assertNotIn("panel", manifest["kinds"])
        self.assertNotIn("menu", manifest["kinds"])
        lifecycle = (ROOT / "Lifecycle.qml").read_text()
        settings = (ROOT / "start/SettingsWindow.qml").read_text()
        self.assertIn("StartUI.SettingsWindow", lifecycle)
        self.assertIn("Session.returnStart = start", lifecycle)
        self.assertIn("returnTimer", settings)
        self.assertNotIn('"omarchy-shell", "eleven-start", "open"', settings)


if __name__ == "__main__":
    unittest.main()
