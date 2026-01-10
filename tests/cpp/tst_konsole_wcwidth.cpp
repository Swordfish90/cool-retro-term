#include <QtTest>
#include "tst_konsole_wcwidth.h"
#include "konsole_wcwidth.h"

// ASCII characters - width 1
void KonsoleWcwidthTest::testAsciiLetter()
{
    QCOMPARE(konsole_wcwidth(L'A'), 1);
    QCOMPARE(konsole_wcwidth(L'z'), 1);
    QCOMPARE(konsole_wcwidth(L'M'), 1);
}

void KonsoleWcwidthTest::testAsciiDigit()
{
    QCOMPARE(konsole_wcwidth(L'0'), 1);
    QCOMPARE(konsole_wcwidth(L'5'), 1);
    QCOMPARE(konsole_wcwidth(L'9'), 1);
}

void KonsoleWcwidthTest::testAsciiSpace()
{
    QCOMPARE(konsole_wcwidth(L' '), 1);
}

void KonsoleWcwidthTest::testAsciiPunctuation()
{
    QCOMPARE(konsole_wcwidth(L'.'), 1);
    QCOMPARE(konsole_wcwidth(L','), 1);
    QCOMPARE(konsole_wcwidth(L'!'), 1);
    QCOMPARE(konsole_wcwidth(L'@'), 1);
}

// Control characters - width -1 or 0
void KonsoleWcwidthTest::testNullCharacter()
{
    QCOMPARE(konsole_wcwidth(L'\0'), 0);
}

void KonsoleWcwidthTest::testControlCharacters()
{
    // Control characters (0x01-0x1F except tab, newline, etc.)
    QCOMPARE(konsole_wcwidth(L'\x01'), -1);  // SOH
    QCOMPARE(konsole_wcwidth(L'\x02'), -1);  // STX
    QCOMPARE(konsole_wcwidth(L'\x1F'), -1);  // US
}

void KonsoleWcwidthTest::testDelete()
{
    QCOMPARE(konsole_wcwidth(L'\x7F'), -1);  // DEL
}

// Wide characters (CJK) - width 2
void KonsoleWcwidthTest::testChineseCharacter()
{
    QCOMPARE(konsole_wcwidth(L'\u4E2D'), 2);  // 中
    QCOMPARE(konsole_wcwidth(L'\u6587'), 2);  // 文
}

void KonsoleWcwidthTest::testJapaneseHiragana()
{
    QCOMPARE(konsole_wcwidth(L'\u3042'), 2);  // あ (a)
    QCOMPARE(konsole_wcwidth(L'\u3044'), 2);  // い (i)
}

void KonsoleWcwidthTest::testKoreanHangul()
{
    QCOMPARE(konsole_wcwidth(L'\uAC00'), 2);  // 가 (ga)
    QCOMPARE(konsole_wcwidth(L'\uD55C'), 2);  // 한 (han)
}

void KonsoleWcwidthTest::testFullWidthLatin()
{
    QCOMPARE(konsole_wcwidth(L'\uFF21'), 2);  // Ａ (fullwidth A)
    QCOMPARE(konsole_wcwidth(L'\uFF10'), 2);  // ０ (fullwidth 0)
}

// Special cases
void KonsoleWcwidthTest::testCombiningCharacters()
{
    // Combining diacritical marks - width 0
    QCOMPARE(konsole_wcwidth(L'\u0300'), 0);  // Combining grave accent
    QCOMPARE(konsole_wcwidth(L'\u0301'), 0);  // Combining acute accent
}

void KonsoleWcwidthTest::testZeroWidthCharacters()
{
    QCOMPARE(konsole_wcwidth(L'\u200B'), 0);  // Zero-width space
    // BOM (U+FEFF) returns -1 in this implementation (non-printable)
    QCOMPARE(konsole_wcwidth(L'\uFEFF'), -1);
}

// String width tests
void KonsoleWcwidthTest::testAsciiStringWidth()
{
    QCOMPARE(string_width(L"hello"), 5);
    QCOMPARE(string_width(L"test123"), 7);
}

void KonsoleWcwidthTest::testMixedStringWidth()
{
    // "hi中文" = 2 (hi) + 4 (中文, each width 2) = 6
    QCOMPARE(string_width(L"hi\u4E2D\u6587"), 6);
}

void KonsoleWcwidthTest::testEmptyStringWidth()
{
    QCOMPARE(string_width(L""), 0);
}
