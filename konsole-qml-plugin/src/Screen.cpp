/*
   This file is part of Konsole, an X terminal.

   Copyright 2007-2008 by Robert Knight <robert.knight@gmail.com>
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

// Own
#include "Screen.h"

// Standard
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>

// Qt
#include <QtCore/QTextStream>
#include <QtCore/QDate>

// KDE
//#include <kdebug.h>

// Konsole
#include "konsole_wcwidth.h"
#include "TerminalCharacterDecoder.h"



//FIXME: this is emulation specific. Use false for xterm, true for ANSI.
//FIXME: see if we can get this from terminfo.
#define BS_CLEARS false

//Macro to convert x,y position on screen to position within an image.
//
//Originally the image was stored as one large contiguous block of 
//memory, so a position within the image could be represented as an
//offset from the beginning of the block.  For efficiency reasons this
//is no longer the case.  
//Many internal parts of this class still use this representation for parameters and so on,
//notably moveImage() and clearImage().
//This macro converts from an X,Y position into an image offset.
#ifndef loc
#define loc(X,Y) ((Y)*columns+(X))
#endif


Character Screen::defaultChar = Character(' ',
        CharacterColor(COLOR_SPACE_DEFAULT,DEFAULT_FORE_COLOR),
        CharacterColor(COLOR_SPACE_DEFAULT,DEFAULT_BACK_COLOR),
        DEFAULT_RENDITION);

//#define REVERSE_WRAPPED_LINES  // for wrapped line debug

Screen::Screen(int l, int c)
    : lines(l),
    columns(c),
    screenLines(new ImageLine[lines+1] ),
    _scrolledLines(0),
    _droppedLines(0),
    history(new HistoryScrollNone()),
    cuX(0), cuY(0),
    currentRendition(0),
    _topMargin(0), _bottomMargin(0),
    selBegin(0), selTopLeft(0), selBottomRight(0),
    blockSelectionMode(false),
    effectiveForeground(CharacterColor()), effectiveBackground(CharacterColor()), effectiveRendition(0),
    lastPos(-1)
{
    lineProperties.resize(lines+1);
    for (int i=0;i<lines+1;i++)
        lineProperties[i]=LINE_DEFAULT;

    initTabStops();
    clearSelection();
    reset();
}

/*! Destructor
*/

Screen::~Screen()
{
    delete[] screenLines;
    delete history;
}

void Screen::cursorUp(int n)
    //=CUU
{
    if (n == 0) n = 1; // Default
    int stop = cuY < _topMargin ? 0 : _topMargin;
    cuX = qMin(columns-1,cuX); // nowrap!
    cuY = qMax(stop,cuY-n);
}

void Screen::cursorDown(int n)
    //=CUD
{
    if (n == 0) n = 1; // Default
    int stop = cuY > _bottomMargin ? lines-1 : _bottomMargin;
    cuX = qMin(columns-1,cuX); // nowrap!
    cuY = qMin(stop,cuY+n);
}

void Screen::cursorLeft(int n)
    //=CUB
{
    if (n == 0) n = 1; // Default
    cuX = qMin(columns-1,cuX); // nowrap!
    cuX = qMax(0,cuX-n);
}

void Screen::cursorRight(int n)
    //=CUF
{
    if (n == 0) n = 1; // Default
    cuX = qMin(columns-1,cuX+n);
}

void Screen::setMargins(int top, int bot)
    //=STBM
{
    if (top == 0) top = 1;      // Default
    if (bot == 0) bot = lines;  // Default
    top = top - 1;              // Adjust to internal lineno
    bot = bot - 1;              // Adjust to internal lineno
    if ( !( 0 <= top && top < bot && bot < lines ) )
    { //Debug()<<" setRegion("<<top<<","<<bot<<") : bad range.";
        return;                   // Default error action: ignore
    }
    _topMargin = top;
    _bottomMargin = bot;
    cuX = 0;
    cuY = getMode(MODE_Origin) ? top : 0;

}

int Screen::topMargin() const
{
    return _topMargin;
}
int Screen::bottomMargin() const
{
    return _bottomMargin;
}

void Screen::index()
    //=IND
{
    if (cuY == _bottomMargin)
        scrollUp(1);
    else if (cuY < lines-1)
        cuY += 1;
}

void Screen::reverseIndex()
    //=RI
{
    if (cuY == _topMargin)
        scrollDown(_topMargin,1);
    else if (cuY > 0)
        cuY -= 1;
}

void Screen::nextLine()
    //=NEL
{
    toStartOfLine(); index();
}

