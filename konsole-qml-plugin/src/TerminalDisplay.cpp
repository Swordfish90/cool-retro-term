/*
    This file is part of KTerminal, QML plugin of the Konsole,
    which is a terminal emulator from KDE.

    Copyright 2006-2008 by Robert Knight   <robertknight@gmail.com>
    Copyright 1997,1998 by Lars Doelle     <lars.doelle@on-line.de>

    Rewritten for QT5/QML by Dmitry Zagnoyko   <hiroshidi@gmail.com>, Copyright (C) 2013

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
#include "TerminalDisplay.h"

// Qt
#include <QtQuick/QtQuick>

#include <QGuiApplication>
#include <QStyleHints>
#include <QInputMethod>

#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QClipboard>
#include <QtGui/QKeyEvent>

#include <QtCore/QEvent>
#include <QtCore/QTime>
#include <QtCore/QFile>
#include <QtCore/QTimer>

#include <QtDebug>
#include <QUrl>

// Konsole
//#include <config-apps.h>
#include "Filter.h"
#include "konsole_wcwidth.h"
#include "ScreenWindow.h"
#include "ColorScheme.h"
#include "ColorTables.h"
#include "TerminalCharacterDecoder.h"


#ifndef loc
#define loc(X,Y) ((Y)*_columns+(X))
#endif

#define REPCHAR   "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
    "abcdefgjijklmnopqrstuvwxyz" \
    "0123456789./+@"

const ColorEntry base_color_table[TABLE_COLORS] =
        // The following are almost IBM standard color codes, with some slight
        // gamma correction for the dim colors to compensate for bright X screens.
        // It contains the 8 ansiterm/xterm colors in 2 intensities.
{
        // Fixme: could add faint colors here, also.
        // normal
        ColorEntry(QColor(0x00,0x00,0x00), 0), ColorEntry( QColor(0xB2,0xB2,0xB2), 1), // Dfore, Dback
        ColorEntry(QColor(0x00,0x00,0x00), 0), ColorEntry( QColor(0xB2,0x18,0x18), 0), // Black, Red
        ColorEntry(QColor(0x18,0xB2,0x18), 0), ColorEntry( QColor(0xB2,0x68,0x18), 0), // Green, Yellow
        ColorEntry(QColor(0x18,0x18,0xB2), 0), ColorEntry( QColor(0xB2,0x18,0xB2), 0), // Blue, Magenta
        ColorEntry(QColor(0x18,0xB2,0xB2), 0), ColorEntry( QColor(0xB2,0xB2,0xB2), 0), // Cyan, White
        // intensiv
        ColorEntry(QColor(0x00,0x00,0x00), 0), ColorEntry( QColor(0xFF,0xFF,0xFF), 1),
        ColorEntry(QColor(0x68,0x68,0x68), 0), ColorEntry( QColor(0xFF,0x54,0x54), 0),
        ColorEntry(QColor(0x54,0xFF,0x54), 0), ColorEntry( QColor(0xFF,0xFF,0x54), 0),
        ColorEntry(QColor(0x54,0x54,0xFF), 0), ColorEntry( QColor(0xFF,0x54,0xFF), 0),
        ColorEntry(QColor(0x54,0xFF,0xFF), 0), ColorEntry( QColor(0xFF,0xFF,0xFF), 0)
        };

// scroll increment used when dragging selection at top/bottom of window.

// static
bool KTerminalDisplay::_antialiasText = true;
bool KTerminalDisplay::HAVE_TRANSPARENCY = true;

// we use this to force QPainter to display text in LTR mode
// more information can be found in: http://unicode.org/reports/tr9/
const QChar LTR_OVERRIDE_CHAR( 0x202D );

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Colors                                     */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/* Note that we use ANSI color order (bgr), while IBMPC color order is (rgb)

   Code        0       1       2       3       4       5       6       7
   ----------- ------- ------- ------- ------- ------- ------- ------- -------
   ANSI  (bgr) Black   Red     Green   Yellow  Blue    Magenta Cyan    White
   IBMPC (rgb) Black   Blue    Green   Cyan    Red     Magenta Yellow  White
*/



/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
///                                   BEGIN
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                         Constructor / Destructor                          */
/*                                                                           */
/* ------------------------------------------------------------------------- */
KTerminalDisplay::KTerminalDisplay(QQuickItem *parent) :
    QQuickPaintedItem(parent)
  ,_screenWindow(0)
  ,_allowBell(true)
  ,_fontHeight(1)
  ,_fontWidth(1)
  ,_fontAscent(1)
  ,_boldIntense(false)
  ,_lines(1)
  ,_columns(1)
  ,_usedLines(1)
  ,_usedColumns(1)
  ,_contentHeight(1)
  ,_contentWidth(1)
  ,_image(0)
  ,_randomSeed(0)
  ,_resizing(false)
  ,_bidiEnabled(false)
  ,_actSel(0)
  ,_wordSelectionMode(false)
  ,_lineSelectionMode(false)
  ,_preserveLineBreaks(false)
  ,_columnSelectionMode(false)
  ,_wordCharacters(":@-./_~")
  ,_bellMode(NotifyBell) //def: SystemBeepBell)
  ,_blinking(false)
  ,_hasBlinker(false)
  ,_cursorBlinking(false)
  ,_hasBlinkingCursor(false)
  ,_allowBlinkingText(true)
  ,_isFixedSize(false)
  ,_resizeTimer(0)
  ,_flowControlWarningEnabled(false)
  ,_lineSpacing(2)
  ,_colorsInverted(false)
  ,_cursorShape(BlockCursor)
  ,_mouseMarks(false)
  ,m_session(0)
  ,m_focusOnClick(true)
  ,m_showVKBonClick(true)
  ,m_parent(parent)
{
    _blendColor  = qRgba(0,0,0,0xff);
    m_widgetRect = QRectF(0,0,1,1);

    m_palette = qApp->palette();

    m_font = QFont("Monospace",16);

#ifdef Q_WS_UBUNTU
#if QT_VERSION >= 0x040700
    m_font.setStyleStrategy(QFont::ForceIntegerMetrics);
#else
#warning "Correct handling of the QFont metrics requited Qt>=4.7"
#endif
#endif

    // The offsets are not yet calculated.
    // Do not calculate these too often to be more smoothly when resizing
    // konsole in opaque mode.
    _topMargin = DEFAULT_TOP_MARGIN;
    _leftMargin = DEFAULT_LEFT_MARGIN;

    // setup timers for blinking cursor and text
    _blinkTimer   = new QTimer(this);
    connect(_blinkTimer, SIGNAL(timeout()), this, SLOT(blinkEvent()));
    _blinkCursorTimer   = new QTimer(this);
    connect(_blinkCursorTimer, SIGNAL(timeout()), this, SLOT(blinkCursorEvent()));

    //KCursor::setAutoHideCursor( this, true );

    setColorTable(base_color_table);

    setRenderTarget(QQuickPaintedItem::FramebufferObject);

    //new AutoScrollHandler(this);

    setAcceptedMouseButtons(Qt::LeftButton);
    setFlags(ItemHasContents | ItemAcceptsInputMethod);
    //installEventFilter(this);

    setVTFont(m_font);
}

KTerminalDisplay::~KTerminalDisplay()
{
    disconnect(_blinkTimer);
    disconnect(_blinkCursorTimer);

    delete[] _image;
}

void KTerminalDisplay::setSession(KSession * session)
{
    if (m_session != session) {
        m_session = session;

        connect(this, SIGNAL(copyAvailable(bool)),
                m_session, SLOT(selectionChanged(bool)));
        connect(this, SIGNAL(termGetFocus()),
                m_session, SIGNAL(termGetFocus()));
        connect(this, SIGNAL(termLostFocus()),
                m_session, SIGNAL(termLostFocus()));
        connect(this, SIGNAL(keyPressedSignal(QKeyEvent *)),
                m_session, SIGNAL(termKeyPressed(QKeyEvent *)));

        m_session->addView(this);

        //m_session->changeDir(QDir::currentPath());

        setRandomSeed(m_session->getRandomSeed());

        emit changedSession(session);
    }
}


ScreenWindow* KTerminalDisplay::screenWindow() const
{
    return _screenWindow;
}

void KTerminalDisplay::forcedFocus()
{

    bool focused = hasActiveFocus();

    if (!focused) {
        forceActiveFocus();
        focused = hasActiveFocus();
    }

}

void KTerminalDisplay::setScreenWindow(ScreenWindow* window)
{
    // disconnect existing screen window if any
    if ( _screenWindow )
    {
        disconnect( _screenWindow , 0 , this , 0 );
    }

    _screenWindow = window;

    if ( window )
    {

        // TODO: Determine if this is an issue.
        //#warning "The order here is not specified - does it matter whether updateImage or updateLineProperties comes first?"
        connect( _screenWindow , SIGNAL(outputChanged()) , this , SLOT(updateLineProperties()) );
        connect( _screenWindow , SIGNAL(outputChanged()) , this , SLOT(updateImage()) );
        window->setWindowLines(_lines);
    }
}

