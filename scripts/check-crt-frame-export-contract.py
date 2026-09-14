#!/usr/bin/env python3
"""Static contract checks for composited CRT frame PNG export.

Verifies that Save CRT Frame is wired through ShaderTerminal grabToImage,
the window/menu actions, PNG file dialog, and FileIO PNG write helpers.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.is_file():
        raise FileNotFoundError(rel)
    return path.read_text(encoding="utf-8")


def must_contain(rel: str, needles: list[str], errors: list[str]) -> None:
    text = read(rel)
    for needle in needles:
        if needle not in text:
            errors.append(f"{rel}: missing {needle!r}")


def main() -> int:
    errors: list[str] = []

    must_contain(
        "app/qml/ShaderTerminal.qml",
        [
            "grabToImage",
            "saveCompositedFrame",
            "dynamicShader",
            "writePng",
            "saveToFile",
        ],
        errors,
    )
    must_contain(
        "app/qml/TerminalContainer.qml",
        [
            "ShaderTerminal {",
            "function saveCrtFrame",
            "saveCompositedFrame",
        ],
        errors,
    )
    must_contain(
        "app/qml/TerminalTabs.qml",
        [
            "function saveCrtFrame",
            "currentContainer",
            "saveCrtFrame(destinationUrl)",
        ],
        errors,
    )
    must_contain(
        "app/qml/TerminalWindow.qml",
        [
            "saveCrtFrameAction",
            'qsTr("Save CRT Frame")',
            "FileDialog",
            "PNG images (*.png)",
            "defaultSuffix: \"png\"",
            "acceptLabel",
            "terminalTabs.saveCrtFrame",
            "crtFrameFileDialog",
        ],
        errors,
    )
    for menu in (
        "app/qml/menus/WindowMenu.qml",
        "app/qml/menus/FullContextMenu.qml",
        "app/qml/menus/ShortContextMenu.qml",
    ):
        must_contain(menu, ["saveCrtFrameAction"], errors)

    must_contain(
        "app/fileio.h",
        ["toLocalFile", "writePng"],
        errors,
    )
    must_contain(
        "app/fileio.cpp",
        ['png.save(path, "PNG")', "toLocalFile"],
        errors,
    )
    must_contain(
        "app/qml/resources.qrc",
        [
            "ShaderTerminal.qml",
            "TerminalContainer.qml",
            "TerminalWindow.qml",
            "TerminalTabs.qml",
            "menus/WindowMenu.qml",
            "menus/FullContextMenu.qml",
            "menus/ShortContextMenu.qml",
        ],
        errors,
    )

    if (ROOT / "AI_PR_NOTICE.txt").exists():
        errors.append("AI_PR_NOTICE.txt must not be added")

    if errors:
        print("CRT frame export contract FAILED:")
        for item in errors:
            print(f"  - {item}")
        return 1

    print("CRT frame export contract OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