void Screen::eraseChars(int n)
{
    if (n == 0) n = 1; // Default
    int p = qMax(0,qMin(cuX+n-1,columns-1));
    clearImage(loc(cuX,cuY),loc(p,cuY),' ');
}

void Screen::deleteChars(int n)
{
    Q_ASSERT( n >= 0 );

    // always delete at least one char
    if (n == 0) 
        n = 1; 

    // if cursor is beyond the end of the line there is nothing to do
    if ( cuX >= screenLines[cuY].count() )
        return;

    if ( cuX+n > screenLines[cuY].count() ) 
        n = screenLines[cuY].count() - cuX;

    Q_ASSERT( n >= 0 );
    Q_ASSERT( cuX+n <= screenLines[cuY].count() );

    screenLines[cuY].remove(cuX,n);
}

void Screen::insertChars(int n)
{
    if (n == 0) n = 1; // Default

    if ( screenLines[cuY].size() < cuX )
        screenLines[cuY].resize(cuX);

    screenLines[cuY].insert(cuX,n,' ');

    if ( screenLines[cuY].count() > columns )
        screenLines[cuY].resize(columns);
}

void Screen::deleteLines(int n)
{
    if (n == 0) n = 1; // Default
    scrollUp(cuY,n);
}

void Screen::insertLines(int n)
{
    if (n == 0) n = 1; // Default
    scrollDown(cuY,n);
}

void Screen::setMode(int m)
{
    currentModes[m] = true;
    switch(m)
    {
        case MODE_Origin : cuX = 0; cuY = _topMargin; break; //FIXME: home
    }
}

void Screen::resetMode(int m)
{
    currentModes[m] = false;
    switch(m)
    {
        case MODE_Origin : cuX = 0; cuY = 0; break; //FIXME: home
    }
}

void Screen::saveMode(int m)
{
    savedModes[m] = currentModes[m];
}

void Screen::restoreMode(int m)
{
    currentModes[m] = savedModes[m];
}

bool Screen::getMode(int m) const
{
    return currentModes[m];
}

void Screen::saveCursor()
{
    savedState.cursorColumn = cuX;
    savedState.cursorLine  = cuY;
    savedState.rendition = currentRendition;
    savedState.foreground = currentForeground;
    savedState.background = currentBackground;
}

void Screen::restoreCursor()
{
    cuX     = qMin(savedState.cursorColumn,columns-1);
    cuY     = qMin(savedState.cursorLine,lines-1);
    currentRendition   = savedState.rendition; 
    currentForeground   = savedState.foreground;
    currentBackground   = savedState.background;
    updateEffectiveRendition();
}

void Screen::resizeImage(int new_lines, int new_columns)
{
    if ((new_lines==lines) && (new_columns==columns)) return;

    if (cuY > new_lines-1)
    { // attempt to preserve focus and lines
        _bottomMargin = lines-1; //FIXME: margin lost
        for (int i = 0; i < cuY-(new_lines-1); i++)
        {
            addHistLine(); scrollUp(0,1);
        }
    }

    // create new screen lines and copy from old to new

    ImageLine* newScreenLines = new ImageLine[new_lines+1];
    for (int i=0; i < qMin(lines-1,new_lines+1) ;i++)
        newScreenLines[i]=screenLines[i];
    for (int i=lines;(i > 0) && (i<new_lines+1);i++)
        newScreenLines[i].resize( new_columns );

    lineProperties.resize(new_lines+1);
    for (int i=lines;(i > 0) && (i<new_lines+1);i++)
        lineProperties[i] = LINE_DEFAULT;

    clearSelection();

    delete[] screenLines; 
    screenLines = newScreenLines;

    lines = new_lines;
    columns = new_columns;
    cuX = qMin(cuX,columns-1);
    cuY = qMin(cuY,lines-1);

    // FIXME: try to keep values, evtl.
    _topMargin=0;
    _bottomMargin=lines-1;
    initTabStops();
    clearSelection();
}

void Screen::setDefaultMargins()
{
    _topMargin = 0;
    _bottomMargin = lines-1;
}


/*
   Clarifying rendition here and in the display.

   currently, the display's color table is
   0       1       2 .. 9    10 .. 17
   dft_fg, dft_bg, dim 0..7, intensive 0..7

   currentForeground, currentBackground contain values 0..8;
   - 0    = default color
   - 1..8 = ansi specified color

   re_fg, re_bg contain values 0..17
   due to the TerminalDisplay's color table

   rendition attributes are

   attr           widget screen
   -------------- ------ ------
   RE_UNDERLINE     XX     XX    affects foreground only
   RE_BLINK         XX     XX    affects foreground only
   RE_BOLD          XX     XX    affects foreground only
   RE_REVERSE       --     XX
   RE_TRANSPARENT   XX     --    affects background only
   RE_INTENSIVE     XX     --    affects foreground only

   Note that RE_BOLD is used in both widget
   and screen rendition. Since xterm/vt102
   is to poor to distinguish between bold
   (which is a font attribute) and intensive
   (which is a color attribute), we translate
   this and RE_BOLD in falls eventually appart
   into RE_BOLD and RE_INTENSIVE.
   */

