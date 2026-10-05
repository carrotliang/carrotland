#!/usr/bin/env python3
"""Build, verify, and overwrite-install IslandClock using Xcode's local tools."""

import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
LOCAL_CONFIG = ROOT / "Scripts/install.local.json"


class InstallError(Exception):
    pass


def select_device(devices, requested=None):
    # Recent devicectl versions also list simulators: never install to one here.
    phones = [d for d in devices
              if d.get("hardwareProperties", {}).get("reality") == "physical"
              and d.get("hardwareProperties", {}).get("deviceType") == "iPhone"
              and d.get("connectionProperties", {}).get("pairingState") == "paired"]
    if requested:
        phones = [d for d in phones if requested in (
            d.get("identifier"), d.get("deviceProperties", {}).get("name"),
            d.get("hardwareProperties", {}).get("udid"))]
    if not phones:
        raise InstallError("未找到匹配的已配对 iPhone。请连接并信任手机，或用 --list-devices 查看设备。")
    if len(phones) != 1:
        raise InstallError("发现多台匹配的 iPhone，请使用 --device 明确指定设备名称或标识符。")
    phone = phones[0]
    if not phone.get("identifier"):
        raise InstallError("设备缺少 identifier，无法安全选择安装目标。")
    if phone.get("deviceProperties", {}).get("developerModeStatus") == "disabled":
        raise InstallError("请先在手机的设置中开启开发者模式。")
    return phone


def verify_installed(apps, expected):
    matches = [a for a in apps
               if a.get("bundleIdentifier") == expected["CFBundleIdentifier"]]
    if len(matches) != 1:
        raise InstallError("安装命令完成，但手机端未回读到唯一匹配的应用。")
    app = matches[0]
    for actual, wanted in (("version", "CFBundleShortVersionString"),
                           ("bundleVersion", "CFBundleVersion")):
        if str(app.get(actual)) != str(expected[wanted]):
            raise InstallError("手机端版本与本次构建不一致，请查看安装回读日志。")


def load_config():
    if not LOCAL_CONFIG.exists():
        return {}
    config = json.loads(LOCAL_CONFIG.read_text())
    if not isinstance(config, dict) or set(config) - {"team", "device"}:
        raise InstallError("install.local.json 只支持 team、device 两个字段。")
    if any(not isinstance(value, str) or not value.strip() for value in config.values()):
        raise InstallError("本地配置字段必须是非空字符串。")
    return config


class Runner:
    def __init__(self, logs):
        self.logs = logs

    def run(self, label, command, json_stdout=False):
        log = self.logs / (label + ".log")
        print("→ " + label, flush=True)
        with log.open("w") as output:
            result = subprocess.run(command, cwd=ROOT,
                                    stdout=subprocess.PIPE if json_stdout else output,
                                    stderr=output if json_stdout else subprocess.STDOUT)
        # Xcode warnings belong in the log, never in the JSON parser input.
        if json_stdout:
            json_path = self.logs / (label + ".json")
            json_path.write_bytes(result.stdout)
        if result.returncode:
            tail = "\n".join(log.read_text(errors="replace").splitlines()[-15:])
            raise InstallError(f"{label} 失败（退出码 {result.returncode}）。\n{tail}\n完整日志：{log}")
        return json_path if json_stdout else log

    def device(self, label, *arguments):
        output = self.logs / (label + ".json")
        self.run(label, ["xcrun", "devicectl", *arguments,
                         "--timeout", "120", "--json-output", str(output)])
        result = json.loads(output.read_text())
        if result.get("info", {}).get("outcome") != "success":
            raise InstallError(f"{label} 没有返回成功状态，请检查 {output}")
        return result["result"]


def is_locked(result):
    locked = result.get("passcodeRequired")
    if not isinstance(locked, bool):
        raise InstallError("无法识别手机锁屏状态，请检查 lock-state JSON 日志。")
    return locked