const ColorEntry* KTerminalDisplay::colorTable() const
{
    return _colorTable;
}
void KTerminalDisplay::setBackgroundColor(const QColor& color)
{
    _colorTable[DEFAULT_BACK_COLOR].color = color;
    //    QPalette p = m_palette;
    //    p.setColor( backgroundRole(), color );
    //    setPalette( p );

    update();
}
void KTerminalDisplay::setForegroundColor(const QColor& color)
{
    _colorTable[DEFAULT_FORE_COLOR].color = color;

    update();
}
void KTerminalDisplay::setColorTable(const ColorEntry table[])
{
    for (int i = 0; i < TABLE_COLORS; i++)
        _colorTable[i] = table[i];

    setBackgroundColor(_colorTable[DEFAULT_BACK_COLOR].color);
}


/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                   Font                                    */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/*
   The VT100 has 32 special graphical characters. The usual vt100 extended
   xterm fonts have these at 0x00..0x1f.

   QT's iso mapping leaves 0x00..0x7f without any changes. But the graphicals
   come in here as proper unicode characters.

   We treat non-iso10646 fonts as VT100 extended and do the requiered mapping
   from unicode to 0x00..0x1f. The remaining translation is then left to the
   QCodec.
*/

static inline bool isLineChar(quint16 c) { return ((c & 0xFF80) == 0x2500);}
static inline bool isLineCharString(const QString& string)
{
    return (string.length() > 0) && (isLineChar(string.at(0).unicode()));
}


// assert for i in [0..31] : vt100extended(vt100_graphics[i]) == i.

unsigned short vt100_graphics[32] =
{ // 0/8     1/9    2/10    3/11    4/12    5/13    6/14    7/15
  0x0020, 0x25C6, 0x2592, 0x2409, 0x240c, 0x240d, 0x240a, 0x00b0,
  0x00b1, 0x2424, 0x240b, 0x2518, 0x2510, 0x250c, 0x2514, 0x253c,
  0xF800, 0xF801, 0x2500, 0xF803, 0xF804, 0x251c, 0x2524, 0x2534,
  0x252c, 0x2502, 0x2264, 0x2265, 0x03C0, 0x2260, 0x00A3, 0x00b7
};

void KTerminalDisplay::fontChange(const QFont&)
{
    QFontMetrics fm(m_font);
    _fontHeight = fm.height() + _lineSpacing;

    // waba TerminalDisplay 1.123:
    // "Base character width on widest ASCII character. This prevents too wide
    //  characters in the presence of double wide (e.g. Japanese) characters."
    // Get the width from representative normal width characters
    _fontWidth = (double)fm.width(REPCHAR)/(double)strlen(REPCHAR);

    _fixedFont = true;

    int fw = fm.width(REPCHAR[0]);
    for(unsigned int i=1; i< strlen(REPCHAR); i++)
    {
        if (fw != fm.width(REPCHAR[i]))
        {
            _fixedFont = false;
            break;
        }
    }

    if (_fontWidth < 1)
        _fontWidth=1;

    _fontAscent = fm.ascent();

    emit changedFontMetricSignal( _fontHeight, _fontWidth );
    emit paintedFontSizeChanged();
    propagateSize();
    update();
}

void KTerminalDisplay::setVTFont(const QFont& f)
{
    QFont font = f;

#if defined(Q_WS_MAC) || defined(Q_WS_UBUNTU)
#if QT_VERSION >= 0x040700
    font.setStyleStrategy(QFont::ForceIntegerMetrics);
#else
#warning "Correct handling of the QFont metrics requited Qt>=4.7"
#endif
#endif

    QFontMetrics metrics(font);

    if ( !QFontInfo(font).fixedPitch() )
    {
        qDebug() << "Using an unsupported variable-width font in the terminal.  This may produce display errors.";
    }

    // TODO For some reasons this is bugged with Qt 5.3
    //if ( metrics.height() < height() && metrics.maxWidth() < width() )
    if (font.pixelSize() > 0)
    {
        // hint that text should be drawn without anti-aliasing.
        // depending on the user's font configuration, this may not be respected
        if (!_antialiasText)
            font.setStyleStrategy( QFont::NoAntialias );

        // experimental optimization.  Konsole assumes that the terminal is using a
        // mono-spaced font, in which case kerning information should have an effect.
        // Disabling kerning saves some computation when rendering text.
        font.setKerning(false);

        // Konsole cannot handle non-integer font metrics
        font.setStyleStrategy(QFont::StyleStrategy(font.styleStrategy() | QFont::ForceIntegerMetrics));

        //QWidget::setFont(font);
        m_font = font;
        fontChange(font);
    }
}

void KTerminalDisplay::setColorScheme(const QString &name)
{
    const ColorScheme *cs;
    // avoid legacy (int) solution
    if (!availableColorSchemes().contains(name))
        cs = ColorSchemeManager::instance()->defaultColorScheme();
    else
        cs = ColorSchemeManager::instance()->findColorScheme(name);

    if (! cs)
    {
#ifndef QT_NO_DEBUG
        qDebug() << "Cannot load color scheme: " << name;
#endif
        return;
    }

    ColorEntry table[TABLE_COLORS];
    cs->getColorTable(table);
    setColorTable(table);
    m_scheme = name;
}

QStringList KTerminalDisplay::availableColorSchemes()
{
    QStringList ret;
    foreach (const ColorScheme* cs, ColorSchemeManager::instance()->allColorSchemes())
        ret.append(cs->name());
    return ret;
}

void KTerminalDisplay::scrollWheel(qreal x, qreal y, int lines){
    if(_mouseMarks){
        int charLine;
        int charColumn;
        getCharacterPosition(QPoint(x,y) , charLine , charColumn);

        emit mouseSignal(lines > 0 ? 5 : 4,
                         charColumn + 1,
                         charLine + 1,
                         0);
    } else {
        if(_screenWindow->lineCount() == _screenWindow->windowLines()){
            const int keyCode = lines > 0 ? Qt::Key_Down : Qt::Key_Up;
            QKeyEvent keyEvent(QEvent::KeyPress, keyCode, Qt::NoModifier);

            emit keyPressedSignal(&keyEvent);
            emit keyPressedSignal(&keyEvent);
        } else {
            _screenWindow->scrollBy( ScreenWindow::ScrollLines, lines );
            _screenWindow->scrollCount();
            updateImage();
        }
    }
}

void KTerminalDisplay::mousePress(qreal x, qreal y){
    if (m_focusOnClick) forcedFocus();
    if (m_showVKBonClick) ShowVKB(true);

    int charLine;
    int charColumn;
    getCharacterPosition(QPoint(x,y), charLine, charColumn);

    _wordSelectionMode = false;
    _lineSelectionMode = false;

    if(_mouseMarks){
        emit mouseSignal(0, charColumn + 1, charLine + 1, 0);
    } else {
        QPoint pos = QPoint(charColumn, charLine);

        _screenWindow->clearSelection();
        _iPntSel = _pntSel = pos;
        _actSel = 1; // left mouse button pressed but nothing selected yet.
    }
}

void KTerminalDisplay::mouseMove(qreal x, qreal y){
    QPoint pos(x, y);

    if(_mouseMarks){
        int charLine;
        int charColumn;
        getCharacterPosition(pos, charLine, charColumn);

        emit mouseSignal(0, charColumn + 1, charLine + 1, 1);
    } else {
        extendSelection(pos);
    }
}

void KTerminalDisplay::mouseDoubleClick(qreal x, qreal y){
    QPoint pos(x, y);

    if(_mouseMarks){
        int charLine;
        int charColumn;
        getCharacterPosition(pos, charLine, charColumn);

        emit mouseSignal(0, charColumn + 1, charLine + 1, 0);
        //emit mouseSignal(0, charColumn + 1, charLine + 1, 0);
    } else {
        _wordSelectionMode = true;
        extendSelection(pos);
    }
}

void KTerminalDisplay::mouseRelease(qreal x, qreal y){
    _actSel = 0;

    if(_mouseMarks){
        int charLine;
        int charColumn;
        getCharacterPosition(QPoint(x,y), charLine, charColumn);

        emit mouseSignal(0, charColumn + 1, charLine + 1, 2);
    }
}

void KTerminalDisplay::setUsesMouse(bool usesMouse){
    _mouseMarks = !usesMouse;
}

void KTerminalDisplay::setAutoFocus(bool au)
{
    m_focusOnClick = au;
    emit changedAutoFocus(au);
}

void KTerminalDisplay::setAutoVKB(bool au)
{
    m_showVKBonClick = au;
    emit changedAutoVKB(au);
}


