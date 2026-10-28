#!/usr/bin/env python3
"""Validate the declarative theme using only Python's standard library."""

from pathlib import Path
import re
import struct
import tomllib
import xml.etree.ElementTree as ET


def main():
    root = Path(__file__).resolve().parents[1]
    for directory, mode in ((root, "light"), (root / "variants/dark", "dark")):
        palette = tomllib.loads((directory / "colors.toml").read_text())
        assert palette.get("mode") == mode
        required = {"accent", "background", "foreground", "selection", "blue", "red"}
        assert required <= palette.keys(), "Missing core palette values"
        for name, value in palette.items():
            if name != "mode":
                assert re.fullmatch(r"#[0-9a-fA-F]{6}", value), f"Invalid color: {name}"
        assert {p.name for p in directory.glob("shell.*.toml")} == {p.name for p in root.glob("shell.*.toml")}
        for path in directory.glob("shell.*.toml"):
            data = tomllib.loads(path.read_text())
            section = path.name.removeprefix("shell.").removesuffix(".toml")
            assert set(data) == {section}, f"Unexpected section: {path.name}"
    icon_theme = (root / "icons.theme").read_text().strip()
    assert re.fullmatch(r"[A-Za-z0-9_-]+", icon_theme), "Invalid icon theme name"

    for name in ("eleven-horizon", "eleven-horizon-dark"):
        svg = ET.parse(root / ("artwork/" + name + ".svg"))
        allowed = {"svg", "title", "desc", "defs", "linearGradient", "stop", "rect", "path"}
        for node in svg.iter():
            tag = node.tag.rsplit("}", 1)[-1]
            assert tag in allowed, f"Unexpected SVG element: {tag}"
            for key, value in node.attrib.items():
                assert not key.lower().startswith("on"), "SVG event handlers are forbidden"
                assert "href" not in key.lower(), "External SVG resources are forbidden"
                for target in re.findall(r"url\(([^)]+)\)", value):
                    assert target.startswith("#"), "Only local gradient references are allowed"
        png = (root / ("backgrounds/" + name + ".png")).read_bytes()
        assert png[:8] == b"\x89PNG\r\n\x1a\n", "Invalid PNG signature"
        assert png[12:16] == b"IHDR", "Missing PNG header"
        assert struct.unpack(">II", png[16:24]) == (2560, 1440), "Unexpected wallpaper size"
    print("OK: palette, shell sections, icon reference, SVG and PNG header")


if __name__ == "__main__":
    main()