void Screen::reverseRendition(Character& p) const
{ 
    CharacterColor f = p.foregroundColor; 
    CharacterColor b = p.backgroundColor;

    p.foregroundColor = b; 
    p.backgroundColor = f; //p->r &= ~RE_TRANSPARENT;
}

void Screen::updateEffectiveRendition()
{
    effectiveRendition = currentRendition;
    if (currentRendition & RE_REVERSE)
    {
        effectiveForeground = currentBackground;
        effectiveBackground = currentForeground;
    }
    else
    {
        effectiveForeground = currentForeground;
        effectiveBackground = currentBackground;
    }

    if (currentRendition & RE_BOLD)
        effectiveForeground.toggleIntensive();
}

void Screen::copyFromHistory(Character* dest, int startLine, int count) const
{
    Q_ASSERT( startLine >= 0 && count > 0 && startLine + count <= history->getLines() );

    for (int line = startLine; line < startLine + count; line++) 
    {
        const int length = qMin(columns,history->getLineLen(line));
        const int destLineOffset  = (line-startLine)*columns;

        history->getCells(line,0,length,dest + destLineOffset);

        for (int column = length; column < columns; column++) 
            dest[destLineOffset+column] = defaultChar;

        // invert selected text
        if (selBegin !=-1)
        {
            for (int column = 0; column < columns; column++)
            {
                if (isSelected(column,line)) 
                {
                    reverseRendition(dest[destLineOffset + column]); 
                }
            }
        }
    }
}

void Screen::copyFromScreen(Character* dest , int startLine , int count) const
{
    Q_ASSERT( startLine >= 0 && count > 0 && startLine + count <= lines );

    for (int line = startLine; line < (startLine+count) ; line++)
    {
        int srcLineStartIndex  = line*columns;
        int destLineStartIndex = (line-startLine)*columns;

        for (int column = 0; column < columns; column++)
        { 
            int srcIndex = srcLineStartIndex + column; 
            int destIndex = destLineStartIndex + column;

            dest[destIndex] = screenLines[srcIndex/columns].value(srcIndex%columns,defaultChar);

            // invert selected text
            if (selBegin != -1 && isSelected(column,line + history->getLines()))
                reverseRendition(dest[destIndex]); 
        }

    }
}

void Screen::getImage( Character* dest, int size, int startLine, int endLine ) const
{
    Q_ASSERT( startLine >= 0 );
    Q_ASSERT( endLine >= startLine && endLine < history->getLines() + lines );

    const int mergedLines = endLine - startLine + 1;

    Q_ASSERT( size >= mergedLines * columns ); 
    Q_UNUSED( size );

    const int linesInHistoryBuffer = qBound(0,history->getLines()-startLine,mergedLines);
    const int linesInScreenBuffer = mergedLines - linesInHistoryBuffer;

    // copy lines from history buffer
    if (linesInHistoryBuffer > 0)
        copyFromHistory(dest,startLine,linesInHistoryBuffer); 

    // copy lines from screen buffer
    if (linesInScreenBuffer > 0)
        copyFromScreen(dest + linesInHistoryBuffer*columns,
                startLine + linesInHistoryBuffer - history->getLines(),
                linesInScreenBuffer);

    // invert display when in screen mode
    if (getMode(MODE_Screen))
    {
        for (int i = 0; i < mergedLines*columns; i++)
            reverseRendition(dest[i]); // for reverse display
    }

    // mark the character at the current cursor position
    int cursorIndex = loc(cuX, cuY + linesInHistoryBuffer);
    if(getMode(MODE_Cursor) && cursorIndex < columns*mergedLines)
        dest[cursorIndex].rendition |= RE_CURSOR;
}

