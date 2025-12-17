#!/usr/bin/env python3
"""
Print glyph counts for all font files under app/qml/fonts.
Requires fontTools (already available in this environment).
"""
from pathlib import Path
from fontTools.ttLib import TTFont


def count_glyphs(font_path: Path) -> int:
    """Return the number of glyphs in the font."""
    with TTFont(str(font_path), lazy=False, fontNumber=0) as font:
        return len(font.getGlyphOrder())


def main() -> None:
    fonts_root = Path(__file__).resolve().parents[1] / "app" / "qml" / "fonts"
    font_files = sorted(
        p for p in fonts_root.rglob("*") if p.suffix.lower() in {".ttf", ".otf", ".otb"}
    )

    if not font_files:
        print(f"No font files found under {fonts_root}")
        return

    for font_path in font_files:
        rel = font_path.relative_to(fonts_root.parent.parent)
        try:
            count = count_glyphs(font_path)
            print(f"{rel}: {count} glyphs")
        except Exception as exc:  # noqa: BLE001
            print(f"{rel}: error reading font ({exc})")


if __name__ == "__main__":
    main()
