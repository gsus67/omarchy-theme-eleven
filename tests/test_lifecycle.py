"""Exercise enable/disable/uninstall and interruptions in an isolated tree."""
import copy
import importlib.util
import json
import shutil
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("eleven_lifecycle", ROOT / "scripts/lifecycle.py")
life = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(life)


class FakeNative:
    def __init__(self):
        self.selected = "tokyo-night"
        self.image = "/wallpapers/original.png"
        self.settings = {"color-scheme": "'prefer-dark'", "gtk-theme": "'Adwaita-dark'", "icon-theme": "'Yaru-red'"}
        self.calls = []
        self.fail = False
        self.unset = set()

    def theme(self):
        return self.selected

    def apply_theme(self, name):
        self.calls.append(name)
        self.selected = name
        if self.fail:
            self.fail = False
            raise RuntimeError("Interrupted after staging")

    def get(self, key):
        return self.settings[key]

    def set(self, key, value):
        self.settings[key] = value

    def user_value(self, key):
        return "" if key in self.unset else self.settings[key]

    def reset(self, key):
        self.settings[key] = {"color-scheme": "'default'", "gtk-theme": "'Adwaita'", "icon-theme": "'Adwaita'"}[key]

    def install_shortcuts(self, source):
        return {"installed": [], "skipped": []}

    def remove_shortcuts(self):
        pass

    def background(self):
        return self.image

    def set_background(self, path):
        self.image = path


class LifecycleTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="eleven-lifecycle-")
        self.addCleanup(self.directory.cleanup)
        self.paths = life.Paths(Path(self.directory.name))
        self.source = Path(self.directory.name) / "plugin"
        self.source.mkdir()
        for name in life.ASSETS:
            target = self.source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        shutil.copytree(ROOT / "variants", self.source / "variants")
        self.original = {"version": 1, "bar": {"position": "top", "transparent": True, "layout": {
            "left": [{"id": "omarchy.menu", "custom": "keep"}, {"id": "omarchy.workspaces"}],
            "center": [{"id": "omarchy.clock"}], "right": [{"id": "tool", "keep": 1}]}},
            "plugins": [{"id": "taskbar", "width": "60%"}], "other": {"keep": True}}
        self.native = FakeNative()
        self.previous_settings = copy.deepcopy(self.native.settings)
        self.manager = life.Manager(self.paths, self.native)
        self.write(self.original)
        self.enable()

    def write(self, config):
        life.atomic_write(self.paths.shell, json.dumps(config).encode())

    def enable(self):
        config = self.manager.config()
        config["bar"]["layout"]["left"].insert(0, {"id": life.PLUGIN})
        self.write(config)

    def disable(self):
        config = self.manager.config()
        for section, rows in config["bar"]["layout"].items():
            config["bar"]["layout"][section] = [row for row in rows if row["id"] != life.PLUGIN]
        self.write(config)

    def select_background(self, mode):
        name = "eleven-horizon-dark.png" if mode == "dark" else "eleven-horizon.png"
        self.native.image = str(self.paths.current / "theme/backgrounds" / name)
        return self.manager.sync_background()

    def test_wallpaper_switch_changes_native_and_gtk_palettes_and_keeps_pins(self):
        self.manager.reconcile(self.source)
        life.atomic_write(self.paths.preferences, b'{"pinnedApps":["chromium"]}')
        for mode in ("dark", "light", "dark"):
            self.assertEqual(self.select_background(mode)["mode"], mode)
            self.assertIn('mode = "' + mode + '"', (self.paths.theme / "colors.toml").read_text())
            self.assertEqual(self.native.settings["color-scheme"], "'prefer-" + mode + "'")
            prefs = json.loads(self.paths.preferences.read_text())
            self.assertEqual(prefs["pinnedApps"], ["chromium"])
            self.assertEqual(self.manager.load()["mode"], mode)
        self.disable()
        self.manager.deactivate()
        self.assertEqual(json.loads(self.paths.preferences.read_text())["appearanceMode"], "dark")
        self.assertEqual(self.native.image, "/wallpapers/original.png")
        self.assertEqual(self.native.settings, self.previous_settings)
        self.assertFalse(self.paths.theme.exists())
        self.enable()
        self.manager.reconcile(self.source)
        self.assertEqual(self.manager.load()["mode"], "dark")

    def test_external_wallpaper_or_theme_does_not_switch_mode(self):
        self.manager.reconcile(self.source)
        calls = list(self.native.calls)
        self.native.image = "/external/eleven-horizon-dark.png"
        self.assertFalse(self.manager.sync_background()["changed"])
        self.native.selected = "other-theme"
        self.select_background("dark")
        self.assertEqual(self.native.calls, calls)

    def test_repeated_background_notifications_do_not_reapply_theme(self):
        self.manager.reconcile(self.source)
        self.select_background("dark")
        calls = list(self.native.calls)
        self.assertFalse(self.select_background("dark")["changed"])
        self.assertEqual(self.native.calls, calls)

    def test_failed_mode_change_rolls_back_without_losing_original_snapshot(self):
        self.manager.reconcile(self.source)
        self.native.fail = True
        with self.assertRaises(RuntimeError):
            self.select_background("dark")
        self.assertEqual(self.manager.load()["mode"], "light")
        self.assertIn('mode = "light"', (self.paths.theme / "colors.toml").read_text())
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.native.image, "/wallpapers/original.png")
        self.assertEqual(self.native.settings, self.previous_settings)

    def test_active_upgrade_adds_dark_background_preserving_external_wallpaper(self):
        self.manager.reconcile(self.source)
        receipt = self.manager.load()
        relative = "backgrounds/eleven-horizon-dark.png"
        (self.paths.theme / relative).unlink()
        receipt["assets"].pop(relative)
        self.manager.save(receipt)
        self.native.image = "/external/custom.png"
        self.manager.reconcile(self.source)
        self.assertTrue((self.paths.theme / relative).is_file())
        self.assertEqual(self.native.image, "/external/custom.png")

    def test_pending_mode_recovers_previous_mode_after_restart(self):
        self.manager.reconcile(self.source)
        receipt = self.manager.load()
        receipt["pendingMode"] = "dark"
        self.manager.stage_assets(receipt, "dark")
        self.manager.save(receipt)
        self.manager.reconcile(self.source)
        self.assertIn('mode = "light"', (self.paths.theme / "colors.toml").read_text())
        self.assertNotIn("pendingMode", self.manager.load())

    def test_activation_replaces_only_start_preserving_bar_and_taskbar(self):
        self.manager.reconcile(self.source)
        config = self.manager.config()
        self.assertEqual(config["bar"]["layout"]["left"], [{"id": life.PLUGIN}, {"id": "omarchy.workspaces"}])
        for key in ("position", "transparent"):
            self.assertEqual(config["bar"][key], self.original["bar"][key])
        self.assertEqual(config["plugins"], self.original["plugins"])
        self.assertEqual(config["bar"]["layout"]["right"], self.original["bar"]["layout"]["right"])

    def test_disable_restores_appearance_and_keeps_plugin_assets_and_preferences(self):
        self.manager.reconcile(self.source)
        life.atomic_write(self.paths.preferences, b'{"pinnedApps":["chromium"]}')
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.manager.config(), self.original)
        self.assertEqual(self.native.selected, "tokyo-night")
        self.assertEqual(self.native.settings, self.previous_settings)
        self.assertEqual(self.native.image, "/wallpapers/original.png")
        self.assertFalse(self.paths.theme.exists())
        self.assertTrue(self.paths.preferences.exists())
        self.assertFalse(self.paths.helper.exists())
        self.assertIsNone(self.manager.load())

    def test_disable_enable_disable_is_reversible(self):
        for _ in range(3):
            self.manager.reconcile(self.source)
            self.disable()
            self.manager.deactivate()
            self.assertEqual(self.manager.config(), self.original)
            self.enable()

    def test_hot_reload_does_not_reapply_or_clean_the_theme(self):
        self.manager.reconcile(self.source)
        calls = list(self.native.calls)
        self.manager.deactivate()
        self.manager.reconcile(self.source)
        self.assertEqual(self.native.calls, calls)
        self.assertTrue(self.manager.load()["active"])

    def test_uninstall_restores_then_removes_only_owned_files(self):
        self.manager.reconcile(self.source)
        life.atomic_write(self.paths.preferences, b'{"pinnedApps":[]}')
        self.manager.deactivate(uninstall=True)
        self.assertEqual(self.manager.config(), self.original)
        self.assertFalse(self.paths.theme.exists())
        self.assertFalse(self.paths.preferences.exists())
        self.assertFalse(self.paths.receipt.exists())
        self.assertFalse(self.paths.helper.exists())

    def test_user_changes_to_settings_theme_and_layout_are_preserved(self):
        self.manager.reconcile(self.source)
        config = self.manager.config()
        config["bar"]["layout"]["right"].append({"id": "new-widget", "value": 42})
        config["bar"]["position"] = "bottom"
        self.write(config)
        self.native.selected = "other-theme"
        self.native.settings["icon-theme"] = "'User-icons'"
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.native.selected, "other-theme")
        self.assertEqual(self.native.settings["icon-theme"], "'User-icons'")
        self.assertEqual(self.manager.config()["bar"]["position"], "bottom")
        self.assertEqual(self.manager.config()["bar"]["layout"]["right"][-1]["value"], 42)

    def test_individual_setting_changes_survive_restoring_previous_theme(self):
        self.manager.reconcile(self.source)
        self.native.settings["icon-theme"] = "'User-icons'"
        self.native.image = "/wallpapers/user-new.png"
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.native.settings["icon-theme"], "'User-icons'")
        self.assertEqual(self.native.settings["color-scheme"], self.previous_settings["color-scheme"])
        self.assertEqual(self.native.image, "/wallpapers/user-new.png")

    def test_changed_theme_files_are_preserved_on_uninstall(self):
        self.manager.reconcile(self.source)
        changed = self.paths.theme / "colors.toml"
        changed.write_text("# user changes\n")
        unrelated = self.paths.theme / "user.txt"
        unrelated.write_text("keep")
        self.manager.deactivate(uninstall=True)
        self.assertEqual(changed.read_text(), "# user changes\n")
        self.assertEqual(unrelated.read_text(), "keep")
        self.assertFalse((self.paths.theme / "icons.theme").exists())

    def test_failed_activation_restores_previous_state(self):
        self.native.fail = True
        with self.assertRaisesRegex(RuntimeError, "Interrupted"):
            self.manager.reconcile(self.source)
        self.assertEqual(self.native.selected, "tokyo-night")
        self.assertEqual(self.manager.config(), self.original)
        self.assertIsNone(self.manager.load())

    def test_preexisting_theme_is_not_overwritten(self):
        self.paths.theme.mkdir(parents=True)
        (self.paths.theme / "mine.txt").write_text("mine")
        with self.assertRaisesRegex(RuntimeError, "already exists"):
            self.manager.reconcile(self.source)
        self.assertEqual((self.paths.theme / "mine.txt").read_text(), "mine")
        self.assertEqual(self.native.selected, "tokyo-night")

    def test_new_native_menu_settings_between_activations_are_kept(self):
        self.manager.reconcile(self.source)
        self.disable()
        self.manager.deactivate()
        config = self.manager.config()
        config["bar"]["layout"]["left"][0]["custom"] = "new"
        self.write(config)
        self.enable()
        self.manager.reconcile(self.source)
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.manager.config()["bar"]["layout"]["left"][0]["custom"], "new")

    def test_previously_unset_gsettings_are_reset_instead_of_persisting_defaults(self):
        self.native.unset.add("color-scheme")
        self.manager.reconcile(self.source)
        self.disable()
        self.manager.deactivate()
        self.assertEqual(self.native.settings["color-scheme"], "'default'")

    def test_disabled_plugin_can_be_removed_without_a_running_helper(self):
        with life.locked(self.paths):
            self.manager.reconcile(self.source)
        life.atomic_write(self.paths.preferences, b'{"pinnedApps":["chromium"]}')
        self.disable()
        with life.locked(self.paths):
            self.manager.deactivate()
        self.assertFalse(self.paths.state.exists())
        self.assertFalse(self.paths.theme.exists())
        self.assertTrue(self.paths.preferences.exists())
        shutil.rmtree(self.source)  # exactly what native remove does to a git clone
        self.assertFalse(self.paths.preferences.exists())
        self.assertEqual(self.manager.config(), self.original)

    def test_uninstall_after_source_was_deleted_uses_the_external_helper(self):
        with life.locked(self.paths):
            self.manager.reconcile(self.source)
        self.assertTrue(self.paths.helper.exists())
        shutil.rmtree(self.source)
        with life.locked(self.paths):
            self.manager.deactivate(uninstall=True)
        self.assertFalse(self.paths.state.exists())
        self.assertFalse(self.paths.theme.exists())
        self.assertEqual(self.native.selected, "tokyo-night")

    def test_cleanup_never_follows_replaced_resource_directories(self):
        self.manager.reconcile(self.source)
        outside = Path(self.directory.name) / "outside"
        outside.mkdir()
        original = self.paths.theme / "backgrounds/eleven-horizon.png"
        protected = outside / original.name
        shutil.copyfile(original, protected)
        original.unlink()
        (original.parent / "eleven-horizon-dark.png").unlink()
        original.parent.rmdir()
        original.parent.symlink_to(outside, target_is_directory=True)
        self.disable()
        self.manager.deactivate()
        self.assertTrue(protected.exists())
        self.assertTrue(original.parent.is_symlink())

    def test_power_availability_checks_only_the_native_read_only_conditions(self):
        with patch.object(life.subprocess, "run", side_effect=[SimpleNamespace(returncode=1), SimpleNamespace(returncode=0)]) as run:
            self.assertEqual(life.power_options(), {"suspend": True, "hibernate": True})
            self.assertEqual([call.args[0] for call in run.call_args_list], [
                ["omarchy", "toggle", "enabled", "suspend-off"], ["omarchy", "hibernation", "available"]])
        with patch.object(life.subprocess, "run", side_effect=OSError):
            self.assertEqual(life.power_options(), {"suspend": False, "hibernate": False})


if __name__ == "__main__":
    unittest.main()
