#!/usr/bin/env python3
"""Installer guardrail tests; no build or phone access required."""

import argparse
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("installer", Path(__file__).with_name("install-to-iphone.py"))
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def phone(identifier="phone-1", name="测试手机", reality="physical"):
    return {"identifier": identifier,
            "hardwareProperties": {"reality": reality, "deviceType": "iPhone", "udid": "udid-" + identifier},
            "deviceProperties": {"name": name, "developerModeStatus": "enabled"},
            "connectionProperties": {"pairingState": "paired"}}


class InstallerTests(unittest.TestCase):
    def test_simulator_is_never_an_install_target(self):
        simulator = phone("simulator", reality="simulated")
        self.assertEqual(installer.select_device([simulator, phone()])["identifier"], "phone-1")
        with self.assertRaises(installer.InstallError):
            installer.select_device([simulator], "simulator")

    def test_multiple_phones_require_an_unambiguous_selection(self):
        phones = [phone(), phone("phone-2")]
        for requested in (None, "测试手机"):
            with self.assertRaises(installer.InstallError):
                installer.select_device(phones, requested)
        self.assertEqual(installer.select_device(phones, "udid-phone-2")["identifier"], "phone-2")

    def test_unpaired_or_disabled_developer_mode_is_rejected(self):
        device = phone()
        device["connectionProperties"]["pairingState"] = "unpaired"
        with self.assertRaises(installer.InstallError):
            installer.select_device([device])
        device = phone()
        device["deviceProperties"]["developerModeStatus"] = "disabled"
        with self.assertRaises(installer.InstallError):
            installer.select_device([device])

    def test_readback_must_match_bundle_and_both_versions(self):
        expected = {"CFBundleIdentifier": "example.app", "CFBundleShortVersionString": "2.0", "CFBundleVersion": "3"}
        app = {"bundleIdentifier": "example.app", "version": "2.0", "bundleVersion": "3"}
        installer.verify_installed([app], expected)
        for field in ("bundleIdentifier", "version", "bundleVersion"):
            with self.assertRaises(installer.InstallError):
                installer.verify_installed([{**app, field: "wrong"}], expected)
        with self.assertRaises(installer.InstallError):
            installer.verify_installed([], expected)

    def test_unknown_lock_state_does_not_mean_unlocked(self):
        self.assertTrue(installer.is_locked({"passcodeRequired": True}))
        self.assertFalse(installer.is_locked({"passcodeRequired": False}))
        for data in ({}, {"passcodeRequired": "false"}):
            with self.assertRaises(installer.InstallError):
                installer.is_locked(data)

    def test_stderr_warnings_do_not_corrupt_json(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = installer.Runner(Path(directory))
            result = runner.run("settings", [sys.executable, "-c",
                                "import sys; print('[{}]'); print('warning', file=sys.stderr)"], json_stdout=True)
            self.assertEqual(json.loads(result.read_text()), [{}])
            self.assertIn("warning", (Path(directory) / "settings.log").read_text())

    def test_failed_build_never_attempts_install(self):
        with tempfile.TemporaryDirectory() as directory:
            settings = Path(directory) / "settings.json"
            settings.write_text(json.dumps([{"target": "IslandClock", "buildSettings": {
                "DEVELOPMENT_TEAM": "ABCDEFGHIJ", "TARGET_BUILD_DIR": directory,
                "FULL_PRODUCT_NAME": "IslandClock.app"}}]))
            runner = Mock()
            runner.device.side_effect = [{"devices": [phone()]}, {"passcodeRequired": False}]
            runner.run.side_effect = [settings, installer.InstallError("build failed")]
            args = argparse.Namespace(device=None, team="ABCDEFGHIJ", list_devices=False,
                                      build_only=False, no_launch=False, configuration="Release")
            with self.assertRaisesRegex(installer.InstallError, "build failed"):
                installer.execute(args, runner, {})
            self.assertEqual([c.args[0] for c in runner.device.call_args_list], ["devices", "lock-before-build"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
