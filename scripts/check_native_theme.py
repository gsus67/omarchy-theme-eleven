#!/usr/bin/env python3
"""Render and restore with native Omarchy, with the real home hidden by bwrap."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    home = Path.home()
    if not shutil.which("bwrap") or not Path("/usr/share/omarchy").is_dir():
        raise SystemExit("Requires the existing bwrap and Omarchy installation")
    with tempfile.TemporaryDirectory(prefix="eleven-native-") as directory:
        isolated = Path(directory)
        theme = isolated / ".config/omarchy/themes/eleven-managed"
        theme.mkdir(parents=True)
        for origin in ROOT.glob("shell.*.toml"):
            shutil.copyfile(origin, theme / origin.name)
        for name in ("colors.toml", "icons.theme"):
            shutil.copyfile(ROOT / name, theme / name)
        (theme / "backgrounds").mkdir()
        shutil.copyfile(ROOT / "backgrounds/eleven-horizon.png", theme / "backgrounds/eleven-horizon.png")
        command = ["bwrap", "--die-with-parent", "--unshare-net", "--unshare-pid", "--unshare-ipc",
                   "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc", "--tmpfs", "/tmp",
                   "--dir", "/tmp/runtime", "--bind", str(isolated), str(home), "--chdir", str(home),
                   "--unsetenv", "DBUS_SESSION_BUS_ADDRESS", "--setenv", "XDG_RUNTIME_DIR", "/tmp/runtime",
                   "--setenv", "OMARCHY_PATH", "/usr/share/omarchy", "--setenv", "OMARCHY_THEME_HEADLESS", "1",
                   "--setenv", "OMARCHY_THEME_SKIP_BACKGROUND", "1"]
        for name in ("eleven-managed", "tokyo-night"):
            result = subprocess.run([*command, "omarchy", "theme", "set", name],
                                    capture_output=True, text=True, timeout=45)
            if result.returncode:
                raise SystemExit(result.stdout + result.stderr)
            current = isolated / ".local/state/omarchy/current"
            assert (current / "theme.name").read_text().strip() == name
            assert (current / "theme/colors.toml").is_file()
            assert (current / "theme/shell.toml").is_file()
        print("OK: native staging of Eleven and restoration of Tokyo Night in an isolated home")


if __name__ == "__main__":
    main()
