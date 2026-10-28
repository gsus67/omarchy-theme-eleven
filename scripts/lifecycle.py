#!/usr/bin/env python3
"""Own Eleven's effects; restore individual changes, never a whole config."""
from contextlib import contextmanager
from pathlib import Path
import argparse
import base64
import copy
import fcntl
import hashlib
import json
import os
import re
import subprocess
import tempfile
import time

PLUGIN = "io.github.gsus67.omarchy-theme-eleven"
THEME = "eleven-managed"
SCHEMA = "org.gnome.desktop.interface"
ASSETS = ["colors.toml", "icons.theme", "backgrounds/eleven-horizon.png", "backgrounds/eleven-horizon-dark.png"]
ASSETS += [f"shell.{part}.toml" for part in (
    "bar", "controls", "font", "launcher", "lock", "menu", "notifications", "popups", "tooltip")]

SHORTCUTS = [
    (64, "Super_L", "SUPER + Super_L", "omarchy-shell eleven-start toggle", True),
    (64, "Super_R", "SUPER + Super_R", "omarchy-shell eleven-start toggle", True),
    (4, "Escape", "CTRL + Escape", "omarchy-shell eleven-start toggle", False),
    (64, "E", "SUPER + E", "omarchy launch filemanager", False),
    (64, "R", "SUPER + R", "omarchy-menu toggle apps", False),
    (64, "I", "SUPER + I", "omarchy-menu toggle setup", False),
    (64, "S", "SUPER + S", "omarchy-shell eleven-start open", False),
    (64, "L", "SUPER + L", "omarchy system lock", False),
]


def eligible_shortcuts(bindings):
    free, skipped = [], []
    for mask, key, keys, command, release in SHORTCUTS:
        def clashes(binding):
            existing = str(binding.get("key", "")).lower()
            same_mask = binding.get("modmask") == mask
            if release:
                physical = 133 if key == "Super_L" else 134
                return existing == key.lower() or int(binding.get("keycode", 0)) == physical or (same_mask and binding.get("catch_all", False))
            # Unknown physical-key bindings are treated conservatively rather
            # than guessing the user's keyboard layout or overriding a bind.
            return same_mask and (existing == key.lower() or binding.get("catch_all")
                                  or int(binding.get("keycode", 0)) > 0)
        conflict = next((binding for binding in bindings if clashes(binding)), None)
        if conflict:
            skipped.append({"keys": keys, "existing": conflict.get("description", "Existing binding")})
        else:
            free.append({"keys": keys, "command": command, "release": release,
                         "description": "Eleven shortcut: " + keys})
    return free, skipped


def lua_literal(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(item) for item in value) + "}"
    if isinstance(value, dict):
        return "{" + ",".join("[" + lua_literal(key) + "]=" + lua_literal(item) for key, item in value.items()) + "}"
    raise ValueError("Unsupported Lua value")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def plain_asset(root, relative):
    path = root
    if path.is_symlink():
        return False
    for part in Path(relative).parts:
        path = path / part
        if path.is_symlink():
            return False
    return True


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".eleven-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


class Paths:
    def __init__(self, home, config=None, state=None):
        self.home = Path(home)
        self.config = Path(config) if config else self.home / ".config"
        self.state_base = Path(state) if state else self.home / ".local/state"
        self.state = self.state_base / "omarchy-theme-eleven"
        self.receipt = self.state / "state.json"
        self.helper = self.state / "cleanup.py"
        self.preferences = None  # kept inside the installed plugin, not shared config
        self.shell = self.config / "omarchy/shell.json"
        self.theme = self.config / "omarchy/themes" / THEME
        # Omarchy 4.0.6 itself uses this fixed path, not XDG_STATE_HOME.
        self.current = self.home / ".local/state/omarchy/current"


def entries(config):
    for section in ("left", "center", "right"):
        for index, entry in enumerate(config.get("bar", {}).get("layout", {}).get(section, [])):
            if isinstance(entry, dict):
                yield section, index, entry


