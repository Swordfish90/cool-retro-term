#ifndef _COLOR_TABLE_H
#define _COLOR_TABLE_H

#include "CharacterColor.h"

//using namespace Konsole;
#if 0
static const ColorEntry whiteonblack_color_table[TABLE_COLORS] = {
    // normal
    ColorEntry(QColor(0xFF,0xFF,0xFF), false ), ColorEntry( QColor(0x00,0x00,0x00), true ), // Dfore, Dback
    ColorEntry(QColor(0x00,0x00,0x00), false ), ColorEntry( QColor(0xB2,0x18,0x18), false ), // Black, Red
    ColorEntry(QColor(0x18,0xB2,0x18), false ), ColorEntry( QColor(0xB2,0x68,0x18), false ), // Green, Yellow
    ColorEntry(QColor(0x18,0x18,0xB2), false ), ColorEntry( QColor(0xB2,0x18,0xB2), false ), // Blue, Magenta
    ColorEntry(QColor(0x18,0xB2,0xB2), false ), ColorEntry( QColor(0xB2,0xB2,0xB2), false ), // Cyan, White
    // intensiv
    ColorEntry(QColor(0x00,0x00,0x00), false ), ColorEntry( QColor(0xFF,0xFF,0xFF), true ),
    ColorEntry(QColor(0x68,0x68,0x68), false ), ColorEntry( QColor(0xFF,0x54,0x54), false ),
    ColorEntry(QColor(0x54,0xFF,0x54), false ), ColorEntry( QColor(0xFF,0xFF,0x54), false ),
    ColorEntry(QColor(0x54,0x54,0xFF), false ), ColorEntry( QColor(0xFF,0x54,0xFF), false ),
    ColorEntry(QColor(0x54,0xFF,0xFF), false ), ColorEntry( QColor(0xFF,0xFF,0xFF), false )
};

static const ColorEntry greenonblack_color_table[TABLE_COLORS] = {
    ColorEntry(QColor(    24, 240,  24),  false), ColorEntry(QColor(     0,   0,   0),  true),
    ColorEntry(QColor(     0,   0,   0),  false), ColorEntry(QColor(   178,  24,  24),  false),
    ColorEntry(QColor(    24, 178,  24),  false), ColorEntry(QColor(   178, 104,  24),  false),
    ColorEntry(QColor(    24,  24, 178),  false), ColorEntry(QColor(   178,  24, 178),  false),
    ColorEntry(QColor(    24, 178, 178),  false), ColorEntry(QColor(   178, 178, 178),  false),
    // intensive colors
    ColorEntry(QColor(   24, 240,  24),  false ), ColorEntry(QColor(    0,   0,   0),  true ),
    ColorEntry(QColor(  104, 104, 104),  false ), ColorEntry(QColor(  255,  84,  84),  false ),
    ColorEntry(QColor(   84, 255,  84),  false ), ColorEntry(QColor(  255, 255,  84),  false ),
    ColorEntry(QColor(   84,  84, 255),  false ), ColorEntry(QColor(  255,  84, 255),  false ),
    ColorEntry(QColor(   84, 255, 255),  false ), ColorEntry(QColor(  255, 255, 255),  false )
};

static const ColorEntry blackonlightyellow_color_table[TABLE_COLORS] = {
    ColorEntry(QColor(  0,   0,   0),  false),  ColorEntry(QColor( 255, 255, 221),  true),
    ColorEntry(QColor(  0,   0,   0),  false),  ColorEntry(QColor( 178,  24,  24),  false),
    ColorEntry(QColor( 24, 178,  24),  false),  ColorEntry(QColor( 178, 104,  24),  false),
    ColorEntry(QColor( 24,  24, 178),  false),  ColorEntry(QColor( 178,  24, 178),  false),
    ColorEntry(QColor( 24, 178, 178),  false),  ColorEntry(QColor( 178, 178, 178),  false),
    ColorEntry(QColor(  0,   0,   0),  false),  ColorEntry(QColor( 255, 255, 221),  true),
    ColorEntry(QColor(104, 104, 104),  false),  ColorEntry(QColor( 255,  84,  84),  false),
    ColorEntry(QColor( 84, 255,  84),  false),  ColorEntry(QColor( 255, 255,  84),  false),
    ColorEntry(QColor( 84,  84, 255),  false),  ColorEntry(QColor( 255,  84, 255),  false),
    ColorEntry(QColor( 84, 255, 255),  false),  ColorEntry(QColor( 255, 255, 255),  false)
};


#endif


#endif

