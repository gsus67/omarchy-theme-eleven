"""Windows-style shortcuts must not replace the user's existing bindings."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("shortcuts_lifecycle", ROOT / "scripts/lifecycle.py")
life = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(life)


class ShortcutTest(unittest.TestCase):
    def test_existing_windows_equivalents_and_conflicting_omarchy_actions_are_kept(self):
        bindings = [{"modmask": 64, "key": "E", "description": "File manager"},
                    {"modmask": 64, "key": "L", "description": "Toggle workspace layout"}]
        free, skipped = life.eligible_shortcuts(bindings)
        self.assertNotIn("SUPER + E", [item["keys"] for item in free])
        self.assertNotIn("SUPER + L", [item["keys"] for item in free])
        self.assertIn({"keys": "SUPER + L", "existing": "Toggle workspace layout"}, skipped)
        self.assertIn("SUPER + Super_L", [item["keys"] for item in free])

    def test_case_physical_keys_and_catch_all_bindings_are_treated_conservatively(self):
        for binding in ({"modmask": 64, "key": "r"}, {"modmask": 64, "keycode": 30},
                        {"modmask": 64, "catch_all": True}):
            free, _ = life.eligible_shortcuts([binding])
            self.assertNotIn("SUPER + R", [item["keys"] for item in free])

    def test_any_existing_modifier_only_binding_blocks_ours(self):
        free, _ = life.eligible_shortcuts([{"modmask": 0, "key": "Super_L"}])
        self.assertNotIn("SUPER + Super_L", [item["keys"] for item in free])

    @unittest.skipUnless(shutil.which("lua"), "Lua is needed to execute the compositor module")
    def test_lua_uses_native_release_binds_without_keyboard_listeners_or_process_polling(self):
        module = (ROOT / "scripts/shortcuts.lua").read_text()
        candidates, _ = life.eligible_shortcuts([])
        script = '''local calls = {}
hl = {dsp = {exec_cmd = function(command) return command end}, bind = function(keys, dispatcher, flags)
  table.insert(calls, {keys=keys, dispatcher=dispatcher, release=flags.release})
  return {}
end}
local module = (function()\n''' + module + '\nend)()\nmodule.install(' + life.lua_literal(candidates) + ''')
assert(#calls == 8)
assert(calls[1].release == true and calls[2].release == true)
assert(calls[3].release == false)
assert(_G.__eleven_shortcuts.owner == "io.github.gsus67.omarchy-theme-eleven")
'''
        subprocess.run([shutil.which("lua"), "-"], input=script, text=True, check=True, capture_output=True, timeout=5)

    def test_cleanup_disables_only_our_handle_if_user_added_the_same_combination(self):
        native = life.Native(life.Paths("/unused"))
        calls = []
        def command(args, **kwargs):
            calls.append(args)
            if args[1:3] == ["binds", "-j"]:
                return json.dumps([{"modmask": 64, "key": "R", "description": "User custom binding"}])
            return "ok"
        native.command = command
        native.remove_shortcuts()
        script = calls[-1][-1]
        self.assertIn('["SUPER + R"]=false', script)
        self.assertIn('record.handle:set_enabled(false)', script)
        self.assertNotIn('hl.unbind(', script)
