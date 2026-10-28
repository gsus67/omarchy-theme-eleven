"""Verify pinned third-party SVGs, notices and the absence of external content."""
import hashlib
import json
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / "assets/fluent"


class IconAssetsTest(unittest.TestCase):
    def test_vendored_icons_match_the_documented_revision_and_hashes(self):
        sources = json.loads((ROOT / "sources.json").read_text())
        self.assertRegex(sources["revision"], r"^[0-9a-f]{40}$")
        for entry in sources["assets"]:
            with self.subTest(icon=entry["file"]):
                self.assertTrue(entry["url"].startswith("https://raw.githubusercontent.com/microsoft/fluentui-system-icons/" + sources["revision"] + "/"))
                self.assertEqual(hashlib.sha256((ROOT / entry["file"]).read_bytes()).hexdigest(), entry["sha256"])
                self.assertRegex(entry["upstreamSha256"], r"^[0-9a-f]{64}$")
        for name, expected in sources["noticeSha256"].items():
            self.assertEqual(hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), expected)
        self.assertIn("MIT License", (ROOT / "LICENSE").read_text())
        self.assertIn("Copyright (c) 2020 Microsoft Corporation", (ROOT / "LICENSE").read_text())

    def test_svg_assets_have_no_executable_or_external_content(self):
        for path in ROOT.glob("*.svg"):
            with self.subTest(icon=path.name):
                for element in ET.parse(path).iter():
                    self.assertIn(element.tag.rsplit("}", 1)[-1], ("svg", "path", "g", "defs", "clipPath", "rect", "circle"))
                    for key, value in element.attrib.items():
                        self.assertFalse(key.lower().startswith("on"))
                        self.assertNotIn("href", key.lower())
                        for target in re.findall(r"url\(([^)]+)\)", value):
                            self.assertTrue(target.startswith("#"))
