#ifndef TST_CHARACTER_H
#define TST_CHARACTER_H

#include <QObject>

class CharacterTest : public QObject
{
    Q_OBJECT

private slots:
    // CharacterColor tests
    void testColorSpaceUndefined();
    void testColorSpaceDefault();
    void testColorSpaceSystem();
    void testColorSpace256();
    void testColorSpaceRGB();
    void testColorIsValid();
    void testColorEquality();
    void testColorInequality();
    void testSetIntensive();

    // Character tests
    void testDefaultCharacter();
    void testCharacterWithValues();
    void testCharacterEquality();
    void testCharacterInequality();
    void testCharacterEqualsFormat();
    void testRenditionFlags();
};

#endif // TST_CHARACTER_H
