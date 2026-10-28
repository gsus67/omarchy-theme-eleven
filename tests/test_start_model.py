"""Run the QML presentation helpers with the installed JS engine."""
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "Node is needed for JavaScript tests")
class StartModelTest(unittest.TestCase):
    def evaluate(self, expression):
        script = (ROOT / "start/StartModel.js").read_text()
        result = subprocess.run([shutil.which("node"), "-e",
                                 script + "\nconsole.log(JSON.stringify(" + expression + "));"],
                                check=True, capture_output=True, text=True, timeout=5)
        return json.loads(result.stdout)

    def test_pins_are_deduplicated_and_untrusted_ids_remain_data(self):
        self.assertEqual(self.evaluate('validIds(["a", "a", null, "", "bad\\nentry", "$(touch nope)", "__proto__"])'),
                         ["a", "$(touch nope)", "__proto__"])

    def test_missing_and_hidden_apps_cannot_reappear_through_pins(self):
        self.assertEqual(self.evaluate('pinnedEntries([{id:"visible"}], ["missing", "visible", "hidden"])'),
                         [{"id": "visible"}])

    def test_empty_pins_and_toggle_are_reversible(self):
        self.assertEqual(self.evaluate('pinnedEntries([{id:"a"}], [])'), [])
        self.assertEqual(self.evaluate('togglePin(togglePin(["a"], "b"), "b")'), ["a"])

    def test_pin_count_is_bounded(self):
        self.assertEqual(len(self.evaluate('togglePin(Array.from({length:48},(_,i)=>"app"+i), "extra")')), 48)

    def test_keyboard_navigation_is_bounded(self):
        for expression, expected in [("movedIndex(-1,0,1,6,12)", 0),
                                     ("movedIndex(0,-1,0,6,12)", 0),
                                     ("movedIndex(11,0,1,6,12)", 11),
                                     ("movedIndex(0,0,1,6,12)", 6),
                                     ("movedIndex(0,0,1,6,0)", -1)]:
            self.assertEqual(self.evaluate(expression), expected)

    def test_categories_use_existing_desktop_metadata_without_duplicating_apps(self):
        groups = self.evaluate('categories([{id:"browser",categories:["Network","WebBrowser"]},{id:"art",categories:["Graphics"]},{id:"tools",categories:["System"]}])')
        self.assertEqual([group["id"] for group in groups], ["productivity", "utilities", "creativity"])
        ids = [entry["id"] for group in groups for entry in group["entries"]]
        self.assertEqual(sorted(ids), ["art", "browser", "tools"])

    def test_category_previews_are_bounded_and_unknown_apps_are_accessible(self):
        groups = self.evaluate('categories(Array.from({length:10},(_,i)=>({id:"app"+i})))')
        self.assertEqual(groups[0]["id"], "utilities")
        self.assertEqual(len(groups[0]["preview"]), 4)
        self.assertEqual(len(groups[0]["entries"]), 10)

    def test_power_menu_preserves_all_native_actions_and_filters_unavailable_sleep_modes(self):
        all_actions = self.evaluate('powerOptions(true,true).map(option=>option.id)')
        self.assertEqual(all_actions, ["screensaver", "lock", "suspend", "hibernate", "logout", "shutdown", "reboot"])
        actions = self.evaluate('powerOptions(false,false).map(option=>option.id)')
        self.assertNotIn("suspend", actions)
        self.assertNotIn("hibernate", actions)
        self.assertIn("shutdown", actions)


if __name__ == "__main__":
    unittest.main()