QVector<LineProperty> Screen::getLineProperties( int startLine , int endLine ) const
{
    Q_ASSERT( startLine >= 0 ); 
    Q_ASSERT( endLine >= startLine && endLine < history->getLines() + lines );

    const int mergedLines = endLine-startLine+1;
    const int linesInHistory = qBound(0,history->getLines()-startLine,mergedLines);
    const int linesInScreen = mergedLines - linesInHistory;

    QVector<LineProperty> result(mergedLines);
    int index = 0;

    // copy properties for lines in history
    for (int line = startLine; line < startLine + linesInHistory; line++) 
    {
        //TODO Support for line properties other than wrapped lines
        if (history->isWrappedLine(line))
        {
            result[index] = (LineProperty)(result[index] | LINE_WRAPPED);
        }
        index++;
    }

    // copy properties for lines in screen buffer
    const int firstScreenLine = startLine + linesInHistory - history->getLines();
    for (int line = firstScreenLine; line < firstScreenLine+linesInScreen; line++)
    {
        result[index]=lineProperties[line];
        index++;
    }

    return result;
}

void Screen::reset(bool clearScreen)
{
    setMode(MODE_Wrap  ); saveMode(MODE_Wrap  );  // wrap at end of margin
    resetMode(MODE_Origin); saveMode(MODE_Origin);  // position refere to [1,1]
    resetMode(MODE_Insert); saveMode(MODE_Insert);  // overstroke
    setMode(MODE_Cursor);                         // cursor visible
    resetMode(MODE_Screen);                         // screen not inverse
    resetMode(MODE_NewLine);

    _topMargin=0;
    _bottomMargin=lines-1;

    setDefaultRendition();
    saveCursor();

    if ( clearScreen )
        clear();
}

void Screen::clear()
{
    clearEntireScreen();
    home();
}

void Screen::backspace()
{
    cuX = qMin(columns-1,cuX); // nowrap!
    cuX = qMax(0,cuX-1);

    if (screenLines[cuY].size() < cuX+1)
        screenLines[cuY].resize(cuX+1);

    if (BS_CLEARS) 
        screenLines[cuY][cuX].character = ' ';
}

void Screen::tab(int n)
{
    // note that TAB is a format effector (does not write ' ');
    if (n == 0) n = 1;
    while((n > 0) && (cuX < columns-1))
    {
        cursorRight(1); 
        while((cuX < columns-1) && !tabStops[cuX]) 
            cursorRight(1);
        n--;
    }
}

void Screen::backtab(int n)
{
    // note that TAB is a format effector (does not write ' ');
    if (n == 0) n = 1;
    while((n > 0) && (cuX > 0))
    {
        cursorLeft(1); while((cuX > 0) && !tabStops[cuX]) cursorLeft(1);
        n--;
    }
}

void Screen::clearTabStops()
{
    for (int i = 0; i < columns; i++) tabStops[i] = false;
}

void Screen::changeTabStop(bool set)
{
    if (cuX >= columns) return;
    tabStops[cuX] = set;
}

void Screen::initTabStops()
{
    tabStops.resize(columns);

    // Arrg! The 1st tabstop has to be one longer than the other.
    // i.e. the kids start counting from 0 instead of 1.
    // Other programs might behave correctly. Be aware.
    for (int i = 0; i < columns; i++) 
        tabStops[i] = (i%8 == 0 && i != 0);
}

void Screen::newLine()
{
    if (getMode(MODE_NewLine)) 
        toStartOfLine();
    index();
}

void Screen::checkSelection(int from, int to)
{
    if (selBegin == -1) 
        return;
    int scr_TL = loc(0, history->getLines());
    //Clear entire selection if it overlaps region [from, to]
    if ( (selBottomRight >= (from+scr_TL)) && (selTopLeft <= (to+scr_TL)) )
        clearSelection();
}

void Screen::displayCharacter(unsigned short c)
{
    // Note that VT100 does wrapping BEFORE putting the character.
    // This has impact on the assumption of valid cursor positions.
    // We indicate the fact that a newline has to be triggered by
    // putting the cursor one right to the last column of the screen.

    int w = konsole_wcwidth(c);
    if (w <= 0)
        return;

    if (cuX+w > columns) {
        if (getMode(MODE_Wrap)) {
            lineProperties[cuY] = (LineProperty)(lineProperties[cuY] | LINE_WRAPPED);
            nextLine();
        }
        else
            cuX = columns-w;
    }

    // ensure current line vector has enough elements
    int size = screenLines[cuY].size();
    if (size < cuX+w)
    {
        screenLines[cuY].resize(cuX+w);
    }

    if (getMode(MODE_Insert)) insertChars(w);

    lastPos = loc(cuX,cuY);

    // check if selection is still valid.
    checkSelection(lastPos, lastPos);

    Character& currentChar = screenLines[cuY][cuX];

    currentChar.character = c;
    currentChar.foregroundColor = effectiveForeground;
    currentChar.backgroundColor = effectiveBackground;
    currentChar.rendition = effectiveRendition;

    int i = 0;
    int newCursorX = cuX + w--;
    while(w)
    {
        i++;

        if ( screenLines[cuY].size() < cuX + i + 1 )
            screenLines[cuY].resize(cuX+i+1);

        Character& ch = screenLines[cuY][cuX + i];
        ch.character = 0;
        ch.foregroundColor = effectiveForeground;
        ch.backgroundColor = effectiveBackground;
        ch.rendition = effectiveRendition;

        w--;
    }
    cuX = newCursorX;
}