/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                             Display Operations                            */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/**
 A table for emulating the simple (single width) unicode drawing chars.
 It represents the 250x - 257x glyphs. If it's zero, we can't use it.
 if it's not, it's encoded as follows: imagine a 5x5 grid where the points are numbered
 0 to 24 left to top, top to bottom. Each point is represented by the corresponding bit.

 Then, the pixels basically have the following interpretation:
 _|||_
 -...-
 -...-
 -...-
 _|||_

where _ = none
      | = vertical line.
      - = horizontal line.
 */


enum LineEncode
{
    TopL  = (1<<1),
    TopC  = (1<<2),
    TopR  = (1<<3),

    LeftT = (1<<5),
    Int11 = (1<<6),
    Int12 = (1<<7),
    Int13 = (1<<8),
    RightT = (1<<9),

    LeftC = (1<<10),
    Int21 = (1<<11),
    Int22 = (1<<12),
    Int23 = (1<<13),
    RightC = (1<<14),

    LeftB = (1<<15),
    Int31 = (1<<16),
    Int32 = (1<<17),
    Int33 = (1<<18),
    RightB = (1<<19),

    BotL  = (1<<21),
    BotC  = (1<<22),
    BotR  = (1<<23)
};

#include "LineFont.h"

static void drawLineChar(QPainter* paint, qreal x, qreal y, qreal w, qreal h, uchar code)
{
    //Calculate cell midpoints, end points.
    qreal cx = x + w/2;
    qreal cy = y + h/2;
    qreal ex = x + w - 1;
    qreal ey = y + h - 1;

    quint32 toDraw = LineChars[code];

    //Top _lines:
    if (toDraw & TopL)
        paint->drawLine(cx-1, y, cx-1, cy-2);
    if (toDraw & TopC)
        paint->drawLine(cx, y, cx, cy-2);
    if (toDraw & TopR)
        paint->drawLine(cx+1, y, cx+1, cy-2);

    //Bot _lines:
    if (toDraw & BotL)
        paint->drawLine(cx-1, cy+2, cx-1, ey);
    if (toDraw & BotC)
        paint->drawLine(cx, cy+2, cx, ey);
    if (toDraw & BotR)
        paint->drawLine(cx+1, cy+2, cx+1, ey);

    //Left _lines:
    if (toDraw & LeftT)
        paint->drawLine(x, cy-1, cx-2, cy-1);
    if (toDraw & LeftC)
        paint->drawLine(x, cy, cx-2, cy);
    if (toDraw & LeftB)
        paint->drawLine(x, cy+1, cx-2, cy+1);

    //Right _lines:
    if (toDraw & RightT)
        paint->drawLine(cx+2, cy-1, ex, cy-1);
    if (toDraw & RightC)
        paint->drawLine(cx+2, cy, ex, cy);
    if (toDraw & RightB)
        paint->drawLine(cx+2, cy+1, ex, cy+1);

    //Intersection points.
    if (toDraw & Int11)
        paint->drawPoint(cx-1, cy-1);
    if (toDraw & Int12)
        paint->drawPoint(cx, cy-1);
    if (toDraw & Int13)
        paint->drawPoint(cx+1, cy-1);

    if (toDraw & Int21)
        paint->drawPoint(cx-1, cy);
    if (toDraw & Int22)
        paint->drawPoint(cx, cy);
    if (toDraw & Int23)
        paint->drawPoint(cx+1, cy);

    if (toDraw & Int31)
        paint->drawPoint(cx-1, cy+1);
    if (toDraw & Int32)
        paint->drawPoint(cx, cy+1);
    if (toDraw & Int33)
        paint->drawPoint(cx+1, cy+1);

}

void KTerminalDisplay::setKeyboardCursorShape(KeyboardCursorShape shape)
{
    _cursorShape = shape;
}

KTerminalDisplay::KeyboardCursorShape KTerminalDisplay::keyboardCursorShape() const
{
    return _cursorShape;
}

void KTerminalDisplay::setKeyboardCursorColor(bool useForegroundColor, const QColor& color)
{
    if (useForegroundColor)
        _cursorColor = QColor(); // an invalid color means that
    // the foreground color of the
    // current character should
    // be used

    else
        _cursorColor = color;
}

QColor KTerminalDisplay::keyboardCursorColor() const
{
    return _cursorColor;
}

void KTerminalDisplay::ShowVKB(bool show)
{
    bool focused = hasActiveFocus();

    if (focused && show && !qGuiApp->inputMethod()->isVisible()) {
        updateInputMethod(Qt::ImEnabled);
        qGuiApp->inputMethod()->show();
    }

    if (focused && !show && qGuiApp->inputMethod()->isVisible()) {
        updateInputMethod(Qt::ImEnabled);
        qGuiApp->inputMethod()->hide();
    }
}

void KTerminalDisplay::setRandomSeed(uint randomSeed) { _randomSeed = randomSeed; }
uint KTerminalDisplay::randomSeed() const { return _randomSeed; }

#if 0
/*!
    Set XIM Position
*/
void TerminalDisplay::setCursorPos(const int curx, const int cury)
{
    int xpos, ypos;
    ypos = _topMargin + _fontHeight*(cury-1) + _fontAscent;
    xpos = _leftMargin + _fontWidth*curx;
    //setMicroFocusHint(xpos, ypos, 0, _fontHeight); //### ???
    // fprintf(stderr, "x/y = %d/%d\txpos/ypos = %d/%d\n", curx, cury, xpos, ypos);
    _cursorLine = cury;
    _cursorCol = curx;
}
#endif

// scrolls the image by 'lines', down if lines > 0 or up otherwise.
//
// the terminal emulation keeps track of the scrolling of the character
// image as it receives input, and when the view is updated, it calls scrollImage()
// with the final scroll amount.  this improves performance because scrolling the
// display is much cheaper than re-rendering all the text for the
// part of the image which has moved up or down.
// Instead only new lines have to be drawn
void KTerminalDisplay::scrollImage(int lines , const QRect& screenWindowRegion)
{
    // constrain the region to the display
    // the bottom of the region is capped to the number of lines in the display's
    // internal image - 2, so that the height of 'region' is strictly less
    // than the height of the internal image.
    QRect region = screenWindowRegion;
    region.setBottom( qMin(region.bottom(),this->_lines-2) );

    // return if there is nothing to do
    if (    lines == 0
            || _image == 0
            || !region.isValid()
            || (region.top() + abs(lines)) >= region.bottom()
            || this->_lines <= region.height() ) return;


    void* firstCharPos = &_image[ region.top() * this->_columns ];
    void* lastCharPos = &_image[ (region.top() + abs(lines)) * this->_columns ];

    int top = _topMargin + (region.top() * _fontHeight);
    Q_UNUSED(top) //BAD IDEA!
    int linesToMove = region.height() - abs(lines);
    int bytesToMove = linesToMove *
            this->_columns *
            sizeof(Character);

    Q_ASSERT( linesToMove > 0 );
    Q_ASSERT( bytesToMove > 0 );

    //scroll internal image
    if ( lines > 0 )
    {
        // check that the memory areas that we are going to move are valid
        Q_ASSERT( (char*)lastCharPos + bytesToMove <
                  (char*)(_image + (this->_lines * this->_columns)) );

        Q_ASSERT( (lines*this->_columns) < _imageSize );

        //scroll internal image down
        memmove( firstCharPos , lastCharPos , bytesToMove );
    }
    else
    {
        // check that the memory areas that we are going to move are valid
        Q_ASSERT( (char*)firstCharPos + bytesToMove <
                  (char*)(_image + (this->_lines * this->_columns)) );

        //scroll internal image up
        memmove( lastCharPos , firstCharPos , bytesToMove );
    }

    // Q_ASSERT(scrollRect.isValid() && !scrollRect.isEmpty());

    //scroll the display vertically to match internal _image
    // scroll( 0 , _fontHeight * (-lines) , scrollRect );
}

