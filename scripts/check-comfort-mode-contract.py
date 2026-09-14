#!/usr/bin/env python3
# Copyright (c) 2026 Matt Van Horn
# https://github.com/Swordfish90/cool-retro-term
#
# This file is part of cool-retro-term.
#
# cool-retro-term is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""Static contract for Comfort effects mode.

Verifies that photosensitive CRT motion is clamped at the shader input
without overwriting stored slider values, and that the setting is wired
through persistence, settings UI, and menus.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

EFFECTS = (
    "flickering",
    "jitter",
    "staticNoise",
    "horizontalSync",
    "rgbShift",
    "glowingLine",
)

CONST_NAME = {
    "flickering": "COMFORT_MAX_FLICKERING",
    "jitter": "COMFORT_MAX_JITTER",
    "staticNoise": "COMFORT_MAX_STATIC_NOISE",
    "horizontalSync": "COMFORT_MAX_HORIZONTAL_SYNC",
    "rgbShift": "COMFORT_MAX_RGB_SHIFT",
    "glowingLine": "COMFORT_MAX_GLOWING_LINE",
}

EFFECTIVE_NAME = {
    "flickering": "effectiveFlickering",
    "jitter": "effectiveJitter",
    "staticNoise": "effectiveStaticNoise",
    "horizontalSync": "effectiveHorizontalSync",
    "rgbShift": "effectiveRgbShift",
    "glowingLine": "effectiveGlowingLine",
}

# Strobe / rolling / chromatic motion must fully drop. Residual grain may remain.
POLICY_MAX = {
    "flickering": 0.0,
    "horizontalSync": 0.0,
    "rgbShift": 0.0,
    "glowingLine": 0.0,
    "jitter": 0.05,
    "staticNoise": 0.05,
}


class ContractError(Exception):
    pass


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    if not path.is_file():
        raise ContractError(f"missing file: {path}")
    return path.read_text(encoding="utf-8")


def must_contain(haystack: str, needle: str, where: str) -> None:
    if needle not in haystack:
        raise ContractError(f"{where}: expected to contain {needle!r}")


def must_match(haystack: str, pattern: str, where: str) -> re.Match[str]:
    match = re.search(pattern, haystack, re.MULTILINE | re.DOTALL)
    if not match:
        raise ContractError(f"{where}: expected pattern {pattern!r}")
    return match


def parse_js_number(source: str, name: str) -> float:
    match = re.search(rf"var {name} = ([0-9]*\.?[0-9]+);", source)
    if not match:
        raise ContractError(f"utils.js: missing {name}")
    return float(match.group(1))


def parse_qml_default(source: str, name: str) -> float:
    match = re.search(rf"property real {name}: ([0-9]*\.?[0-9]+)", source)
    if not match:
        raise ContractError(f"ApplicationSettings.qml: missing default for {name}")
    return float(match.group(1))


def clamp(value: float, min_value: float, max_value: float) -> float:
    if value <= min_value:
        return min_value
    if value >= max_value:
        return max_value
    return value


def apply_comfort_clamp(
    effect_name: str, value: float, comfort_enabled: bool, limits: dict[str, float]
) -> float:
    if not comfort_enabled:
        return value
    if effect_name not in limits:
        return value
    return clamp(value, 0.0, limits[effect_name])


def check_utils(source: str) -> dict[str, float]:
    must_contain(source, "function applyComfortClamp(effectName, value, comfortEnabled)", "utils.js")
    must_contain(source, "function clamp(x, min, max)", "utils.js")
    limits = {}
    for effect in EFFECTS:
        const_name = CONST_NAME[effect]
        must_contain(source, const_name, "utils.js")
        must_contain(source, f'case "{effect}":', "utils.js")
        limits[effect] = parse_js_number(source, const_name)
        allowed = POLICY_MAX[effect]
        if limits[effect] < 0:
            raise ContractError(f"{const_name} must be >= 0")
        if limits[effect] > allowed + 1e-9:
            raise ContractError(
                f"{const_name}={limits[effect]} exceeds photosensitive policy max {allowed}"
            )
    return limits


def check_application_settings(source: str, limits: dict[str, float]) -> None:
    must_match(source, r"property bool comfortEffectsMode:\s*false", "ApplicationSettings.qml")
    must_contain(source, '"comfortEffectsMode": comfortEffectsMode', "ApplicationSettings.qml")
    must_contain(
        source,
        "comfortEffectsMode = settings.comfortEffectsMode",
        "ApplicationSettings.qml",
    )
    compose = must_match(
        source,
        r"function composeSettingsString\(\) \{(?P<body>.*?)^\s*function ",
        "ApplicationSettings.qml composeSettingsString",
    )
    compose_body = compose.group("body")
    if "comfortEffectsMode" not in compose_body:
        raise ContractError("composeSettingsString must persist comfortEffectsMode")
    if '"flickering": flickering' in compose_body:
        raise ContractError("comfortEffectsMode must not live in the profile payload")

    profile = must_match(
        source,
        r"function composeProfileObject\(\) \{(?P<body>.*?)^\s*function ",
        "ApplicationSettings.qml composeProfileObject",
    )
    if "comfortEffectsMode" in profile.group("body"):
        raise ContractError(
            "comfortEffectsMode is a durable window setting, not a profile field"
        )

    for effect in EFFECTS:
        effective = EFFECTIVE_NAME[effect]
        must_contain(
            source,
            f'readonly property real {effective}: Utils.applyComfortClamp("{effect}", {effect}, comfortEffectsMode)',
            "ApplicationSettings.qml",
        )
        default = parse_qml_default(source, effect)
        clamped = apply_comfort_clamp(effect, default, True, limits)
        if default > limits[effect] + 1e-9 and clamped > limits[effect] + 1e-9:
            raise ContractError(f"clamp failed to cap default {effect}")
        if effect in ("flickering", "jitter", "staticNoise", "horizontalSync", "glowingLine"):
            if default <= limits[effect]:
                raise ContractError(
                    f"default {effect}={default} is already at/under comfort cap "
                    f"{limits[effect]}; mode would not change the stock profile"
                )