def enabled(config):
    if PLUGIN in config.get("disabledPlugins", []):
        return False
    return any(entry.get("id") == PLUGIN for _, _, entry in entries(config)) or any(
        isinstance(entry, dict) and entry.get("id") == PLUGIN for entry in config.get("plugins", []))


def original_start(config):
    for section in ("left", "center", "right"):
        rows = [entry for entry in config.get("bar", {}).get("layout", {}).get(section, [])
                if isinstance(entry, dict) and entry.get("id") != PLUGIN]
        for index, entry in enumerate(rows):
            if entry.get("id") == "omarchy.menu":
                return section, index, copy.deepcopy(entry)
    return None


class Native:
    def __init__(self, paths):
        self.paths = paths

    def command(self, args, *, env=None):
        return subprocess.run(args, check=True, text=True, capture_output=True, timeout=45, env=env).stdout.strip()

    def theme(self):
        path = self.paths.current / "theme.name"
        return path.read_text().strip() if path.exists() else ""

    def apply_theme(self, name):
        if not re.fullmatch(r"[a-zA-Z0-9_-]+", name):
            raise ValueError("Invalid theme identifier")
        # Native staging/templates, without browser policy elevation, downloads,
        # user hooks or restarting applications. Push presentation explicitly.
        script = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "bin/omarchy-theme-set"
        if "OMARCHY_THEME_HEADLESS" not in script.read_text():
            raise RuntimeError("This Omarchy version lacks safe headless theme staging")
        env = dict(os.environ, OMARCHY_THEME_HEADLESS="1", OMARCHY_THEME_SKIP_BACKGROUND="1")
        self.command(["omarchy", "theme", "set", name], env=env)
        self.refresh()

    def refresh(self):
        payloads = [base64.b64encode((self.paths.current / "theme" / name).read_bytes()).decode()
                    for name in ("colors.toml", "shell.toml")]
        self.command(["omarchy-shell", "shell", "applyTheme", *payloads])

    def get(self, key):
        return self.command(["gsettings", "get", SCHEMA, key])

    def set(self, key, value):
        self.command(["gsettings", "set", SCHEMA, key, value])

    def user_value(self, key):
        return self.command(["dconf", "read", f"/org/gnome/desktop/interface/{key}"])

    def reset(self, key):
        self.command(["gsettings", "reset", SCHEMA, key])

    def install_shortcuts(self, source):
        self.remove_shortcuts()
        bindings = json.loads(self.command(["hyprctl", "binds", "-j"]))
        candidates, skipped = eligible_shortcuts(bindings)
        script = (source / "scripts/shortcuts.lua").read_text()
        self.command(["hyprctl", "eval", "(function()\n" + script + "\nend)().install(" + lua_literal(candidates) + ")"])
        return {"installed": [item["keys"] for item in candidates], "skipped": skipped}

    def remove_shortcuts(self):
        bindings = json.loads(self.command(["hyprctl", "binds", "-j"]))
        safe = {}
        for mask, key, keys, _, _ in SHORTCUTS:
            same = [binding for binding in bindings if binding.get("modmask") == mask
                    and str(binding.get("key", "")).lower() == key.lower()]
            safe[keys] = all(binding.get("description") == "Eleven shortcut: " + keys for binding in same)
        # On this Hyprland version handle:unbind() removes all same-key binds.
        # If the user added another one meanwhile, disable only our handle and
        # let the compositor's next config reload discard that inert record.
        script = """local state = _G.__eleven_shortcuts
if state and state.owner == "io.github.gsus67.omarchy-theme-eleven" then
  local safe = SAFE
  for _, record in ipairs(state.binds) do
    if safe[record.keys] then record.handle:unbind()
    else record.handle:set_enabled(false) end
  end
  _G.__eleven_shortcuts = nil
end""".replace("SAFE", lua_literal(safe))
        self.command(["hyprctl", "eval", script])

    def background(self):
        path = self.paths.current / "background"
        return os.readlink(path) if path.is_symlink() else ""

    def set_background(self, path):
        self.command(["omarchy-shell", "background", "setInstant", path])
        target = self.paths.current / "background"
        temporary = target.with_name(".eleven-background")
        temporary.unlink(missing_ok=True)
        temporary.symlink_to(path)
        os.replace(temporary, target)