void Screen::compose(const QString& /*compose*/)
{
    Q_ASSERT( 0 /*Not implemented yet*/ );

    /*  if (lastPos == -1)
        return;

        QChar c(image[lastPos].character);
        compose.prepend(c);
    //compose.compose(); ### FIXME!
    image[lastPos].character = compose[0].unicode();*/
}

int Screen::scrolledLines() const
{
    return _scrolledLines;
}
int Screen::droppedLines() const
{
    return _droppedLines;
}
void Screen::resetDroppedLines()
{
    _droppedLines = 0;
}
void Screen::resetScrolledLines()
{
    _scrolledLines = 0;
}

void Screen::scrollUp(int n)
{
    if (n == 0) n = 1; // Default
    if (_topMargin == 0) addHistLine(); // history.history
    scrollUp(_topMargin, n);
}

QRect Screen::lastScrolledRegion() const
{
    return _lastScrolledRegion;
}

void Screen::scrollUp(int from, int n)
{
    if (n <= 0 || from + n > _bottomMargin) return;

    _scrolledLines -= n;
    _lastScrolledRegion = QRect(0,_topMargin,columns-1,(_bottomMargin-_topMargin));

    //FIXME: make sure `topMargin', `bottomMargin', `from', `n' is in bounds.
    moveImage(loc(0,from),loc(0,from+n),loc(columns-1,_bottomMargin));
    clearImage(loc(0,_bottomMargin-n+1),loc(columns-1,_bottomMargin),' ');
}

void Screen::scrollDown(int n)
{
    if (n == 0) n = 1; // Default
    scrollDown(_topMargin, n);
}

void Screen::scrollDown(int from, int n)
{
    _scrolledLines += n;

    //FIXME: make sure `topMargin', `bottomMargin', `from', `n' is in bounds.
    if (n <= 0) 
        return;
    if (from > _bottomMargin) 
        return;
    if (from + n > _bottomMargin) 
        n = _bottomMargin - from;
    moveImage(loc(0,from+n),loc(0,from),loc(columns-1,_bottomMargin-n));
    clearImage(loc(0,from),loc(columns-1,from+n-1),' ');
}

void Screen::setCursorYX(int y, int x)
{
    setCursorY(y); setCursorX(x);
}

void Screen::setCursorX(int x)
{
    if (x == 0) x = 1; // Default
    x -= 1; // Adjust
    cuX = qMax(0,qMin(columns-1, x));
}

void Screen::setCursorY(int y)
{
    if (y == 0) y = 1; // Default
    y -= 1; // Adjust
    cuY = qMax(0,qMin(lines  -1, y + (getMode(MODE_Origin) ? _topMargin : 0) ));
}

void Screen::home()
{
    cuX = 0;
    cuY = 0;
}

void Screen::toStartOfLine()
{
    cuX = 0;
}

int Screen::getCursorX() const
{
    return cuX;
}

int Screen::getCursorY() const
{
    return cuY;
}

void Screen::clearImage(int loca, int loce, char c)
{ 
    int scr_TL=loc(0,history->getLines());
    //FIXME: check positions

    //Clear entire selection if it overlaps region to be moved...
    if ( (selBottomRight > (loca+scr_TL) )&&(selTopLeft < (loce+scr_TL)) )
    {
        clearSelection();
    }

    int topLine = loca/columns;
    int bottomLine = loce/columns;

    Character clearCh(c,currentForeground,currentBackground,DEFAULT_RENDITION);

    //if the character being used to clear the area is the same as the
    //default character, the affected lines can simply be shrunk.
    bool isDefaultCh = (clearCh == Character());

    for (int y=topLine;y<=bottomLine;y++)
    {
        lineProperties[y] = 0;

        int endCol = ( y == bottomLine) ? loce%columns : columns-1;
        int startCol = ( y == topLine ) ? loca%columns : 0;

        QVector<Character>& line = screenLines[y];

        if ( isDefaultCh && endCol == columns-1 )
        {
            line.resize(startCol);
        }
        else
        {
            if (line.size() < endCol + 1)
                line.resize(endCol+1);

            Character* data = line.data();
            for (int i=startCol;i<=endCol;i++)
                data[i]=clearCh;
        }
    }
}