void KTerminalDisplay::updateImage()
{
    if ( !_screenWindow )
        return;

    // optimization - scroll the existing image where possible and
    // avoid expensive text drawing for parts of the image that
    // can simply be moved up or down
    scrollImage( _screenWindow->scrollCount() ,
                 _screenWindow->scrollRegion() );
    _screenWindow->resetScrollCount();

    if (!_image) {
        // Create _image.
        // The emitted changedContentSizeSignal also leads to getImage being recreated, so do this first.
        updateImageSize();
    }

    Character* const newimg = _screenWindow->getImage();
    int lines   = _screenWindow->windowLines();
    int columns = _screenWindow->windowColumns();

    Q_ASSERT( this->_usedLines <= this->_lines );
    Q_ASSERT( this->_usedColumns <= this->_columns );

    int y,x,len;

    _hasBlinker = false;

    CharacterColor cf;       // undefined
    CharacterColor _clipboard;       // undefined
    int cr  = -1;   // undefined

    const int linesToUpdate   = qMin(this->_lines,  qMax(0,lines  ));
    const int columnsToUpdate = qMin(this->_columns,qMax(0,columns));

    QChar *disstrU = new QChar[columnsToUpdate];
    char *dirtyMask = new char[columnsToUpdate+2];
    QRegion dirtyRegion;

    // debugging variable, this records the number of lines that are found to
    // be 'dirty' ( ie. have changed from the old _image to the new _image ) and
    // which therefore need to be repainted
    int dirtyLineCount = 0;

    for (y = 0; y < linesToUpdate; ++y)
    {
        const Character*       currentLine = &_image[y*this->_columns];
        const Character* const newLine = &newimg[y*columns];

        bool updateLine = false;

        // The dirty mask indicates which characters need repainting. We also
        // mark surrounding neighbours dirty, in case the character exceeds
        // its cell boundaries
        memset(dirtyMask, 0, columnsToUpdate+2);

        for( x = 0 ; x < columnsToUpdate ; ++x)
        {
            if ( newLine[x] != currentLine[x] )
            {
                dirtyMask[x] = true;
            }
        }

        if (!_resizing) // not while _resizing, we're expecting a paintEvent
            for (x = 0; x < columnsToUpdate; ++x)
            {
                _hasBlinker |= (newLine[x].rendition & RE_BLINK);

                // Start drawing if this character or the next one differs.
                // We also take the next one into account to handle the situation
                // where characters exceed their cell width.
                if (dirtyMask[x])
                {
                    quint16 c = newLine[x+0].character;
                    if ( !c )
                        continue;
                    int p = 0;
                    disstrU[p++] = c; //fontMap(c);
                    bool lineDraw = isLineChar(c);
                    bool doubleWidth = (x+1 == columnsToUpdate) ? false : (newLine[x+1].character == 0);
                    cr = newLine[x].rendition;
                    _clipboard = newLine[x].backgroundColor;
                    if (newLine[x].foregroundColor != cf) cf = newLine[x].foregroundColor;
                    int lln = columnsToUpdate - x;
                    for (len = 1; len < lln; ++len)
                    {
                        const Character& ch = newLine[x+len];

                        if (!ch.character)
                            continue; // Skip trailing part of multi-col chars.

                        bool nextIsDoubleWidth = (x+len+1 == columnsToUpdate) ? false : (newLine[x+len+1].character == 0);

                        if (  ch.foregroundColor != cf ||
                              ch.backgroundColor != _clipboard ||
                              ch.rendition != cr ||
                              !dirtyMask[x+len] ||
                              isLineChar(c) != lineDraw ||
                              nextIsDoubleWidth != doubleWidth )
                            break;

                        disstrU[p++] = c; //fontMap(c);
                    }

                    QString unistr(disstrU, p);

                    bool saveFixedFont = _fixedFont;
                    if (lineDraw)
                        _fixedFont = false;
                    if (doubleWidth)
                        _fixedFont = false;

                    updateLine = true;

                    _fixedFont = saveFixedFont;
                    x += len - 1;
                }

            }

        //both the top and bottom halves of double height _lines must always be redrawn
        //although both top and bottom halves contain the same characters, only
        //the top one is actually
        //drawn.
        if (_lineProperties.count() > y)
            updateLine |= (_lineProperties[y] & LINE_DOUBLEHEIGHT);

        // if the characters on the line are different in the old and the new _image
        // then this line must be repainted.
        if (updateLine)
        {
            dirtyLineCount++;

            // add the area occupied by this line to the region which needs to be
            // repainted
            QRect dirtyRect = QRect( qRound(_leftMargin),
                                     qRound(_topMargin + _fontHeight*y) ,
                                     qRound(_fontWidth * columnsToUpdate) ,
                                     _fontHeight );

            dirtyRegion |= dirtyRect;
        }

        // replace the line of characters in the old _image with the
        // current line of the new _image
        memcpy((void*)currentLine,(const void*)newLine,columnsToUpdate*sizeof(Character));
    }

    // if the new _image is smaller than the previous _image, then ensure that the area
    // outside the new _image is cleared
    if ( linesToUpdate < _usedLines )
    {
        dirtyRegion |= QRect( qRound(_leftMargin),
                              qRound(_topMargin + _fontHeight*linesToUpdate) ,
                              qRound(_fontWidth * this->_columns) ,
                              _fontHeight * (_usedLines-linesToUpdate) );
    }
    _usedLines = linesToUpdate;

    if ( columnsToUpdate < _usedColumns )
    {
        dirtyRegion |= QRect( qRound(_leftMargin + columnsToUpdate*_fontWidth) ,
                              qRound(_topMargin),
                              qRound(_fontWidth * (_usedColumns-columnsToUpdate)) ,
                              _fontHeight * this->_lines );
    }
    _usedColumns = columnsToUpdate;

    dirtyRegion |= geometryRound(_inputMethodData.previousPreeditRect);

    // update the parts of the display which have changed
    // update(dirtyRegion.boundingRect());

    // update whole widget
    update();

    if ( _hasBlinker && !_blinkTimer->isActive()) _blinkTimer->start( TEXT_BLINK_DELAY );
    if (!_hasBlinker && _blinkTimer->isActive()) { _blinkTimer->stop(); _blinking = false; }
    delete[] dirtyMask;
    delete[] disstrU;

    //Notify changes to qml
    emit updatedImage();
}

void KTerminalDisplay::setBlinkingCursor(bool blink)
{
    _hasBlinkingCursor=blink;

    if (blink && !_blinkCursorTimer->isActive())
        _blinkCursorTimer->start(100); // WARN! HARDCODE

    if (!blink && _blinkCursorTimer->isActive())
    {
        _blinkCursorTimer->stop();
        if (_cursorBlinking)
            blinkCursorEvent();
        else
            _cursorBlinking = false;
    }
}

void KTerminalDisplay::setBlinkingTextEnabled(bool blink)
{
    _allowBlinkingText = blink;

    if (blink && !_blinkTimer->isActive())
        _blinkTimer->start(qApp->styleHints()->cursorFlashTime() / 2);

    if (!blink && _blinkTimer->isActive())
    {
        _blinkTimer->stop();
        _blinking = false;
    }
}

void KTerminalDisplay::focusOutEvent(QFocusEvent*)
{
    emit termLostFocus();
    // trigger a repaint of the cursor so that it is both visible (in case
    // it was hidden during blinking)
    // and drawn in a focused out state
    _cursorBlinking = false;
    updateCursor();

    _blinkCursorTimer->stop();
    if (_blinking)
        blinkEvent();

    _blinkTimer->stop();

    //parent->activeFocus = false;
    emit activeFocusChanged(true);
}

void KTerminalDisplay::focusInEvent(QFocusEvent*)
{
    emit termGetFocus();
    if (_hasBlinkingCursor)
    {
        _blinkCursorTimer->start();
    }
    updateCursor();

    if (_hasBlinker)
        _blinkTimer->start();
}

QPoint KTerminalDisplay::cursorPosition() const
{
    if (_screenWindow)
        return _screenWindow->cursorPosition();
    else
        return QPoint(0,0);
}

void KTerminalDisplay::blinkEvent()
{
    if (!_allowBlinkingText) return;

    _blinking = !_blinking;

    //TODO:  Optimize to only repaint the areas of the widget
    // where there is blinking text
    // rather than repainting the whole widget.
    update();
}

void KTerminalDisplay::updateCursor()
{
    QRect cursorRect = imageToWidget( QRect(cursorPosition(),QSize(1,1)) );
    update(cursorRect);
}