class Manager:
    def __init__(self, paths, native=None):
        self.paths = paths
        self.native = native or Native(paths)

    def config(self):
        return json.loads(self.paths.shell.read_text())

    def save(self, receipt):
        atomic_write(self.paths.receipt, (json.dumps(receipt, indent=2) + "\n").encode())

    def load(self):
        if not self.paths.receipt.exists():
            return None
        receipt = json.loads(self.paths.receipt.read_text())
        if receipt.get("owner") != PLUGIN:
            raise RuntimeError("Refusing an unrecognized ownership receipt")
        return receipt

    def mutate_config(self, mutator):
        # Retry if another settings writer changed the file while we prepared
        # our mutation. Preserve every unrelated entry and property.
        for _ in range(5):
            before = self.paths.shell.read_bytes()
            config = json.loads(before)
            mutator(config)
            if self.paths.shell.read_bytes() != before:
                continue
            after = (json.dumps(config, indent=2, ensure_ascii=False) + "\n").encode()
            if json.loads(before) != config:
                atomic_write(self.paths.shell, after)
            return
        raise RuntimeError("Shell settings are changing; retry activation")

    def preferences(self, source):
        path = Path(source) / ".eleven/preferences.json"
        if path.parent.is_symlink() or path.is_symlink():
            raise RuntimeError("Preferences must stay inside the installed plugin")
        return json.loads(path.read_text()) if path.is_file() else {}

    def remember_mode(self, source, mode):
        preferences = self.preferences(source)
        if preferences.get("appearanceMode") == mode:
            return
        preferences["appearanceMode"] = mode
        atomic_write(Path(source) / ".eleven/preferences.json",
                     (json.dumps(preferences) + "\n").encode())

    def stage_assets(self, receipt, mode):
        source = Path(receipt["source"])
        resources = []
        for relative in ASSETS:
            variant = ("variants/dark/" if mode == "dark" and
                       (relative == "colors.toml" or relative.startswith("shell.")) else "")
            origin = source / (variant + relative)
            target = self.paths.theme / relative
            if not plain_asset(source, variant + relative) or not origin.is_file():
                raise RuntimeError(f"Invalid theme resource: {relative}")
            if not plain_asset(self.paths.theme, relative) or (target.exists() and
                    digest(target) not in (receipt["assets"].get(relative), receipt.get("pendingAssets", {}).get(relative))):
                raise RuntimeError(f"Theme resource was changed by the user: {relative}")
            resources.append((relative, origin, target))
        for relative, origin, target in resources:
            target.parent.mkdir(parents=True, exist_ok=True)
            receipt.setdefault("pendingAssets", {})[relative] = digest(origin)
            self.save(receipt)
            atomic_write(target, origin.read_bytes())
            receipt["assets"][relative] = receipt["pendingAssets"].pop(relative)
            self.save(receipt)

    def apply_mode(self, receipt, mode):
        self.stage_assets(receipt, mode)
        receipt["managedSettings"] = {"color-scheme": "'prefer-dark'" if mode == "dark" else "'prefer-light'",
                                      "gtk-theme": "'Adwaita-dark'" if mode == "dark" else "'Adwaita'"}
        if Path("/usr/share/icons/Yaru-blue/index.theme").is_file():
            receipt["managedSettings"]["icon-theme"] = "'Yaru-blue'"
        self.save(receipt)
        self.native.apply_theme(THEME)
        for key, value in receipt["managedSettings"].items():
            self.native.set(key, value)
        filename = "eleven-horizon-dark.png" if mode == "dark" else "eleven-horizon.png"
        receipt["managedBackground"] = str(self.paths.current / "theme/backgrounds" / filename)
        self.save(receipt)
        self.native.set_background(receipt["managedBackground"])
        receipt["mode"] = mode
        receipt.pop("pendingMode", None)
        self.save(receipt)

    def sync_background(self):
        receipt = self.load()
        if not receipt or not receipt.get("active") or not enabled(self.config()):
            return {"active": False}
        previous = receipt.get("mode", "light")
        if self.native.theme() != THEME:
            return {"mode": previous, "changed": False}
        selected = Path(self.native.background()).resolve()
        modes = {"eleven-horizon.png": "light", "eleven-horizon-dark.png": "dark"}
        mode = next((value for name, value in modes.items() if selected ==
                     (self.paths.current / "theme/backgrounds" / name).resolve()), None)
        if mode is None:
            return {"mode": previous, "changed": False}
        if mode != previous:
            receipt["pendingMode"] = mode
            self.save(receipt)
            try:
                self.apply_mode(receipt, mode)
            except Exception:
                self.apply_mode(receipt, previous)
                raise
        else:
            receipt["managedBackground"] = self.native.background()
            self.save(receipt)
        # Keep the live selection in the receipt. Writing inside the plugin
        # triggers Omarchy's code reload watcher; persist preferences on disable.
        return {"active": True, "mode": mode, "changed": mode != previous}

    def reconcile(self, source):
        try:
            return self.activate(source)
        except Exception as error:
            try:
                self.deactivate(force=True)
            except Exception as restore_error:
                raise RuntimeError(f"Activation failed: {error}; restoration needs retry: {restore_error}") from error
            raise

    def activate(self, source):
        source = Path(source).resolve()
        self.paths.preferences = source / ".eleven/preferences.json"
        if not enabled(self.config()):
            return {"active": False}
        receipt = self.load()
        if receipt and receipt.get("active"):
            atomic_write(self.paths.helper, Path(__file__).read_bytes())
            receipt["shortcuts"] = self.native.install_shortcuts(source)
            self.save(receipt)
            if self.native.theme() == THEME and (receipt.get("pendingMode") or
                    any(relative not in receipt["assets"] for relative in ASSETS)):
                background = self.native.background()
                owned = background == receipt.get("managedBackground")
                self.apply_mode(receipt, receipt.get("mode", "light"))
                if not owned and background:
                    self.native.set_background(background)
            # Hot reload/login must not undo a theme the user selected later.
            return {"active": True, "theme": self.native.theme(), "mode": receipt.get("mode", "light")}
        if receipt is None:
            if self.paths.theme.exists() or self.paths.theme.is_symlink():
                raise RuntimeError("The managed theme path already exists; nothing was overwritten")
            original = original_start(self.config())
            receipt = {"owner": PLUGIN, "active": False, "phase": "prepared", "assets": {},
                       "originalStart": original}
        original = original_start(self.config())
        if receipt.get("phase") == "inactive" and original:
            receipt["originalStart"] = original
        previous = self.native.theme()
        if previous == THEME:
            # Recovery uses the snapshot recorded before the interrupted apply.
            previous = receipt.get("previousTheme", "")
        if not previous:
            raise RuntimeError("Cannot record the current theme; activation cancelled")
        recovering = receipt.get("phase") in ("prepared", "applying") and "previousTheme" in receipt
        if not recovering:
            background = self.native.background()
            if not background:
                raise RuntimeError("Cannot record the current wallpaper; activation cancelled")
            receipt.update(previousTheme=previous, previousBackground=self.native.background(),
                           previousSettings={key: self.native.get(key) for key in ("color-scheme", "gtk-theme", "icon-theme")},
                           previousUserValues={key: self.native.user_value(key) for key in ("color-scheme", "gtk-theme", "icon-theme")})
        receipt.update(source=str(source), phase="prepared")
        self.save(receipt)
        if self.paths.theme.is_symlink():
            raise RuntimeError("Managed theme directory became a symlink")
        self.paths.theme.mkdir(parents=True, exist_ok=True)
        atomic_write(self.paths.helper, Path(__file__).read_bytes())
        receipt["phase"] = "applying"
        self.save(receipt)
        mode = self.preferences(source).get("appearanceMode", "light")
        mode = mode if mode in ("light", "dark") else "light"
        self.apply_mode(receipt, mode)

        def replace_start(config):
            own = next((copy.deepcopy(e) for _, _, e in entries(config) if e.get("id") == PLUGIN), None)
            native = next(((s, i) for s, i, e in entries(config) if e.get("id") == "omarchy.menu"), None)
            if own is None or native is None:
                return
            for section in config["bar"]["layout"]:
                config["bar"]["layout"][section] = [e for e in config["bar"]["layout"][section] if e.get("id") != PLUGIN]
            # Locate again after removing our default-position entry.
            section, index, _ = next((s, i, e) for s, i, e in entries(config) if e.get("id") == "omarchy.menu")
            config["bar"]["layout"][section][index] = own

        self.mutate_config(replace_start)
        receipt["shortcuts"] = self.native.install_shortcuts(source)
        receipt.update(active=True, phase="active")
        self.save(receipt)
        return {"active": True, "theme": THEME, "mode": receipt.get("mode", "light")}

    def deactivate(self, *, uninstall=False, force=False):
        receipt = self.load()
        if receipt is None:
            return {"active": False}
        self.paths.preferences = Path(receipt["source"]) / ".eleven/preferences.json"
        # The source folder can disappear before Omarchy has persisted the
        # disabled entry. An uninstall must remove that own entry too.
        if not uninstall and not force and enabled(self.config()):
            return {"active": receipt.get("active", False), "reload": True}
        if not uninstall and receipt.get("active"):
            self.remember_mode(receipt["source"], receipt.get("mode", "light"))
        self.native.remove_shortcuts()
        previous = receipt.get("previousTheme", "")
        if self.native.theme() == THEME and previous:
            settings = {key: self.native.get(key) for key in receipt.get("managedSettings", {})}
            restore_background = self.native.background() == receipt.get("managedBackground")
            self.native.apply_theme(previous)
            for key, expected in receipt.get("managedSettings", {}).items():
                if settings[key] == expected:
                    user_value = receipt["previousUserValues"][key]
                    if user_value:
                        self.native.set(key, user_value)
                    else:
                        self.native.reset(key)
            if restore_background and receipt.get("previousBackground"):
                self.native.set_background(receipt["previousBackground"])

        def restore_start(config):
            for section in config.get("bar", {}).get("layout", {}):
                config["bar"]["layout"][section] = [e for e in config["bar"]["layout"][section] if e.get("id") != PLUGIN]
            if uninstall:
                config["plugins"] = [e for e in config.get("plugins", []) if e.get("id") != PLUGIN]
            original = receipt.get("originalStart")
            if original and not any(e.get("id") == "omarchy.menu" for _, _, e in entries(config)):
                section, index, entry = original
                layout = config.setdefault("bar", {}).setdefault("layout", {}).setdefault(section, [])
                layout.insert(min(index, len(layout)), entry)

        self.mutate_config(restore_start)
        if self.native.theme() == THEME:
            raise RuntimeError("Managed theme is still selected; its resources were preserved")
        for relative in ASSETS:
            target = self.paths.theme / relative
            if plain_asset(self.paths.theme, relative) and target.is_file() and digest(target) in (receipt["assets"].get(relative), receipt.get("pendingAssets", {}).get(relative)):
                target.unlink()
        for directory in (self.paths.theme / "backgrounds", self.paths.theme):
            if directory.is_dir() and not directory.is_symlink() and not any(directory.iterdir()):
                directory.rmdir()
        if uninstall:
            self.paths.preferences.unlink(missing_ok=True)
            if self.paths.preferences.parent.exists() and not any(self.paths.preferences.parent.iterdir()):
                self.paths.preferences.parent.rmdir()
        self.paths.receipt.unlink(missing_ok=True)
        self.paths.helper.unlink(missing_ok=True)
        return {"active": False, "uninstalled": uninstall}