void Screen::moveImage(int dest, int sourceBegin, int sourceEnd)
{
    Q_ASSERT( sourceBegin <= sourceEnd );

    int lines=(sourceEnd-sourceBegin)/columns;

    //move screen image and line properties:
    //the source and destination areas of the image may overlap, 
    //so it matters that we do the copy in the right order - 
    //forwards if dest < sourceBegin or backwards otherwise.
    //(search the web for 'memmove implementation' for details)
    if (dest < sourceBegin)
    {
        for (int i=0;i<=lines;i++)
        {
            screenLines[ (dest/columns)+i ] = screenLines[ (sourceBegin/columns)+i ];
            lineProperties[(dest/columns)+i]=lineProperties[(sourceBegin/columns)+i];
        }
    }
    else
    {
        for (int i=lines;i>=0;i--)
        {
            screenLines[ (dest/columns)+i ] = screenLines[ (sourceBegin/columns)+i ];
            lineProperties[(dest/columns)+i]=lineProperties[(sourceBegin/columns)+i];
        }
    }

    if (lastPos != -1)
    {
        int diff = dest - sourceBegin; // Scroll by this amount
        lastPos += diff;
        if ((lastPos < 0) || (lastPos >= (lines*columns)))
            lastPos = -1;
    }

    // Adjust selection to follow scroll.
    if (selBegin != -1)
    {
        bool beginIsTL = (selBegin == selTopLeft);
        int diff = dest - sourceBegin; // Scroll by this amount
        int scr_TL=loc(0,history->getLines());
        int srca = sourceBegin+scr_TL; // Translate index from screen to global
        int srce = sourceEnd+scr_TL; // Translate index from screen to global
        int desta = srca+diff;
        int deste = srce+diff;

        if ((selTopLeft >= srca) && (selTopLeft <= srce))
            selTopLeft += diff;
        else if ((selTopLeft >= desta) && (selTopLeft <= deste))
            selBottomRight = -1; // Clear selection (see below)

        if ((selBottomRight >= srca) && (selBottomRight <= srce))
            selBottomRight += diff;
        else if ((selBottomRight >= desta) && (selBottomRight <= deste))
            selBottomRight = -1; // Clear selection (see below)

        if (selBottomRight < 0)
        {
            clearSelection();
        }
        else
        {
            if (selTopLeft < 0)
                selTopLeft = 0;
        }

        if (beginIsTL)
            selBegin = selTopLeft;
        else
            selBegin = selBottomRight;
    }
}

void Screen::clearToEndOfScreen()
{
    clearImage(loc(cuX,cuY),loc(columns-1,lines-1),' ');
}

void Screen::clearToBeginOfScreen()
{
    clearImage(loc(0,0),loc(cuX,cuY),' ');
}

void Screen::clearEntireScreen()
{
    // Add entire screen to history
    for (int i = 0; i < (lines-1); i++)
    {
        addHistLine(); scrollUp(0,1);
    }

    clearImage(loc(0,0),loc(columns-1,lines-1),' ');
}

/*! fill screen with 'E'
  This is to aid screen alignment
  */

void Screen::helpAlign()
{
    clearImage(loc(0,0),loc(columns-1,lines-1),'E');
}

void Screen::clearToEndOfLine()
{
    clearImage(loc(cuX,cuY),loc(columns-1,cuY),' ');
}

void Screen::clearToBeginOfLine()
{
    clearImage(loc(0,cuY),loc(cuX,cuY),' ');
}

void Screen::clearEntireLine()
{
    clearImage(loc(0,cuY),loc(columns-1,cuY),' ');
}

void Screen::setRendition(int re)
{
    currentRendition |= re;
    updateEffectiveRendition();
}

void Screen::resetRendition(int re)
{
    currentRendition &= ~re;
    updateEffectiveRendition();
}

void Screen::setDefaultRendition()
{
    setForeColor(COLOR_SPACE_DEFAULT,DEFAULT_FORE_COLOR);
    setBackColor(COLOR_SPACE_DEFAULT,DEFAULT_BACK_COLOR);
    currentRendition   = DEFAULT_RENDITION;
    updateEffectiveRendition();
}

void Screen::setForeColor(int space, int color)
{
    currentForeground = CharacterColor(space, color);

    if ( currentForeground.isValid() ) 
        updateEffectiveRendition();
    else 
        setForeColor(COLOR_SPACE_DEFAULT,DEFAULT_FORE_COLOR);
}

