#ifndef TST_KONSOLE_WCWIDTH_H
#define TST_KONSOLE_WCWIDTH_H

#include <QObject>

class KonsoleWcwidthTest : public QObject
{
    Q_OBJECT

private slots:
    // ASCII characters
    void testAsciiLetter();
    void testAsciiDigit();
    void testAsciiSpace();
    void testAsciiPunctuation();

    // Control characters
    void testNullCharacter();
    void testControlCharacters();
    void testDelete();

    // Wide characters (CJK)
    void testChineseCharacter();
    void testJapaneseHiragana();
    void testKoreanHangul();
    void testFullWidthLatin();

    // Special cases
    void testCombiningCharacters();
    void testZeroWidthCharacters();

    // String width
    void testAsciiStringWidth();
    void testMixedStringWidth();
    void testEmptyStringWidth();
};

#endif // TST_KONSOLE_WCWIDTH_H