@contextmanager
def locked(paths):
    paths.state.mkdir(parents=True, exist_ok=True)
    lock = paths.state / "lock"
    with lock.open("a") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield
    # Keep the lock inode while installed, even when disabled. Remove only
    # after uninstall; there are no periodic workers or resident helpers.
    if not paths.receipt.exists() and not paths.helper.exists():
        lock.unlink(missing_ok=True)
        if not any(paths.state.iterdir()):
            paths.state.rmdir()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=("activate", "cleanup", "pins", "power-options", "shortcuts", "sync-background"))
    parser.add_argument("value", nargs="?", default="")
    args = parser.parse_args()
    if args.operation == "power-options":
        print(json.dumps(power_options()))
        return
    if not args.value:
        if args.operation not in ("shortcuts", "sync-background"):
            parser.error("This operation requires a value")
    paths = Paths(Path.home(), os.environ.get("XDG_CONFIG_HOME"), os.environ.get("XDG_STATE_HOME"))
    if args.operation == "cleanup":
        time.sleep(1)  # let Omarchy finish persisting its disable/remove action
    with locked(paths):
        manager = Manager(paths)
        if args.operation == "activate":
            changing = not (manager.load() or {}).get("active", False)
            if changing:
                notify("Aplicando tema e Inicio…")
            result = manager.reconcile(args.value)
            if changing and result.get("active"):
                notify("Eleven está listo")
        elif args.operation == "cleanup":
            result = manager.deactivate(uninstall=not Path(args.value).is_dir())
            if not result.get("reload"):
                notify("Eleven desinstalado" if result.get("uninstalled") else "Eleven desactivado")
        elif args.operation == "sync-background":
            result = manager.sync_background()
        elif args.operation == "shortcuts":
            receipt = manager.load()
            if receipt and enabled(manager.config()):
                receipt["shortcuts"] = manager.native.install_shortcuts(Path(receipt["source"]))
                manager.save(receipt)
                result = receipt["shortcuts"]
            else:
                result = {"installed": []}
        else:
            paths.preferences = Path(__file__).resolve().parents[1] / ".eleven/preferences.json"
            if paths.preferences.parent.is_symlink() or paths.preferences.is_symlink():
                raise RuntimeError("Preferences must stay inside the installed plugin")
            pins = json.loads(args.value)
            if not isinstance(pins, list) or len(pins) > 48 or any(
                not isinstance(value, str) or not value or len(value) > 512
                or re.search(r"[\x00-\x1f\x7f-\x9f]", value) for value in pins):
                raise ValueError("Invalid pinned applications")
            preferences = manager.preferences(paths.preferences.parents[1])
            preferences["pinnedApps"] = list(dict.fromkeys(pins))
            atomic_write(paths.preferences, (json.dumps(preferences) + "\n").encode())
            result = {"saved": True}
        print(json.dumps(result))


def power_options():
    def status(args):
        try:
            return subprocess.run(args, capture_output=True, timeout=3, check=False).returncode
        except (OSError, subprocess.TimeoutExpired):
            return None
    return {"suspend": status(["omarchy", "toggle", "enabled", "suspend-off"]) == 1,
            "hibernate": status(["omarchy", "hibernation", "available"]) == 0}


def notify(message, *, critical=False):
    try:
        subprocess.run(["notify-send", "-a", "Eleven", "-u", "critical" if critical else "normal", "Eleven", message],
                       capture_output=True, timeout=5, check=False)
    except (OSError, subprocess.TimeoutExpired):
        pass


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        notify(str(error), critical=True)
        print(json.dumps({"error": str(error)}))
        raise SystemExit(1)