void Screen::setBackColor(int space, int color)
{
    currentBackground = CharacterColor(space, color);

    if ( currentBackground.isValid() ) 
        updateEffectiveRendition();
    else
        setBackColor(COLOR_SPACE_DEFAULT,DEFAULT_BACK_COLOR);
}

void Screen::clearSelection() 
{
    selBottomRight = -1;
    selTopLeft = -1;
    selBegin = -1;
}

void Screen::getSelectionStart(int& column , int& line) const
{
    if ( selTopLeft != -1 )
    {
        column = selTopLeft % columns;
        line = selTopLeft / columns; 
    }
    else
    {
        column = cuX + getHistLines();
        line = cuY + getHistLines();
    }
}
void Screen::getSelectionEnd(int& column , int& line) const
{
    if ( selBottomRight != -1 )
    {
        column = selBottomRight % columns;
        line = selBottomRight / columns;
    }
    else
    {
        column = cuX + getHistLines();
        line = cuY + getHistLines();
    } 
}
void Screen::setSelectionStart(const int x, const int y, const bool mode)
{
    selBegin = loc(x,y); 
    /* FIXME, HACK to correct for x too far to the right... */
    if (x == columns) selBegin--;

    selBottomRight = selBegin;
    selTopLeft = selBegin;
    blockSelectionMode = mode;
}

void Screen::setSelectionEnd( const int x, const int y)
{
    if (selBegin == -1) 
        return;

    int endPos =  loc(x,y); 

    if (endPos < selBegin)
    {
        selTopLeft = endPos;
        selBottomRight = selBegin;
    }
    else
    {
        /* FIXME, HACK to correct for x too far to the right... */
        if (x == columns) 
            endPos--;

        selTopLeft = selBegin;
        selBottomRight = endPos;
    }

    // Normalize the selection in column mode
    if (blockSelectionMode)
    {
        int topRow = selTopLeft / columns;
        int topColumn = selTopLeft % columns;
        int bottomRow = selBottomRight / columns;
        int bottomColumn = selBottomRight % columns;

        selTopLeft = loc(qMin(topColumn,bottomColumn),topRow);
        selBottomRight = loc(qMax(topColumn,bottomColumn),bottomRow);
    }
}

bool Screen::isSelected( const int x,const int y) const
{
    bool columnInSelection = true;
    if (blockSelectionMode)
    {
        columnInSelection = x >= (selTopLeft % columns) &&
            x <= (selBottomRight % columns);
    }

    int pos = loc(x,y);
    return pos >= selTopLeft && pos <= selBottomRight && columnInSelection;
}

QString Screen::selectedText(bool preserveLineBreaks) const
{
    QString result;
    QTextStream stream(&result, QIODevice::ReadWrite);

    PlainTextDecoder decoder;
    decoder.begin(&stream);
    writeSelectionToStream(&decoder , preserveLineBreaks);
    decoder.end();

    return result;
}

bool Screen::isSelectionValid() const
{
    return selTopLeft >= 0 && selBottomRight >= 0;
}

void Screen::writeSelectionToStream(TerminalCharacterDecoder* decoder , 
        bool preserveLineBreaks) const
{
    if (!isSelectionValid())
        return;
    writeToStream(decoder,selTopLeft,selBottomRight,preserveLineBreaks);
}

void Screen::writeToStream(TerminalCharacterDecoder* decoder, 
        int startIndex, int endIndex,
        bool preserveLineBreaks) const
{
    int top = startIndex / columns;    
    int left = startIndex % columns;

    int bottom = endIndex / columns;
    int right = endIndex % columns;

    Q_ASSERT( top >= 0 && left >= 0 && bottom >= 0 && right >= 0 );

    for (int y=top;y<=bottom;y++)
    {
        int start = 0;
        if ( y == top || blockSelectionMode ) start = left;

        int count = -1;
        if ( y == bottom || blockSelectionMode ) count = right - start + 1;

        const bool appendNewLine = ( y != bottom );
        int copied = copyLineToStream( y,
                start,
                count,
                decoder, 
                appendNewLine,
                preserveLineBreaks );

        // if the selection goes beyond the end of the last line then
        // append a new line character.
        //
        // this makes it possible to 'select' a trailing new line character after
        // the text on a line.  
        if ( y == bottom && 
                copied < count    )
        {
            Character newLineChar('\n');
            decoder->decodeLine(&newLineChar,1,0);
        }
    }    
}