def execute(args, runner, config):
    device_arg = args.device or os.environ.get("IPHONE_DEVICE") or config.get("device")
    team = args.team or os.environ.get("DEVELOPMENT_TEAM") or config.get("team")
    if team and not re.fullmatch(r"[A-Z0-9]{10}", team):
        raise InstallError("Team ID 应为 10 位大写字母或数字，请检查 --team 或本地配置。")

    if args.list_devices or not args.build_only:
        devices = runner.device("devices", "list", "devices").get("devices", [])
        if args.list_devices:
            for d in devices:
                if d.get("hardwareProperties", {}).get("reality") == "physical":
                    print(" | ".join((d.get("deviceProperties", {}).get("name", "未知设备"),
                                      d.get("identifier", "未知标识"),
                                      d.get("connectionProperties", {}).get("pairingState", "未知配对状态"),
                                      d.get("connectionProperties", {}).get("tunnelState", "未知连接状态"))))
            return
        phone = select_device(devices, device_arg)
        device_id = phone["identifier"]
        print("目标手机：" + phone["deviceProperties"]["name"], flush=True)
        locked = is_locked(runner.device("lock-before-build", "device", "info", "lockState",
                                         "--device", device_id))
        if locked:
            print("手机已锁屏；可以继续编译和尝试安装，启动前需要解锁。", flush=True)

    derived_data = ROOT / ".build/iphone/DerivedData"
    common = ["xcodebuild", "-project", str(ROOT / "IslandClock.xcodeproj"),
              "-scheme", "IslandClock", "-configuration", args.configuration,
              "-destination", "generic/platform=iOS", "-derivedDataPath", str(derived_data)]
    if team:
        common += ["DEVELOPMENT_TEAM=" + team]
    settings_log = runner.run("build-settings", common + ["-showBuildSettings", "-json"], json_stdout=True)
    settings = json.loads(settings_log.read_text())
    settings = next((s["buildSettings"] for s in settings if s.get("target") == "IslandClock"), None)
    if not settings or not settings.get("DEVELOPMENT_TEAM"):
        raise InstallError("没有配置签名团队。请在 Xcode 中选择 Team，或传入 --team TEAM_ID。")
    app_path = Path(settings["TARGET_BUILD_DIR"]) / settings["FULL_PRODUCT_NAME"]

    runner.run("build", common + ["-allowProvisioningUpdates", "build"])
    if app_path.suffix != ".app" or not (app_path / "Info.plist").is_file():
        raise InstallError(f"构建完成但未找到 App：{app_path}")
    runner.run("verify-signature", ["codesign", "--verify", "--deep", "--strict", str(app_path)])
    with (app_path / "Info.plist").open("rb") as source:
        info = plistlib.load(source)
    for key in ("CFBundleIdentifier", "CFBundleShortVersionString", "CFBundleVersion"):
        if not info.get(key):
            raise InstallError("安装包缺少必要字段：" + key)
    bundle_id = info["CFBundleIdentifier"]
    print(f"构建和签名校验通过：{info.get('CFBundleDisplayName', bundle_id)} "
          f"{info['CFBundleShortVersionString']} ({info['CFBundleVersion']})\n安装包：{app_path}", flush=True)
    if args.build_only:
        return

    # Install in place: no uninstall and no deletion of the phone's app data.
    runner.device("install", "device", "install", "app", "--device", device_id, str(app_path))
    installed = runner.device("installed-app", "device", "info", "apps",
                              "--device", device_id, "--bundle-id", bundle_id)
    verify_installed(installed.get("apps", []), info)
    print("覆盖安装成功，手机端 Bundle ID 和版本回读一致。", flush=True)
    if args.no_launch:
        print("已按 --no-launch 跳过启动。")
        return

    try:
        locked = is_locked(runner.device("lock-before-launch", "device", "info", "lockState",
                                         "--device", device_id))
        if locked:
            print("安装已完成；手机锁屏，未执行启动。请解锁后手动打开“灵动萝卜”。")
            return
        runner.device("launch", "device", "process", "launch", "--device", device_id, bundle_id)
    except InstallError as error:
        raise InstallError("安装及回读已成功，但启动未完成（可能在检查后重新锁屏）。\n" + str(error)) from error
    print("安装并启动成功。", flush=True)


def main():
    parser = argparse.ArgumentParser(description="编译、签名校验并覆盖安装灵动萝卜到已配对 iPhone。")
    parser.add_argument("--team", help="Apple Developer Team ID；默认使用环境变量、本地配置或 Xcode 设置")
    parser.add_argument("--device", help="手机名称、CoreDevice 标识符或 UDID；默认选择唯一已配对 iPhone")
    parser.add_argument("--configuration", choices=("Debug", "Release"), default="Release")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--build-only", action="store_true", help="仅构建和校验签名")
    mode.add_argument("--list-devices", action="store_true", help="只列出物理设备")
    parser.add_argument("--no-launch", action="store_true", help="安装并回读后不启动 App")
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("此脚本需要 macOS 和完整 Xcode。")
    for tool in ("xcodebuild", "xcrun", "codesign"):
        if not shutil.which(tool):
            parser.error("缺少工具：" + tool)

    logs_root = ROOT / ".build/iphone/logs"
    logs_root.mkdir(parents=True, exist_ok=True)
    logs = Path(tempfile.mkdtemp(prefix="run-", dir=logs_root))
    print("本次日志：" + str(logs), flush=True)
    try:
        # Protect the shared build products from concurrent installer runs.
        import fcntl
        with (logs_root.parent / "install.lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise InstallError("已有安装脚本正在运行，请等待它完成。") from error
            execute(args, Runner(logs), load_config())
    except (InstallError, OSError, ValueError, KeyError) as error:
        print(f"错误：{error}\n本次日志保留在：{logs}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print(f"已中断；请检查日志确认最后完成的步骤：{logs}", file=sys.stderr)
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
