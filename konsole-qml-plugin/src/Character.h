/*
    This file is part of Konsole, KDE's terminal.
    
    Copyright 2007-2008 by Robert Knight <robertknight@gmail.com>
    Copyright 1997,1998 by Lars Doelle <lars.doelle@on-line.de>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA.
*/

#ifndef CHARACTER_H
#define CHARACTER_H

// Qt
#include <QtCore/QHash>

// Local
#include "CharacterColor.h"

typedef unsigned char LineProperty;

static const int LINE_DEFAULT        = 0;
static const int LINE_WRAPPED          = (1 << 0);
static const int LINE_DOUBLEWIDTH      = (1 << 1);
static const int LINE_DOUBLEHEIGHT    = (1 << 2);

#define DEFAULT_RENDITION  0
#define RE_BOLD            (1 << 0)
#define RE_BLINK           (1 << 1)
#define RE_UNDERLINE       (1 << 2)
#define RE_REVERSE         (1 << 3) // Screen only
#define RE_INTENSIVE       (1 << 3) // Widget only
#define RE_CURSOR          (1 << 4)
#define RE_EXTENDED_CHAR   (1 << 5)

/**
 * A single character in the terminal which consists of a unicode character
 * value, foreground and background colors and a set of rendition attributes
 * which specify how it should be drawn.
 */
class Character
{
public:
  /** 
   * Constructs a new character.
   *
   * @param _c The unicode character value of this character.
   * @param _f The foreground color used to draw the character.
   * @param _b The color used to draw the character's background.
   * @param _r A set of rendition flags which specify how this character is to be drawn.
   */
  inline Character(quint16 _c = ' ',
            CharacterColor  _f = CharacterColor(COLOR_SPACE_DEFAULT,DEFAULT_FORE_COLOR),
            CharacterColor  _b = CharacterColor(COLOR_SPACE_DEFAULT,DEFAULT_BACK_COLOR),
            quint8  _r = DEFAULT_RENDITION)
       : character(_c), rendition(_r), foregroundColor(_f), backgroundColor(_b) {}

  union
  {
    /** The unicode character value for this character. */
    quint16 character;
    /** 
     * Experimental addition which allows a single Character instance to contain more than
     * one unicode character.
     *
     * charSequence is a hash code which can be used to look up the unicode
     * character sequence in the ExtendedCharTable used to create the sequence.
     */
    quint16 charSequence; 
  };

  /** A combination of RENDITION flags which specify options for drawing the character. */
  quint8  rendition;

  /** The foreground color used to draw this character. */
  CharacterColor  foregroundColor; 
  /** The color used to draw this character's background. */
  CharacterColor  backgroundColor;

  /** 
   * Returns true if this character has a transparent background when
   * it is drawn with the specified @p palette.
   */
  bool   isTransparent(const ColorEntry* palette) const;
  /**
   * Returns true if this character should always be drawn in bold when
   * it is drawn with the specified @p palette, independent of whether
   * or not the character has the RE_BOLD rendition flag. 
   */
  ColorEntry::FontWeight fontWeight(const ColorEntry* base) const;
  
  /** 
   * returns true if the format (color, rendition flag) of the compared characters is equal
   */
  bool equalsFormat(const Character &other) const;

  /** 
   * Compares two characters and returns true if they have the same unicode character value,
   * rendition and colors.
   */
  friend bool operator == (const Character& a, const Character& b);
  /**
   * Compares two characters and returns true if they have different unicode character values,
   * renditions or colors.
   */
  friend bool operator != (const Character& a, const Character& b);
};

inline bool operator == (const Character& a, const Character& b)
{ 
  return a.character == b.character && 
         a.rendition == b.rendition && 
         a.foregroundColor == b.foregroundColor && 
         a.backgroundColor == b.backgroundColor;
}

inline bool operator != (const Character& a, const Character& b)
{
  return    a.character != b.character || 
            a.rendition != b.rendition || 
            a.foregroundColor != b.foregroundColor || 
            a.backgroundColor != b.backgroundColor;
}

inline bool Character::isTransparent(const ColorEntry* base) const
{
  return ((backgroundColor._colorSpace == COLOR_SPACE_DEFAULT) && 
          base[backgroundColor._u+0+(backgroundColor._v?BASE_COLORS:0)].transparent)
      || ((backgroundColor._colorSpace == COLOR_SPACE_SYSTEM) && 
          base[backgroundColor._u+2+(backgroundColor._v?BASE_COLORS:0)].transparent);
}

inline bool Character::equalsFormat(const Character& other) const
{
  return 
    backgroundColor==other.backgroundColor &&
    foregroundColor==other.foregroundColor &&
    rendition==other.rendition;
}	

inline ColorEntry::FontWeight Character::fontWeight(const ColorEntry* base) const
{
    if (backgroundColor._colorSpace == COLOR_SPACE_DEFAULT)
        return base[backgroundColor._u+0+(backgroundColor._v?BASE_COLORS:0)].fontWeight;
    else if (backgroundColor._colorSpace == COLOR_SPACE_SYSTEM)
        return base[backgroundColor._u+2+(backgroundColor._v?BASE_COLORS:0)].fontWeight;
    else
        return ColorEntry::UseCurrentFormat;
}

extern unsigned short vt100_graphics[32];


/**
 * A table which stores sequences of unicode characters, referenced
 * by hash keys.  The hash key itself is the same size as a unicode
 * character ( ushort ) so that it can occupy the same space in
 * a structure.
 */
class ExtendedCharTable
{
public:
    /** Constructs a new character table. */
    ExtendedCharTable();
    ~ExtendedCharTable();

    /**
     * Adds a sequences of unicode characters to the table and returns
     * a hash code which can be used later to look up the sequence
     * using lookupExtendedChar()
     *
     * If the same sequence already exists in the table, the hash
     * of the existing sequence will be returned.
     *
     * @param unicodePoints An array of unicode character points
     * @param length Length of @p unicodePoints
     */
    ushort createExtendedChar(ushort* unicodePoints , ushort length);
    /**
     * Looks up and returns a pointer to a sequence of unicode characters
     * which was added to the table using createExtendedChar().
     *
     * @param hash The hash key returned by createExtendedChar()
     * @param length This variable is set to the length of the 
     * character sequence.
     *
     * @return A unicode character sequence of size @p length.
     */
    ushort* lookupExtendedChar(ushort hash , ushort& length) const;

    /** The global ExtendedCharTable instance. */
    static ExtendedCharTable instance;
private:
    // calculates the hash key of a sequence of unicode points of size 'length'
    ushort extendedCharHash(ushort* unicodePoints , ushort length) const;
    // tests whether the entry in the table specified by 'hash' matches the 
    // character sequence 'unicodePoints' of size 'length'
    bool extendedCharMatch(ushort hash , ushort* unicodePoints , ushort length) const;
    // internal, maps hash keys to character sequence buffers.  The first ushort
    // in each value is the length of the buffer, followed by the ushorts in the buffer
    // themselves.
    QHash<ushort,ushort*> extendedCharTable;
};


Q_DECLARE_TYPEINFO(Character, Q_MOVABLE_TYPE);

#endif // CHARACTER_H