int Screen::copyLineToStream(int line , 
        int start, 
        int count,
        TerminalCharacterDecoder* decoder,
        bool appendNewLine,
        bool preserveLineBreaks) const
{
    //buffer to hold characters for decoding
    //the buffer is static to avoid initialising every 
    //element on each call to copyLineToStream
    //(which is unnecessary since all elements will be overwritten anyway)
    static const int MAX_CHARS = 1024;
    static Character characterBuffer[MAX_CHARS];

    assert( count < MAX_CHARS );

    LineProperty currentLineProperties = 0;

    //determine if the line is in the history buffer or the screen image
    if (line < history->getLines())
    {
        const int lineLength = history->getLineLen(line);

        // ensure that start position is before end of line
        start = qMin(start,qMax(0,lineLength-1));

        // retrieve line from history buffer.  It is assumed
        // that the history buffer does not store trailing white space
        // at the end of the line, so it does not need to be trimmed here 
        if (count == -1)
        {
            count = lineLength-start;
        }
        else
        {
            count = qMin(start+count,lineLength)-start;
        }

        // safety checks
        assert( start >= 0 );
        assert( count >= 0 );    
        assert( (start+count) <= history->getLineLen(line) );

        history->getCells(line,start,count,characterBuffer);

        if ( history->isWrappedLine(line) )
            currentLineProperties |= LINE_WRAPPED;
    }
    else
    {
        if ( count == -1 )
            count = columns - start;

        assert( count >= 0 );

        const int screenLine = line-history->getLines();

        Character* data = screenLines[screenLine].data();
        int length = screenLines[screenLine].count();

        //retrieve line from screen image
        for (int i=start;i < qMin(start+count,length);i++)
        {
            characterBuffer[i-start] = data[i];
        }

        // count cannot be any greater than length
        count = qBound(0,count,length-start);

        Q_ASSERT( screenLine < lineProperties.count() );
        currentLineProperties |= lineProperties[screenLine]; 
    }

    // add new line character at end
    const bool omitLineBreak = (currentLineProperties & LINE_WRAPPED) ||
        !preserveLineBreaks;

    if ( !omitLineBreak && appendNewLine && (count+1 < MAX_CHARS) )
    {
        characterBuffer[count] = '\n';
        count++;
    }

    //decode line and write to text stream    
    decoder->decodeLine( (Character*) characterBuffer , 
            count, currentLineProperties );

    return count;
}

void Screen::writeLinesToStream(TerminalCharacterDecoder* decoder, int fromLine, int toLine) const
{
    writeToStream(decoder,loc(0,fromLine),loc(columns-1,toLine));
}

void Screen::addHistLine()
{
    // add line to history buffer
    // we have to take care about scrolling, too...

    if (hasScroll())
    {
        int oldHistLines = history->getLines();

        history->addCellsVector(screenLines[0]);
        history->addLine( lineProperties[0] & LINE_WRAPPED );

        int newHistLines = history->getLines();

        bool beginIsTL = (selBegin == selTopLeft);

        // If the history is full, increment the count
        // of dropped lines
        if ( newHistLines == oldHistLines )
            _droppedLines++;

        // Adjust selection for the new point of reference
        if (newHistLines > oldHistLines)
        {
            if (selBegin != -1)
            {
                selTopLeft += columns;
                selBottomRight += columns;
            }
        }

        if (selBegin != -1)
        {
            // Scroll selection in history up
            int top_BR = loc(0, 1+newHistLines);

            if (selTopLeft < top_BR)
                selTopLeft -= columns;

            if (selBottomRight < top_BR)
                selBottomRight -= columns;

            if (selBottomRight < 0)
                clearSelection();
            else
            {
                if (selTopLeft < 0)
                    selTopLeft = 0;
            }

            if (beginIsTL)
                selBegin = selTopLeft;
            else
                selBegin = selBottomRight;
        }
    }

}

int Screen::getHistLines() const
{
    return history->getLines();
}

void Screen::setScroll(const HistoryType& t , bool copyPreviousScroll)
{
    clearSelection();

    if ( copyPreviousScroll )
        history = t.scroll(history);
    else
    {
        HistoryScroll* oldScroll = history;
        history = t.scroll(0);
        delete oldScroll;
    }
}

bool Screen::hasScroll() const
{
    return history->hasScroll();
}

const HistoryType& Screen::getScroll() const
{
    return history->getType();
}

void Screen::setLineProperty(LineProperty property , bool enable)
{
    if ( enable )
        lineProperties[cuY] = (LineProperty)(lineProperties[cuY] | property);
    else
        lineProperties[cuY] = (LineProperty)(lineProperties[cuY] & ~property);
}
void Screen::fillWithDefaultChar(Character* dest, int count)
{
    for (int i=0;i<count;i++)
        dest[i] = defaultChar;
}
