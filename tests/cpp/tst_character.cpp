#include <QtTest>
#include "tst_character.h"
#include "Character.h"
#include "CharacterColor.h"

using namespace Konsole;

// CharacterColor tests

void CharacterTest::testColorSpaceUndefined()
{
    CharacterColor color;
    QVERIFY(!color.isValid());
}

void CharacterTest::testColorSpaceDefault()
{
    // Default foreground (0)
    CharacterColor fg(COLOR_SPACE_DEFAULT, DEFAULT_FORE_COLOR);
    QVERIFY(fg.isValid());

    // Default background (1)
    CharacterColor bg(COLOR_SPACE_DEFAULT, DEFAULT_BACK_COLOR);
    QVERIFY(bg.isValid());

    // They should be different
    QVERIFY(fg != bg);
}

void CharacterTest::testColorSpaceSystem()
{
    // System colors 0-7, plus intensive variants (8-15)
    CharacterColor black(COLOR_SPACE_SYSTEM, 0);
    CharacterColor red(COLOR_SPACE_SYSTEM, 1);
    CharacterColor brightRed(COLOR_SPACE_SYSTEM, 9);  // 1 + 8 (intensive)

    QVERIFY(black.isValid());
    QVERIFY(red.isValid());
    QVERIFY(brightRed.isValid());

    QVERIFY(black != red);
    QVERIFY(red != brightRed);
}

void CharacterTest::testColorSpace256()
{
    // 256-color palette
    CharacterColor color16(COLOR_SPACE_256, 16);   // First non-system color
    CharacterColor color231(COLOR_SPACE_256, 231); // Last RGB cube color
    CharacterColor color255(COLOR_SPACE_256, 255); // Last grayscale

    QVERIFY(color16.isValid());
    QVERIFY(color231.isValid());
    QVERIFY(color255.isValid());
}

void CharacterTest::testColorSpaceRGB()
{
    // RGB color: 0xRRGGBB
    int red = (255 << 16) | (0 << 8) | 0;      // #FF0000
    int green = (0 << 16) | (255 << 8) | 0;    // #00FF00
    int blue = (0 << 16) | (0 << 8) | 255;     // #0000FF
    int white = (255 << 16) | (255 << 8) | 255; // #FFFFFF

    CharacterColor colorRed(COLOR_SPACE_RGB, red);
    CharacterColor colorGreen(COLOR_SPACE_RGB, green);
    CharacterColor colorBlue(COLOR_SPACE_RGB, blue);
    CharacterColor colorWhite(COLOR_SPACE_RGB, white);

    QVERIFY(colorRed.isValid());
    QVERIFY(colorGreen.isValid());
    QVERIFY(colorBlue.isValid());
    QVERIFY(colorWhite.isValid());

    QVERIFY(colorRed != colorGreen);
    QVERIFY(colorGreen != colorBlue);
}

void CharacterTest::testColorIsValid()
{
    CharacterColor undefined;
    CharacterColor defined(COLOR_SPACE_DEFAULT, 0);

    QVERIFY(!undefined.isValid());
    QVERIFY(defined.isValid());
}

void CharacterTest::testColorEquality()
{
    CharacterColor a(COLOR_SPACE_DEFAULT, 0);
    CharacterColor b(COLOR_SPACE_DEFAULT, 0);

    QVERIFY(a == b);
    QVERIFY(!(a != b));
}

void CharacterTest::testColorInequality()
{
    CharacterColor a(COLOR_SPACE_DEFAULT, 0);
    CharacterColor b(COLOR_SPACE_DEFAULT, 1);
    CharacterColor c(COLOR_SPACE_SYSTEM, 0);

    QVERIFY(a != b);  // Different value, same space
    QVERIFY(a != c);  // Same value, different space
}

void CharacterTest::testSetIntensive()
{
    CharacterColor normal(COLOR_SPACE_SYSTEM, 1);  // Red
    CharacterColor intensive(COLOR_SPACE_SYSTEM, 1);
    intensive.setIntensive();

    // After setIntensive, they should be different
    QVERIFY(normal != intensive);
}

// Character tests

void CharacterTest::testDefaultCharacter()
{
    Character ch;

    // Default character is a space
    QCOMPARE(ch.character, (wchar_t)' ');
    QCOMPARE(ch.rendition, (quint8)DEFAULT_RENDITION);
}

void CharacterTest::testCharacterWithValues()
{
    CharacterColor fg(COLOR_SPACE_SYSTEM, 2);  // Green
    CharacterColor bg(COLOR_SPACE_DEFAULT, DEFAULT_BACK_COLOR);

    Character ch('A', fg, bg, RE_BOLD);

    QCOMPARE(ch.character, (wchar_t)'A');
    QCOMPARE(ch.rendition, (quint8)RE_BOLD);
    QVERIFY(ch.foregroundColor == fg);
    QVERIFY(ch.backgroundColor == bg);
}

void CharacterTest::testCharacterEquality()
{
    CharacterColor fg(COLOR_SPACE_SYSTEM, 1);
    CharacterColor bg(COLOR_SPACE_DEFAULT, 1);

    Character a('X', fg, bg, RE_BOLD);
    Character b('X', fg, bg, RE_BOLD);

    QVERIFY(a == b);
}

void CharacterTest::testCharacterInequality()
{
    CharacterColor fg(COLOR_SPACE_SYSTEM, 1);
    CharacterColor bg(COLOR_SPACE_DEFAULT, 1);

    Character a('X', fg, bg, RE_BOLD);
    Character b('Y', fg, bg, RE_BOLD);  // Different character
    Character c('X', fg, bg, RE_UNDERLINE);  // Different rendition

    QVERIFY(a != b);
    QVERIFY(a != c);
}

void CharacterTest::testCharacterEqualsFormat()
{
    CharacterColor fg(COLOR_SPACE_SYSTEM, 1);
    CharacterColor bg(COLOR_SPACE_DEFAULT, 1);

    Character a('X', fg, bg, RE_BOLD);
    Character b('Y', fg, bg, RE_BOLD);  // Different char, same format

    // equalsFormat should return true (same colors and rendition)
    QVERIFY(a.equalsFormat(b));

    // But full equality should be false
    QVERIFY(a != b);
}

void CharacterTest::testRenditionFlags()
{
    Character bold(' ', CharacterColor(), CharacterColor(), RE_BOLD);
    Character italic(' ', CharacterColor(), CharacterColor(), RE_ITALIC);
    Character underline(' ', CharacterColor(), CharacterColor(), RE_UNDERLINE);
    Character combined(' ', CharacterColor(), CharacterColor(), RE_BOLD | RE_ITALIC);

    QCOMPARE(bold.rendition & RE_BOLD, (quint8)RE_BOLD);
    QCOMPARE(italic.rendition & RE_ITALIC, (quint8)RE_ITALIC);
    QCOMPARE(underline.rendition & RE_UNDERLINE, (quint8)RE_UNDERLINE);
    QCOMPARE(combined.rendition & RE_BOLD, (quint8)RE_BOLD);
    QCOMPARE(combined.rendition & RE_ITALIC, (quint8)RE_ITALIC);
}