void KTerminalDisplay::blinkCursorEvent()
{
    _cursorBlinking = !_cursorBlinking;
    updateCursor();
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                  Resizing                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

void KTerminalDisplay::propagateSize()
{
    if (_image) {
        updateImageSize();
    }
}

void KTerminalDisplay::updateImageSize()
{
    Character* oldimg = _image;
    int oldlin = _lines;
    int oldcol = _columns;

    makeImage();

    // copy the old image to reduce flicker
    int lines =   qMin(oldlin,_lines);
    int columns = qMin(oldcol,_columns);

    emit terminalSizeChanged();

    if (oldimg)
    {
        for (int line = 0; line < lines; line++)
        {
            memcpy((void*)&_image[_columns*line],
                    (void*)&oldimg[oldcol*line],columns*sizeof(Character));
        }
        delete[] oldimg;
    }

    if (_screenWindow)
        _screenWindow->setWindowLines(_lines);

    _resizing = (oldlin!=_lines) || (oldcol!=_columns);

    if ( _resizing )
    {
        emit changedContentSizeSignal(_contentHeight, _contentWidth); // expose resizeEvent
    }

    _resizing = false;
}

void KTerminalDisplay::scrollToEnd()
{
    //_screenWindow->scrollTo( _scrollBar->value() + 1 );
    _screenWindow->setTrackOutput( _screenWindow->atEndOfOutput() );
}

void KTerminalDisplay::extendSelection( const QPoint& position )
{
    QPoint pos = position;

    if ( !_screenWindow )
        return;

    //if ( !contentsRect().contains(ev->pos()) ) return;

    // we're in the process of moving the mouse with the left button pressed
    // the mouse cursor will kept caught within the bounds of the text in
    // this widget.

    int linesBeyondWidget = 0;

    QRect textBounds( _leftMargin,
                      _topMargin,
                      _usedColumns*_fontWidth-1,
                      _usedLines*_fontHeight-1);

    // Adjust position within text area bounds.
    QPoint oldpos = pos;

    pos.setX( qBound(textBounds.left(),pos.x(),textBounds.right()) );
    pos.setY( qBound(textBounds.top(),pos.y(),textBounds.bottom()) );

    if ( oldpos.y() > textBounds.bottom() )
    {
        linesBeyondWidget = (oldpos.y()-textBounds.bottom()) / _fontHeight;
    }
    if ( oldpos.y() < textBounds.top() )
    {
        linesBeyondWidget = (textBounds.top()-oldpos.y()) / _fontHeight;
    }

    int charColumn = 0;
    int charLine = 0;
    getCharacterPosition(pos,charLine,charColumn);

    QPoint here = QPoint(charColumn,charLine); //QPoint((pos.x()-tLx-_leftMargin+(_fontWidth/2))/_fontWidth,(pos.y()-tLy-_topMargin)/_fontHeight);
    QPoint ohere;
    QPoint _iPntSelCorr = _iPntSel;
    _iPntSelCorr.ry() -= 0; //_scrollBar->value();
    QPoint _pntSelCorr = _pntSel;
    _pntSelCorr.ry() -= 0; //_scrollBar->value();
    bool swapping = false;

    if ( _wordSelectionMode )
    {
        // Extend to word boundaries
        int i;
        QChar selClass;

        bool left_not_right = ( here.y() < _iPntSelCorr.y() ||
                                ( here.y() == _iPntSelCorr.y() && here.x() < _iPntSelCorr.x() ) );
        bool old_left_not_right = ( _pntSelCorr.y() < _iPntSelCorr.y() ||
                                    ( _pntSelCorr.y() == _iPntSelCorr.y() && _pntSelCorr.x() < _iPntSelCorr.x() ) );
        swapping = left_not_right != old_left_not_right;

        // Find left (left_not_right ? from here : from start)
        QPoint left = left_not_right ? here : _iPntSelCorr;
        i = loc(left.x(),left.y());
        if (i>=0 && i<=_imageSize) {
            selClass = charClass(_image[i].character);
            while ( ((left.x()>0) || (left.y()>0 && (_lineProperties[left.y()-1] & LINE_WRAPPED) ))
                    && charClass(_image[i-1].character) == selClass )
            { i--; if (left.x()>0) left.rx()--; else {left.rx()=_usedColumns-1; left.ry()--;} }
        }

        // Find left (left_not_right ? from start : from here)
        QPoint right = left_not_right ? _iPntSelCorr : here;
        i = loc(right.x(),right.y());
        if (i>=0 && i<=_imageSize) {
            selClass = charClass(_image[i].character);
            while( ((right.x()<_usedColumns-1) || (right.y()<_usedLines-1 && (_lineProperties[right.y()] & LINE_WRAPPED) ))
                   && charClass(_image[i+1].character) == selClass )
            { i++; if (right.x()<_usedColumns-1) right.rx()++; else {right.rx()=0; right.ry()++; } }
        }

        // Pick which is start (ohere) and which is extension (here)
        if ( left_not_right )
        {
            here = left; ohere = right;
        }
        else
        {
            here = right; ohere = left;
        }
        ohere.rx()++;
    }

    if ( _lineSelectionMode )
    {
        // Extend to complete line
        bool above_not_below = ( here.y() < _iPntSelCorr.y() );

        QPoint above = above_not_below ? here : _iPntSelCorr;
        QPoint below = above_not_below ? _iPntSelCorr : here;

        while (above.y()>0 && (_lineProperties[above.y()-1] & LINE_WRAPPED) )
            above.ry()--;
        while (below.y()<_usedLines-1 && (_lineProperties[below.y()] & LINE_WRAPPED) )
            below.ry()++;

        above.setX(0);
        below.setX(_usedColumns-1);

        // Pick which is start (ohere) and which is extension (here)
        if ( above_not_below )
        {
            here = above; ohere = below;
        }
        else
        {
            here = below; ohere = above;
        }

        QPoint newSelBegin = QPoint( ohere.x(), ohere.y() );
        swapping = !(_tripleSelBegin==newSelBegin);
        _tripleSelBegin = newSelBegin;

        ohere.rx()++;
    }

    int offset = 0;
    if ( !_wordSelectionMode && !_lineSelectionMode )
    {
        int i;
        QChar selClass;

        bool left_not_right = ( here.y() < _iPntSelCorr.y() ||
                                ( here.y() == _iPntSelCorr.y() && here.x() < _iPntSelCorr.x() ) );
        bool old_left_not_right = ( _pntSelCorr.y() < _iPntSelCorr.y() ||
                                    ( _pntSelCorr.y() == _iPntSelCorr.y() && _pntSelCorr.x() < _iPntSelCorr.x() ) );
        swapping = left_not_right != old_left_not_right;

        // Find left (left_not_right ? from here : from start)
        QPoint left = left_not_right ? here : _iPntSelCorr;

        // Find left (left_not_right ? from start : from here)
        QPoint right = left_not_right ? _iPntSelCorr : here;
        if ( right.x() > 0 && !_columnSelectionMode )
        {
            i = loc(right.x(),right.y());
            if (i>=0 && i<=_imageSize) {
                selClass = charClass(_image[i-1].character);
                /* if (selClass == ' ')
        {
          while ( right.x() < _usedColumns-1 && charClass(_image[i+1].character) == selClass && (right.y()<_usedLines-1) &&
                          !(_lineProperties[right.y()] & LINE_WRAPPED))
          { i++; right.rx()++; }
          if (right.x() < _usedColumns-1)
            right = left_not_right ? _iPntSelCorr : here;
          else
            right.rx()++;  // will be balanced later because of offset=-1;
        }*/
            }
        }

        // Pick which is start (ohere) and which is extension (here)
        if ( left_not_right )
        {
            here = left; ohere = right; offset = 0;
        }
        else
        {
            here = right; ohere = left; offset = -1;
        }
    }

    //if ((here == _pntSelCorr) && (scroll == _scrollBar->value())) return; // not moved

    if (here == ohere) return; // It's not left, it's not right.

    if ( _actSel < 2 || swapping )
    {
        if ( _columnSelectionMode && !_lineSelectionMode && !_wordSelectionMode )
        {
            _screenWindow->setSelectionStart( ohere.x() , ohere.y() , true );
        }
        else
        {
            _screenWindow->setSelectionStart( ohere.x()-1-offset , ohere.y() , false );
        }

    }

    _actSel = 2; // within selection
    _pntSel = here;
    _pntSel.ry() += 0; //_scrollBar->value();

    if ( _columnSelectionMode && !_lineSelectionMode && !_wordSelectionMode )
    {
        _screenWindow->setSelectionEnd( here.x() , here.y() );
    }
    else
    {
        _screenWindow->setSelectionEnd( here.x()+offset , here.y() );
    }

    Q_UNUSED(linesBeyondWidget)

}

void KTerminalDisplay::updateLineProperties()
{
    if ( !_screenWindow )
        return;

    _lineProperties = _screenWindow->getLineProperties();
}

QChar KTerminalDisplay::charClass(QChar qch) const
{
    if ( qch.isSpace() ) return ' ';

    if ( qch.isLetterOrNumber() || _wordCharacters.contains(qch, Qt::CaseInsensitive ) )
        return 'a';

    return qch;
}

void KTerminalDisplay::setWordCharacters(const QString& wc)
{
    _wordCharacters = wc;
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                               Clipboard                                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#undef KeyPress

void KTerminalDisplay::emitSelection(bool useXselection,bool appendReturn)
{
    if ( !_screenWindow )
        return;

    // Paste Clipboard by simulating keypress events
    QString text = QGuiApplication::clipboard()->text(useXselection ? QClipboard::Selection :
                                                                      QClipboard::Clipboard);
    if(appendReturn)
        text.append("\r");
    if ( ! text.isEmpty() )
    {
        text.replace('\n', '\r');
        QKeyEvent e(QEvent::KeyPress, 0, Qt::NoModifier, text);
        emit keyPressedSignal(&e); // expose as a big fat keypress event

        _screenWindow->clearSelection();
    }
}

void KTerminalDisplay::setSelection(const QString& t)
{
    QGuiApplication::clipboard()->setText(t, QClipboard::Selection);
}

void KTerminalDisplay::copyClipboard()
{
    if ( !_screenWindow )
        return;

    QString text = _screenWindow->selectedText(_preserveLineBreaks);
    if (!text.isEmpty())
        QGuiApplication::clipboard()->setText(text);
}

void KTerminalDisplay::pasteClipboard()
{
    emitSelection(false,false);
}

void KTerminalDisplay::pasteSelection()
{
    if (!_screenWindow)
        return;

    QString text = _screenWindow->selectedText(_preserveLineBreaks);
    if (text.isEmpty())
        return;

    text.replace('\n', '\r');
    QKeyEvent e(QEvent::KeyPress, 0, Qt::NoModifier, text);
    emit keyPressedSignal(&e); // expose as a big fat keypress event
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Keyboard                                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */

void KTerminalDisplay::setFlowControlWarningEnabled( bool enable )
{
    _flowControlWarningEnabled = enable;

    // if the dialog is currently visible and the flow control warning has
    // been disabled then hide the dialog
    //    if (!enable)
    //        outputSuspended(false);
}

void KTerminalDisplay::inputMethodEvent( QInputMethodEvent* event )
{
    QKeyEvent keyEvent(QEvent::KeyPress,0,Qt::NoModifier,event->commitString());
    emit keyPressedSignal(&keyEvent);

    _inputMethodData.preeditString = event->preeditString();
    QRect updRect = geometryRound(preeditRect() | _inputMethodData.previousPreeditRect);
    update(updRect);

    event->accept();
}

void KTerminalDisplay::inputMethodQuery(QInputMethodQueryEvent *event)
{
    event->setValue(Qt::ImEnabled, true);
    event->accept();
}

QVariant KTerminalDisplay::inputMethodQuery(Qt::InputMethodQuery query) const
{
    const QPoint cursorPos = _screenWindow ? _screenWindow->cursorPosition() : QPoint(0,0);
    switch ( query )
    {
    case Qt::ImEnabled:
        return (bool)(flags() & ItemAcceptsInputMethod);
        break;
    case Qt::ImMicroFocus:
        return imageToWidget(QRect(cursorPos.x(),cursorPos.y(),1,1));
        break;
    case Qt::ImFont:
        return m_font;
        break;
    case Qt::ImCursorPosition:
        // return the cursor position within the current line
        return cursorPos.x();
        break;
    case Qt::ImSurroundingText:
    {
        // return the text from the current line
        QString lineText;
        QTextStream stream(&lineText);
        PlainTextDecoder decoder;
        decoder.begin(&stream);
        decoder.decodeLine(&_image[loc(0,cursorPos.y())],_usedColumns,_lineProperties[cursorPos.y()]);
        decoder.end();
        return lineText;
    }
        break;
    case Qt::ImCurrentSelection:
        return QString();
        break;
    default:
        break;
    }

    return QVariant();
}

bool KTerminalDisplay::handleShortcutOverrideEvent(QKeyEvent* keyEvent)
{
    int modifiers = keyEvent->modifiers();

    //  When a possible shortcut combination is pressed,
    //  emit the overrideShortcutCheck() signal to allow the host
    //  to decide whether the terminal should override it or not.
    if (modifiers != Qt::NoModifier)
    {
        int modifierCount = 0;
        unsigned int currentModifier = Qt::ShiftModifier;

        while (currentModifier <= Qt::KeypadModifier)
        {
            if (modifiers & currentModifier)
                modifierCount++;
            currentModifier <<= 1;
        }
        if (modifierCount < 2)
        {
            bool override = false;
            emit overrideShortcutCheck(keyEvent,override);
            if (override)
            {
                keyEvent->accept();
                return true;
            }
        }
    }

    // Override any of the following shortcuts because
    // they are needed by the terminal
    int keyCode = keyEvent->key() | modifiers;
    switch ( keyCode )
    {
    // list is taken from the QLineEdit::event() code
    case Qt::Key_Tab:
    case Qt::Key_Delete:
    case Qt::Key_Home:
    case Qt::Key_End:
    case Qt::Key_Backspace:
    case Qt::Key_Left:
    case Qt::Key_Right:
        keyEvent->accept();
        return true;
    }
    return false;
}

bool KTerminalDisplay::event(QEvent* event)
{
    bool eventHandled = false;
    switch (event->type())
    {
    case QEvent::ShortcutOverride:
        eventHandled = handleShortcutOverrideEvent((QKeyEvent*)event);
        break;
    case QEvent::PaletteChange:
    case QEvent::ApplicationPaletteChange:
        break;
    case QEvent::InputMethod:
        inputMethodEvent(static_cast<QInputMethodEvent *>(event));
        break;
    case QEvent::InputMethodQuery:
        inputMethodQuery(static_cast<QInputMethodQueryEvent *>(event));
        break;
    default:
        eventHandled = QQuickPaintedItem::event(event);
        break;
    }
    return eventHandled; //parent->event(event);
}

void KTerminalDisplay::geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    if (newGeometry != oldGeometry) {
        m_widgetRect = newGeometry;
        propagateSize();
        update();
    }

    QQuickPaintedItem::geometryChanged(newGeometry,oldGeometry);
}

QRect KTerminalDisplay::geometryRound(const QRectF &r) const
{
    QRect rect;

    rect.setTop(qRound(r.top()));
    rect.setBottom(qRound(r.bottom()));
    rect.setLeft(qRound(r.left()));
    rect.setRight(qRound(r.right()));

    return rect;
}

void KTerminalDisplay::setBellMode(int mode)
{
    _bellMode=mode;
}

void KTerminalDisplay::enableBell()
{
    _allowBell = true;
}

void KTerminalDisplay::bell(const QString& message)
{
    Q_UNUSED(message)

    if (_bellMode==NoBell) return;

    //limit the rate at which bells can occur
    //...mainly for sound effects where rapid bells in sequence
    //produce a horrible noise
    if ( _allowBell )
    {
        _allowBell = false;
        QTimer::singleShot(500,this,SLOT(enableBell()));

        if (_bellMode==SystemBeepBell)
        {
            // NO BEEP !
            //QGuiApplication::beep();
            int a = 0;
            Q_UNUSED(a)
        }
        else if (_bellMode==NotifyBell)
        {
            //KNotification::event("BellVisible", message,QPixmap(),this);
            // TODO/FIXME: qt4 notifications?
        }
        else if (_bellMode==VisualBell)
        {
            swapColorTable();
            QTimer::singleShot(200,this,SLOT(swapColorTable()));
        }
    }
}

void KTerminalDisplay::selectionChanged()
{
    emit copyAvailable(_screenWindow->selectedText(false).isEmpty() == false);
}

void KTerminalDisplay::swapColorTable()
{
    ColorEntry color = _colorTable[1];
    _colorTable[1]=_colorTable[0];
    _colorTable[0]= color;
    _colorsInverted = !_colorsInverted;
    update();
}

void KTerminalDisplay::clearImage()
{
    // We initialize _image[_imageSize] too. See makeImage()
    for (int i = 0; i <= _imageSize; i++)
    {
        _image[i].character = ' ';
        _image[i].foregroundColor = CharacterColor(COLOR_SPACE_DEFAULT,
                                                   DEFAULT_FORE_COLOR);
        _image[i].backgroundColor = CharacterColor(COLOR_SPACE_DEFAULT,
                                                   DEFAULT_BACK_COLOR);
        _image[i].rendition = DEFAULT_RENDITION;
    }
}

void KTerminalDisplay::calcGeometry()
{
    _leftMargin    = DEFAULT_LEFT_MARGIN;
    _contentWidth  = width() - 2 * DEFAULT_LEFT_MARGIN;

    _topMargin     = DEFAULT_TOP_MARGIN;
    _contentHeight = height() - 2 * DEFAULT_TOP_MARGIN + /* mysterious */ 1;

    // ensure that display is always at least one column wide
    _columns     = qMax(1, qRound(_contentWidth / _fontWidth));
    _usedColumns = qMin(_usedColumns,_columns);

    // ensure that display is always at least one line high
    _lines     = qMax(1, qFloor(_contentHeight / (double)_fontHeight));
    _usedLines = qMin(_usedLines,_lines);
}

void KTerminalDisplay::makeImage()
{
    calcGeometry();

    // confirm that array will be of non-zero size, since the painting code
    // assumes a non-zero array length
    Q_ASSERT( _lines > 0 && _columns > 0 );
    Q_ASSERT( _usedLines <= _lines && _usedColumns <= _columns );

    _imageSize=_lines*_columns;

    // We over-commit one character so that we can be more relaxed in dealing with
    // certain boundary conditions: _image[_imageSize] is a valid but unused position
    _image = new Character[_imageSize+1];

    clearImage();
}

uint KTerminalDisplay::lineSpacing() const
{
    return _lineSpacing;
}

void KTerminalDisplay::setLineSpacing(uint i)
{
    _lineSpacing = i;
    setVTFont(m_font); // Trigger an update.
}



/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
///                                    PAINT
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

QRect KTerminalDisplay::imageToWidget(const QRect& imageArea) const
{
    QRect result;
    result.setLeft(   _leftMargin + _fontWidth * imageArea.left() );
    result.setTop(    _topMargin  + _fontHeight * imageArea.top() );
    result.setWidth(  _fontWidth  * imageArea.width() );
    result.setHeight( _fontHeight * imageArea.height() );

    return result;
}

void KTerminalDisplay::paint(QPainter *painter)
{
    //contentsBoundingRect()
    QRectF rect = m_widgetRect;
    drawBackground(painter, rect, _colorTable[DEFAULT_BACK_COLOR].color, true /* use opacity setting */);

    /////////////////////////////////////
    ///           !!!WARN!!!
    ///   THIS FUNCTION REQUIRE PATCH
    /////////////////////////////////////
    drawContents(painter, rect);
    /////////////////////////////////////
    /////////////////////////////////////

    drawInputMethodPreeditString(painter, preeditRect());
    //paintFilters(painter);
}

void KTerminalDisplay::drawContents(QPainter  *paint, QRectF &rect)
{
    //Q_UNUSED(rect)
    int left_   = ceil(rect.left());
    int top_    = ceil(rect.top());
    int right_  = ceil(rect.right());
    int bottom_ = ceil(rect.bottom());

    int lux = qMin(_usedColumns-1, qMax(0, qRound((left_   + _leftMargin ) / _fontWidth  )));
    int luy = qMin(_usedLines-1,   qMax(0, qRound((top_    + _topMargin  ) / _fontHeight )));
    int rlx = qMin(_usedColumns-1, qMax(0, qRound((right_  - _leftMargin ) / _fontWidth  )));
    int rly = qMin(_usedLines-1,   qMax(0, qRound((bottom_ - _topMargin  ) / _fontHeight )));

    // prevent zero size buffer
    if (_usedColumns<=1) return;

    const int bufferSize = _usedColumns;
    QString unistr;
    unistr.reserve(bufferSize);
    for (int y = luy; y <= rly; y++)
    {
        quint16 c = _image[loc(lux,y)].character;
        int x = lux;
        if(!c && x)
            x--; // Search for start of multi-column character
        for (; x <= rlx; x++)
        {
            int len = 1;
            int p = 0;

            // reset our buffer to the maximal size
            unistr.resize(bufferSize);
            QChar *disstrU = unistr.data();

            // is this a single character or a sequence of characters ?
            if ( _image[loc(x,y)].rendition & RE_EXTENDED_CHAR )
            {
                // sequence of characters
                ushort extendedCharLength = 0;
                ushort* chars = ExtendedCharTable::instance
                        .lookupExtendedChar(_image[loc(x,y)].charSequence,extendedCharLength);
                for ( int index = 0 ; index < extendedCharLength ; index++ )
                {
                    Q_ASSERT( p < bufferSize );
                    disstrU[p++] = chars[index];
                }
            }
            else
            {
                // single character
                c = _image[loc(x,y)].character;
                if (c)
                {
                    Q_ASSERT( p < bufferSize );
                    disstrU[p++] = c; //fontMap(c);
                }
            }

            bool lineDraw = isLineChar(c);
            bool doubleWidth = (_image[ qMin(loc(x,y)+1,_imageSize) ].character == 0);
            CharacterColor currentForeground = _image[loc(x,y)].foregroundColor;
            CharacterColor currentBackground = _image[loc(x,y)].backgroundColor;
            quint8 currentRendition = _image[loc(x,y)].rendition;

            while (x+len <= rlx &&
                   _image[loc(x+len,y)].foregroundColor == currentForeground &&
                   _image[loc(x+len,y)].backgroundColor == currentBackground &&
                   _image[loc(x+len,y)].rendition == currentRendition &&
                   (_image[ qMin(loc(x+len,y)+1,_imageSize) ].character == 0) == doubleWidth &&
                   isLineChar( c = _image[loc(x+len,y)].character) == lineDraw) // Assignment!
            {
                if (c)
                    disstrU[p++] = c; //fontMap(c);
                if (doubleWidth) // assert((_image[loc(x+len,y)+1].character == 0)), see above if condition
                    len++; // Skip trailing part of multi-column character
                len++;
            }
            if ((x+len < _usedColumns) && (!_image[loc(x+len,y)].character))
                len++; // Adjust for trailing part of multi-column character

            bool save__fixedFont = _fixedFont;

            if (lineDraw)
                _fixedFont = false;
            if (doubleWidth)
                _fixedFont = false;
            unistr.resize(p);

            // Create a text scaling matrix for double width and double height lines.
            QMatrix textScale;

            if (y < _lineProperties.size())
            {
                if (_lineProperties[y] & LINE_DOUBLEWIDTH)
                    textScale.scale(2,1);

                if (_lineProperties[y] & LINE_DOUBLEHEIGHT)
                    textScale.scale(1,2);
            }

            //Apply text scaling matrix.
            paint->setWorldMatrix(textScale, true);

            //calculate the area in which the text will be drawn
            QRectF textArea = QRectF( _leftMargin + _fontWidth*x , _topMargin + _fontHeight*y , _fontWidth*len , _fontHeight);

            //move the calculated area to take account of scaling applied to the painter.
            //the position of the area from the origin (0,0) is scaled
            //by the opposite of whatever
            //transformation has been applied to the painter.  this ensures that
            //painting does actually start from textArea.topLeft()
            //(instead of textArea.topLeft() * painter-scale)
            textArea.moveTopLeft( textScale.inverted().map(textArea.topLeft()) );

            //paint text fragment
            drawTextFragment(  paint,
                               textArea,
                               unistr,
                               &_image[loc(x,y)] ); //,
            //0,
            //!_isPrinting );

            _fixedFont = save__fixedFont;

            //reset back to single-width, single-height _lines
            paint->setWorldMatrix(textScale.inverted(), true);

            if (y < _lineProperties.size()-1)
            {
                //double-height _lines are represented by two adjacent _lines
                //containing the same characters
                //both _lines will have the LINE_DOUBLEHEIGHT attribute.
                //If the current line has the LINE_DOUBLEHEIGHT attribute,
                //we can therefore skip the next line
                if (_lineProperties[y] & LINE_DOUBLEHEIGHT)
                    y++;
            }

            x += len - 1;
        }
    }
}


void KTerminalDisplay::drawLineCharString( QPainter* painter, qreal x, qreal y, const QString& str,
                                           const Character* attributes)
{
    const QPen& currentPen = painter->pen();

    if ( (attributes->rendition & RE_BOLD) && _boldIntense )
    {
        QPen boldPen(currentPen);
        boldPen.setWidth(3);
        painter->setPen( boldPen );
    }

    for (int i=0 ; i < str.length(); i++)
    {
        uchar code = str[i].cell();
        if (LineChars[code])
            drawLineChar(painter, x + (_fontWidth*i), y, _fontWidth, _fontHeight, code);
    }

    painter->setPen( currentPen );
}

void KTerminalDisplay::drawBackground(QPainter* painter, const QRectF &rect, const QColor& backgroundColor, bool useOpacitySetting )
{
    // the area of the widget showing the contents of the terminal display is drawn
    // using the background color from the color scheme set with setColorTable()

    QRectF contentsRect = rect;

    if ( HAVE_TRANSPARENCY && qAlpha(_blendColor) < 0xff && useOpacitySetting )
    {
        QColor color(backgroundColor);
        color.setAlpha(qAlpha(_blendColor));

        painter->save();
        painter->setCompositionMode(QPainter::CompositionMode_Source);
        painter->fillRect(contentsRect, color);
        painter->restore();
    }
    else
        painter->fillRect(contentsRect, backgroundColor);

}

void KTerminalDisplay::drawCursor(QPainter* painter,
                                  const QRectF& rect,
                                  const QColor& foregroundColor,
                                  const QColor& /*backgroundColor*/,
                                  bool& invertCharacterColor)
{
    QRectF cursorRect = rect;
    cursorRect.setHeight(_fontHeight - _lineSpacing - 1);

    if (!_cursorBlinking)
    {
        if ( _cursorColor.isValid() )
            painter->setPen(_cursorColor);
        else
            painter->setPen(foregroundColor);

        if ( _cursorShape == BlockCursor )
        {
            // draw the cursor outline, adjusting the area so that
            // it is draw entirely inside 'rect'
            int penWidth = qMax(1,painter->pen().width());

            painter->drawRect(cursorRect.adjusted( penWidth/2,
                                                   penWidth/2,
                                                   - penWidth/2 - penWidth%2,
                                                   - penWidth/2 - penWidth%2));
            if ( hasFocus() )
            {
                painter->fillRect(cursorRect, _cursorColor.isValid() ? _cursorColor : foregroundColor);

                if ( !_cursorColor.isValid() )
                {
                    // invert the colour used to draw the text to ensure that the character at
                    // the cursor position is readable
                    invertCharacterColor = true;
                }
            }
        }
        else if ( _cursorShape == UnderlineCursor )
            painter->drawLine(cursorRect.left(),
                              cursorRect.bottom(),
                              cursorRect.right(),
                              cursorRect.bottom());
        else if ( _cursorShape == IBeamCursor )
            painter->drawLine(cursorRect.left(),
                              cursorRect.top(),
                              cursorRect.left(),
                              cursorRect.bottom());

    }
}

void KTerminalDisplay::drawCharacters(QPainter* painter,
                                      const QRectF& rect,
                                      const QString& text,
                                      const Character* style,
                                      bool invertCharacterColor)
{
    // don't draw text which is currently blinking
    if ( _blinking && (style->rendition & RE_BLINK) )
        return;

    // setup bold and underline
    bool useBold;
    ColorEntry::FontWeight weight = style->fontWeight(_colorTable);
    if (weight == ColorEntry::UseCurrentFormat)
        useBold = ((style->rendition & RE_BOLD) && _boldIntense) || m_font.bold();
    else
        useBold = (weight == ColorEntry::Bold) ? true : false;
    bool useUnderline = style->rendition & RE_UNDERLINE || m_font.underline();

    QFont font  = m_font;
    QFont font_ = painter->font();
    if (    font.bold() != useBold
            || font.underline() != useUnderline )
    {
        //font.setBold(useBold);
        font.setUnderline(useUnderline);
    }

#ifdef Q_WS_UBUNTU
#if QT_VERSION >= 0x040700
    font.setStyleStrategy(QFont::ForceIntegerMetrics);
#else
#warning "Correct handling of the QFont metrics requited Qt>=4.7"
#endif
#endif

    painter->setFont(font);

    // setup pen
    const CharacterColor& textColor = ( invertCharacterColor ? style->backgroundColor : style->foregroundColor );
    const QColor color = textColor.color(_colorTable);
    QPen pen = painter->pen();
    if ( pen.color() != color )
    {
        pen.setColor(color);
        painter->setPen(color);
    }

    // draw text
    if ( isLineCharString(text) )
        drawLineCharString(painter,rect.x(),rect.y(),text,style);
    else
    {
        if (_bidiEnabled)
            painter->drawText(rect,text);
        else
            painter->drawText(rect,LTR_OVERRIDE_CHAR+text);
    }

    painter->setFont(font_);
}

void KTerminalDisplay::drawTextFragment(QPainter* painter ,
                                        const QRectF& rect,
                                        const QString& text,
                                        const Character* style)
{
    painter->save();

    // setup painter
    const QColor foregroundColor = style->foregroundColor.color(_colorTable);
    const QColor backgroundColor = style->backgroundColor.color(_colorTable);

    // draw background if different from the display's background color
    if ( backgroundColor != m_palette.background().color() )
        drawBackground(painter, rect, backgroundColor, false /* do not use transparency */);

    // draw cursor shape if the current character is the cursor
    // this may alter the foreground and background colors
    bool invertCharacterColor = false;
    if ( style->rendition & RE_CURSOR )
        drawCursor(painter, rect, foregroundColor,backgroundColor,invertCharacterColor);

    // draw text
    drawCharacters(painter, rect, text, style, invertCharacterColor);

    painter->restore();
}

void KTerminalDisplay::getCharacterPosition(const QPointF &widgetPoint, int& line, int& column) const
{
    //contentsBoundingRect()
    QRectF rect = m_widgetRect;

    column = qFloor((widgetPoint.x() + _fontWidth/2 - rect.left()-_leftMargin) / _fontWidth);
    line   = qFloor((widgetPoint.y() - rect.top()-_topMargin) / _fontHeight);

    if ( line < 0 )
        line = 0;
    if ( column < 0 )
        column = 0;

    if ( line >= _usedLines )
        line = _usedLines-1;

    // the column value returned can be equal to _usedColumns, which
    // is the position just after the last character displayed in a line.
    //
    // this is required so that the user can select characters in the right-most
    // column (or left-most for right-to-left input)
    if ( column > _usedColumns )
        column = _usedColumns;
}

QRectF KTerminalDisplay::preeditRect() const
{
    const int preeditLength = string_width(_inputMethodData.preeditString);

    if ( preeditLength == 0 )
        return QRectF();

    return QRectF(_leftMargin + _fontWidth*cursorPosition().x(),
                  _topMargin  + _fontHeight*cursorPosition().y(),
                  _fontWidth*preeditLength,
                  _fontHeight);
}

void KTerminalDisplay::drawInputMethodPreeditString(QPainter *painter , const QRectF &rect)
{
    if ( _inputMethodData.preeditString.isEmpty() )
        return;

    const QPoint cursorPos = cursorPosition();

    bool invertColors = false;
    const QColor background = _colorTable[DEFAULT_BACK_COLOR].color;
    const QColor foreground = _colorTable[DEFAULT_FORE_COLOR].color;
    const Character* style = &_image[loc(cursorPos.x(),cursorPos.y())];

    drawBackground(painter, rect, background,true);
    drawCursor(painter, rect, foreground,background,invertColors);
    drawCharacters(painter, rect,_inputMethodData.preeditString,style,invertColors);

    _inputMethodData.previousPreeditRect = rect;
}



void KTerminalDisplay::keyPressEvent(QKeyEvent *event)
{
    bool emitKeyPressSignal = true;

    // Keyboard-based navigation
    if ( event->modifiers() == Qt::ShiftModifier )
    {
        bool update = true;

        if ( event->key() == Qt::Key_PageUp )
        {
            _screenWindow->scrollBy( ScreenWindow::ScrollPages , -1 );
        }
        else if ( event->key() == Qt::Key_PageDown )
        {
            _screenWindow->scrollBy( ScreenWindow::ScrollPages , 1 );
        }
        else if ( event->key() == Qt::Key_Up )
        {
            _screenWindow->scrollBy( ScreenWindow::ScrollLines , -1 );
        }
        else if ( event->key() == Qt::Key_Down )
        {
            _screenWindow->scrollBy( ScreenWindow::ScrollLines , 1 );
        }
        else
            update = false;

        if ( update )
        {
            _screenWindow->setTrackOutput( _screenWindow->atEndOfOutput() );

            updateLineProperties();
            updateImage();

            // do not send key press to terminal
            emitKeyPressSignal = false;
        }
    }

    _actSel=0; // Key stroke implies a screen update, so TerminalDisplay won't
    // know where the current selection is.

    if (_hasBlinkingCursor)
    {
        _blinkCursorTimer->start(100); //WARN! HARDCODE
        if (_cursorBlinking)
            blinkCursorEvent();
        else
            _cursorBlinking = false;
    }

    if ( emitKeyPressSignal )
        emit keyPressedSignal(event);

    event->accept();
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
///                                   HELPER
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

//AutoScrollHandler::AutoScrollHandler(QQuickItem* parent)
//: QObject(parent)
//, _timerId(0)
//{
//    parent->installEventFilter(this);
//}
//void AutoScrollHandler::timerEvent(QTimerEvent* event)
//{
//    if (event->timerId() != _timerId)
//        return;

//    QMouseEvent mouseEvent(    QEvent::MouseMove,
//                              widget()->mapFromScene(QCursor::pos()),
//                              Qt::NoButton,
//                              Qt::LeftButton,
//                              Qt::NoModifier);

//    QGuiApplication::sendEvent(widget(),&mouseEvent);
//}
//bool AutoScrollHandler::eventFilter(QObject* watched,QEvent* event)
//{
//    Q_ASSERT( watched == parent() );
//    Q_UNUSED( watched );

//    QMouseEvent* mouseEvent = (QMouseEvent*)event;
//    switch (event->type())
//    {
//        case QEvent::MouseMove:
//        {
//            bool mouseInWidget = false; //widget()->rect().contains(mouseEvent->pos());

//            if (mouseInWidget)
//            {
//                if (_timerId)
//                    killTimer(_timerId);
//                _timerId = 0;
//            }
//            else
//            {
//                if (!_timerId && (mouseEvent->buttons() & Qt::LeftButton))
//                    _timerId = startTimer(100);
//            }
//                break;
//        }
//        case QEvent::MouseButtonRelease:
//            if (_timerId && (mouseEvent->buttons() & ~Qt::LeftButton))
//            {
//                killTimer(_timerId);
//                _timerId = 0;
//            }
//        break;
//        default:
//        break;
//    };

//    return false;
//}

//#include "TerminalDisplay.moc"