def check_shader_terminal(source: str) -> None:
    raw = re.findall(
        r"appSettings\.(flickering|jitter|staticNoise|horizontalSync|rgbShift|glowingLine)\b",
        source,
    )
    if raw:
        raise ContractError(
            "ShaderTerminal.qml must not bind raw motion effects; "
            f"found appSettings.{raw[0]}"
        )
    for effect in EFFECTS:
        must_contain(source, f"appSettings.{EFFECTIVE_NAME[effect]}", "ShaderTerminal.qml")
    must_contain(source, "appSettings.effectiveRgbShift > 0", "ShaderTerminal.qml")
    must_contain(source, "appSettings.bloom", "ShaderTerminal.qml")
    must_contain(source, "appSettings.screenCurvature", "ShaderTerminal.qml")


def check_ui(effects_tab: str, advanced_tab: str, window_menu: str, context_menu: str, terminal_window: str) -> None:
    for where, source in (
        ("SettingsEffectsTab.qml", effects_tab),
        ("SettingsAdvancedTab.qml", advanced_tab),
    ):
        must_contain(source, "Comfort effects mode", where)
        must_contain(source, "appSettings.comfortEffectsMode", where)
        must_contain(source, "appSettings.comfortEffectsMode = checked", where)

    for where, source in (
        ("WindowMenu.qml", window_menu),
        ("FullContextMenu.qml", context_menu),
    ):
        must_contain(source, "comfortEffectsAction", where)

    must_contain(terminal_window, "id: comfortEffectsAction", "TerminalWindow.qml")
    must_contain(terminal_window, "Comfort Effects Mode", "TerminalWindow.qml")
    must_contain(
        terminal_window,
        "appSettings.comfortEffectsMode = !appSettings.comfortEffectsMode",
        "TerminalWindow.qml",
    )
    must_contain(terminal_window, "checkable: true", "TerminalWindow.qml")


def check_clamp_math(limits: dict[str, float]) -> None:
    cases = [
        ("flickering", 0.8, True, limits["flickering"]),
        ("flickering", 0.8, False, 0.8),
        ("jitter", 1.0, True, limits["jitter"]),
        ("staticNoise", 0.0, True, 0.0),
        ("horizontalSync", 0.5, True, 0.0),
        ("rgbShift", 0.4, True, 0.0),
        ("glowingLine", 0.9, True, 0.0),
        ("unknown", 0.3, True, 0.3),
    ]
    for name, value, enabled, expected in cases:
        got = apply_comfort_clamp(name, value, enabled, limits)
        if abs(got - expected) > 1e-9:
            raise ContractError(
                f"clamp math {name} value={value} enabled={enabled}: expected {expected}, got {got}"
            )


def check_gpl_header(path: Path) -> None:
    text = read(path)
    if "GNU General Public License" not in text:
        raise ContractError(f"{path.name}: missing GPLv3+ header")
    if "version 3 of the License, or" not in text:
        raise ContractError(f"{path.name}: header must be GPLv3 or later")


def main() -> int:
    root = repo_root()
    failures: list[str] = []

    files = {
        "utils": root / "app/qml/utils.js",
        "settings": root / "app/qml/ApplicationSettings.qml",
        "shader": root / "app/qml/ShaderTerminal.qml",
        "effects": root / "app/qml/SettingsEffectsTab.qml",
        "advanced": root / "app/qml/SettingsAdvancedTab.qml",
        "window_menu": root / "app/qml/menus/WindowMenu.qml",
        "context_menu": root / "app/qml/menus/FullContextMenu.qml",
        "terminal_window": root / "app/qml/TerminalWindow.qml",
        "contract": Path(__file__),
    }

    try:
        sources = {key: read(path) for key, path in files.items()}
        for path in files.values():
            check_gpl_header(path)

        limits = check_utils(sources["utils"])
        check_application_settings(sources["settings"], limits)
        check_shader_terminal(sources["shader"])
        check_ui(
            sources["effects"],
            sources["advanced"],
            sources["window_menu"],
            sources["context_menu"],
            sources["terminal_window"],
        )
        check_clamp_math(limits)
    except ContractError as exc:
        failures.append(str(exc))

    if failures:
        print("Comfort effects mode contract FAILED:")
        for item in failures:
            print(f"  - {item}")
        return 1

    print("Comfort effects mode contract OK")
    print("  clamped effects:", ", ".join(EFFECTS))
    print("  persisted setting: comfortEffectsMode (not a profile field)")
    print("  shader binds effective* properties; sliders keep stored values")
    return 0


if __name__ == "__main__":
    sys.exit(main())
