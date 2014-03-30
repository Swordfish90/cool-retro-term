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

#ifndef TERMINALDISPLAY_H
#define TERMINALDISPLAY_H

#include <QtGui/QColor>
#include <QtCore/QPointer>

// Konsole
#include "Filter.h"
#include "Character.h"
#include "ksession.h"
//#include "konsole_export.h"
#define KONSOLEPRIVATE_EXPORT

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickPaintedItem>

class QTimer;
class QEvent;
class QKeyEvent;
class QTimerEvent;
//class KMenu;

extern unsigned short vt100_graphics[32];

class ScreenWindow;

/**
 * A widget which displays output from a terminal emulation and sends input keypresses and mouse activity
 * to the terminal.
 *
 * When the terminal emulation receives new output from the program running in the terminal,
 * it will update the display by calling updateImage().
 *
 * TODO More documentation
 */

class KONSOLEPRIVATE_EXPORT KTerminalDisplay : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(KSession *session       READ getSession      WRITE setSession     NOTIFY changedSession)
    Q_PROPERTY(QString  colorScheme    READ scheme()        WRITE setColorScheme NOTIFY changedScheme)
    Q_PROPERTY(QFont    font           READ getVTFont       WRITE setVTFont )
    Q_PROPERTY(bool activeFocusOnClick READ autoFocus       WRITE setAutoFocus   NOTIFY changedAutoFocus)
    Q_PROPERTY(bool ShowIMEOnClick     READ autoVKB         WRITE setAutoVKB     NOTIFY changedAutoVKB)



public:
    KTerminalDisplay(QQuickItem *parent = 0);
    ~KTerminalDisplay();

    QString scheme() { return m_scheme; }
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    /** Returns the terminal color palette used by the display. */
    const ColorEntry* colorTable() const;
    /** Sets the terminal color palette used by the display. */
    void setColorTable(const ColorEntry table[]);
    /**
     * Returns the seed used to generate random colors for the display
     * (in color schemes that support them).
     */
    uint randomSeed() const;

    /** Returns true if the cursor is set to blink or false otherwise. */
    bool blinkingCursor() { return _hasBlinkingCursor; }
    /** Specifies whether or not the cursor blinks. */
    void setBlinkingCursor(bool blink);

    /** Specifies whether or not text can blink. */
    void setBlinkingTextEnabled(bool blink);

    Q_INVOKABLE void setLineSpacing(uint);
    uint lineSpacing() const;

    Q_INVOKABLE void scrollDown();
    Q_INVOKABLE void scrollUp();

    void emitSelection(bool useXselection,bool appendReturn);

    /**
     * This enum describes the available shapes for the keyboard cursor.
     * See setKeyboardCursorShape()
     */
    enum KeyboardCursorShape
    {
        /** A rectangular block which covers the entire area of the cursor character. */
        BlockCursor,
        /**
         * A single flat line which occupies the space at the bottom of the cursor
         * character's area.
         */
        UnderlineCursor,
        /**
         * An cursor shaped like the capital letter 'I', similar to the IBeam
         * cursor used in Qt/KDE text editors.
         */
        IBeamCursor
    };
    /**
     * Sets the shape of the keyboard cursor.  This is the cursor drawn
     * at the position in the terminal where keyboard input will appear.
     *
     * In addition the terminal display widget also has a cursor for
     * the mouse pointer, which can be set using the QWidget::setCursor()
     * method.
     *
     * Defaults to BlockCursor
     */
    void setKeyboardCursorShape(KeyboardCursorShape shape);
    /**
     * Returns the shape of the keyboard cursor.  See setKeyboardCursorShape()
     */
    KeyboardCursorShape keyboardCursorShape() const;

    /**
     * Sets the color used to draw the keyboard cursor.
     *
     * The keyboard cursor defaults to using the foreground color of the character
     * underneath it.
     *
     * @param useForegroundColor If true, the cursor color will change to match
     * the foreground color of the character underneath it as it is moved, in this
     * case, the @p color parameter is ignored and the color of the character
     * under the cursor is inverted to ensure that it is still readable.
     * @param color The color to use to draw the cursor.  This is only taken into
     * account if @p useForegroundColor is false.
     */
    void setKeyboardCursorColor(bool useForegroundColor , const QColor& color);

    /**
     * Returns the color of the keyboard cursor, or an invalid color if the keyboard
     * cursor color is set to change according to the foreground color of the character
     * underneath it.
     */
    QColor keyboardCursorColor() const;

    // Show VKB
    void ShowVKB(bool show);

    /**
     * Returns the number of lines of text which can be displayed in the widget.
     *
     * This will depend upon the height of the widget and the current font.
     * See fontHeight()
     */
    int  lines()   { return _lines;   }
    /**
     * Returns the number of characters of text which can be displayed on
     * each line in the widget.
     *
     * This will depend upon the width of the widget and the current font.
     * See fontWidth()
     */
    int  columns() { return _columns; }

    /**
     * Returns the height of the characters in the font used to draw the text in the display.
     */
    int  fontHeight()   { return _fontHeight;   }
    /**
     * Returns the width of the characters in the display.
     * This assumes the use of a fixed-width font.
     */
    int  fontWidth()    { return _fontWidth; }



    /**
     * Sets which characters, in addition to letters and numbers,
     * are regarded as being part of a word for the purposes
     * of selecting words in the display by double clicking on them.
     *
     * The word boundaries occur at the first and last characters which
     * are either a letter, number, or a character in @p wc
     *
     * @param wc An array of characters which are to be considered parts
     * of a word ( in addition to letters and numbers ).
     */
    void setWordCharacters(const QString& wc);
    /**
     * Returns the characters which are considered part of a word for the
     * purpose of selecting words in the display with the mouse.
     *
     * @see setWordCharacters()
     */
    QString wordCharacters() { return _wordCharacters; }

    /**
     * Sets the type of effect used to alert the user when a 'bell' occurs in the
     * terminal session.
     *
     * The terminal session can trigger the bell effect by calling bell() with
     * the alert message.
     */
    void setBellMode(int mode);
    /**
     * Returns the type of effect used to alert the user when a 'bell' occurs in
     * the terminal session.
     *
     * See setBellMode()
     */
    int bellMode() { return _bellMode; }

    /**
     * This enum describes the different types of sounds and visual effects which
     * can be used to alert the user when a 'bell' occurs in the terminal
     * session.
     */
    enum BellMode
    {
        /** A system beep. */
        SystemBeepBell=0,
        /**
         * KDE notification.  This may play a sound, show a passive popup
         * or perform some other action depending on the user's settings.
         */
        NotifyBell=1,
        /** A silent, visual bell (eg. inverting the display's colors briefly) */
        VisualBell=2,
        /** No bell effects */
        NoBell=3
    };

    void setSelection(const QString &t);

    /**
     * Specified whether anti-aliasing of text in the terminal display
     * is enabled or not.  Defaults to enabled.
     */
    static void setAntialias( bool antialias ) { _antialiasText = antialias; }
    /**
     * Returns true if anti-aliasing of text in the terminal is enabled.
     */
    static bool antialias()                 { return _antialiasText;   }

    /**
     * Specifies whether characters with intense colors should be rendered
     * as bold. Defaults to true.
     */
    void setBoldIntense(bool value) { _boldIntense = value; }
    /**
     * Returns true if characters with intense colors are rendered in bold.
     */
    bool getBoldIntense() { return _boldIntense; }

    /**
     * Sets the status of the BiDi rendering inside the terminal display.
     * Defaults to disabled.
     */
    void setBidiEnabled(bool set) { _bidiEnabled=set; }
    /**
     * Returns the status of the BiDi rendering in this widget.
     */
    bool isBidiEnabled() { return _bidiEnabled; }

    /**
     * Sets the terminal screen section which is displayed in this widget.
     * When updateImage() is called, the display fetches the latest character image from the
     * the associated terminal screen window.
     *
     * In terms of the model-view paradigm, the ScreenWindow is the model which is rendered
     * by the TerminalDisplay.
     */
    void setScreenWindow( ScreenWindow* window );
    /** Returns the terminal screen section which is displayed in this widget.  See setScreenWindow() */
    ScreenWindow* screenWindow() const;

    static bool HAVE_TRANSPARENCY;
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////




public slots:
    void forcedFocus();
    void setColorScheme(const QString &name);
    QStringList availableColorSchemes();

    void click(qreal x, qreal y);

    bool autoFocus() { return m_focusOnClick; }
    void setAutoFocus(bool au);
    bool autoVKB() { return m_showVKBonClick; }
    void setAutoVKB(bool au);


    /** Returns the font used to draw characters in the display */
    QFont getVTFont() { return m_font; }

    /**
     * Sets the font used to draw the display.  Has no effect if @p font
     * is larger than the size of the display itself.
     */
    void setVTFont(const QFont& font);

    /**
     * Scroll to the bottom of the terminal (reset scrolling).
     */
    void scrollToEnd();

    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    /**
     * Causes the terminal display to fetch the latest character image from the associated
     * terminal screen ( see setScreenWindow() ) and redraw the display.
     */
    void updateImage();
    /**
     * Causes the terminal display to fetch the latest line status flags from the
     * associated terminal screen ( see setScreenWindow() ).
     */
    void updateLineProperties();

    /** Copies the selected text to the clipboard. */
    void copyClipboard();
    /**
     * Pastes the content of the clipboard into the
     * display.
     */
    void pasteClipboard();
    /**
     * Pastes the content of the selection into the
     * display.
     */
    void pasteSelection();

    /**
       * Changes whether the flow control warning box should be shown when the flow control
       * stop key (Ctrl+S) are pressed.
       */
    void setFlowControlWarningEnabled(bool enabled);
    /**
     * Returns true if the flow control warning box is enabled.
     * See outputSuspended() and setFlowControlWarningEnabled()
     */
    bool flowControlWarningEnabled() const
    { return _flowControlWarningEnabled; }

    /**
     * Causes the widget to display or hide a message informing the user that terminal
     * output has been suspended (by using the flow control key combination Ctrl+S)
     *
     * @param suspended True if terminal output has been suspended and the warning message should
     *                     be shown or false to indicate that terminal output has been resumed and that
     *                     the warning message should disappear.
     */
    //void outputSuspended(bool suspended);

    /**
     * Shows a notification that a bell event has occurred in the terminal.
     * TODO: More documentation here
     */
    void bell(const QString& message);

    /**
     * Sets the background of the display to the specified color.
     * @see setColorTable(), setForegroundColor()
     */
    void setBackgroundColor(const QColor& color);

    /**
     * Sets the text of the display to the specified color.
     * @see setColorTable(), setBackgroundColor()
     */
    void setForegroundColor(const QColor& color);

    void selectionChanged();
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////

    void setSession(KSession * session);
    KSession * getSession() const { return m_session; }

signals:
    void changedScheme(QString scheme);
    void changedAutoVKB(bool au);
    void changedAutoFocus(bool au);

    void updatedImage();
    void clicked();

    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    /**
     * Emitted when the user presses a key whilst the terminal widget has focus.
     */
    void keyPressedSignal(QKeyEvent *e);

    void changedFontMetricSignal(int height, int width);
    void changedContentSizeSignal(int height, int width);

    /**
     * Emitted when the user right clicks on the display, or right-clicks with the Shift
     * key held down if usesMouse() is true.
     *
     * This can be used to display a context menu.
     */
    void configureRequest(const QPoint& position);

    /**
     * When a shortcut which is also a valid terminal key sequence is pressed while
     * the terminal widget  has focus, this signal is emitted to allow the host to decide
     * whether the shortcut should be overridden.
     * When the shortcut is overridden, the key sequence will be sent to the terminal emulation instead
     * and the action associated with the shortcut will not be triggered.
     *
     * @p override is set to false by default and the shortcut will be triggered as normal.
     */
    void overrideShortcutCheck(QKeyEvent* keyEvent,bool& override);
    void isBusySelecting(bool);
    //void sendStringToEmu(const char*);

    // qtermwidget signals
    void copyAvailable(bool);
    void termGetFocus();
    void termLostFocus();
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////

    void changedSession(KSession *session);


protected:
    void paint (QPainter * painter);
    void keyPressEvent(QKeyEvent *event);
    bool event( QEvent *);

    void geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry);
    QRect geometryRound(const QRectF &r) const;

    void mousePressEvent(QMouseEvent*ev);
//    void mouseReleaseEvent( QMouseEvent* );
//    void mouseMoveEvent( QMouseEvent* );

    void focusInEvent(QFocusEvent* event);
    void focusOutEvent(QFocusEvent* event);



    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    void fontChange(const QFont &font);
    void extendSelection(const QPoint &pos );

    // classifies the 'ch' into one of three categories
    // and returns a character to indicate which category it is in
    //
    //     - A space (returns ' ')
    //     - Part of a word (returns 'a')
    //     - Other characters (returns the input character)
    QChar charClass(QChar ch) const;

    void clearImage();

    // reimplemented
    // cath for UT Soft Keyboard QInputMethodEvent
    void inputMethodEvent ( QInputMethodEvent* event );
    void inputMethodQuery( QInputMethodQueryEvent* event );
    QVariant inputMethodQuery( Qt::InputMethodQuery query ) const;
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////


protected slots:
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    void blinkEvent();
    void blinkCursorEvent();

    //Renables bell noises and visuals.  Used to disable further bells for a short period of time
    //after emitting the first in a sequence of bell events.
    void enableBell();
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////


private slots:
    void swapColorTable();

private:
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    // -- Drawing helpers --

    // divides the part of the display specified by 'rect' into
    // fragments according to their colors and styles and calls
    // drawTextFragment() to draw the fragments
    void drawContents(QPainter *paint, QRectF &rect);

    // draws a section of text, all the text in this section
    // has a common color and style
    void drawTextFragment(QPainter *painter, const QRectF &rect,
                          const QString& text, const Character* style);

    // draws the background for a text fragment
    // if useOpacitySetting is true then the color's alpha value will be set to
    // the display's transparency (set with setOpacity()), otherwise the background
    // will be drawn fully opaque
    void drawBackground(QPainter *painter, const QRectF& rect, const QColor& color,
                        bool useOpacitySetting);

    // draws the cursor character
    void drawCursor(QPainter *painter, const QRectF &rect , const QColor& foregroundColor,
                                       const QColor& backgroundColor , bool& invertColors);

    // draws the characters or line graphics in a text fragment
    void drawCharacters(QPainter *painter, const QRectF &rect,  const QString& text,
                                           const Character* style, bool invertCharacterColor);

    // draws a string of line graphics
    void drawLineCharString(QPainter *painter, qreal x, qreal y,
                            const QString& str, const Character* attributes);

    // draws the preedit string for input methods
    void drawInputMethodPreeditString(QPainter *painter , const QRectF& rect);

    // --

    // maps an area in the character image to an area on the widget
    QRect imageToWidget(const QRect& imageArea) const;

    // maps a point on the widget to the position ( ie. line and column )
    // of the character at that point.
    void getCharacterPosition(const QPointF& widgetPoint,int& line,int& column) const;

    // the area where the preedit string for input methods will be draw
    QRectF preeditRect() const;

    // scrolls the image by a number of lines.
    // 'lines' may be positive ( to scroll the image down )
    // or negative ( to scroll the image up )
    // 'region' is the part of the image to scroll - currently only
    // the top, bottom and height of 'region' are taken into account,
    // the left and right are ignored.
    void scrollImage(int lines , const QRect& region);

    void calcGeometry();
    void propagateSize();
    void updateImageSize();
    void makeImage();

    // returns the position of the cursor in columns and lines
    QPoint cursorPosition() const;

    // redraws the cursor
    void updateCursor();

    bool handleShortcutOverrideEvent(QKeyEvent* event);
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
    * Sets the seed used to generate random colors for the display
    * (in color schemes that support them).
    */
    void setRandomSeed(uint seed);



    /////////////////////////////////////////////////////////////////////////////////////
    ///                                 MEMBERS
    /////////////////////////////////////////////////////////////////////////////////////
    QFont       m_font;
    QPalette    m_palette;
    KSession   *m_session;
    QString     m_scheme;

    bool m_focusOnClick;
    bool m_showVKBonClick;

    QQuickItem *m_parent;
    QRectF      m_widgetRect;

    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////
    // the window onto the terminal screen which this display
    // is currently showing.
    QPointer<ScreenWindow> _screenWindow;

    bool   _allowBell;
    bool   _fixedFont;     // has fixed pitch
    int    _fontHeight;    // height
    qreal  _fontWidth;     // width
    int    _fontAscent;    // ascend
    bool   _boldIntense;   // Whether intense colors should be rendered with bold font

    qreal  _leftMargin;   // offset
    qreal  _topMargin;    // offset

    int _lines;      // the number of lines that can be displayed in the widget
    int _columns;    // the number of columns that can be displayed in the widget

    int _usedLines;  // the number of lines that are actually being used, this will be less
                     // than 'lines' if the character image provided with setImage() is smaller
                     // than the maximum image size which can be displayed

    int _usedColumns; // the number of columns that are actually being used, this will be less
                      // than 'columns' if the character image provided with setImage() is smaller
                      // than the maximum image size which can be displayed

    qreal _contentHeight;
    qreal _contentWidth;

    Character* _image; // [lines][columns]
                       // only the area [usedLines][usedColumns] in the image contains valid data

    int _imageSize;
    QVector<LineProperty> _lineProperties;

    ColorEntry _colorTable[TABLE_COLORS];
    uint _randomSeed;

    bool _resizing;
    bool _bidiEnabled;

    QPoint  _iPntSel;           // initial selection point
    QPoint  _pntSel;            // current selection point
    QPoint  _tripleSelBegin;    // help avoid flicker
    int     _actSel;            // selection state
    bool    _wordSelectionMode;
    bool    _lineSelectionMode;
    bool    _preserveLineBreaks;
    bool    _columnSelectionMode;

    QClipboard*  _clipboard;
    QString     _wordCharacters;
    int         _bellMode;

    bool _blinking;           // hide text in paintEvent
    bool _hasBlinker;         // has characters to blink
    bool _cursorBlinking;     // hide cursor in paintEvent
    bool _hasBlinkingCursor;  // has blinking cursor enabled
    bool _allowBlinkingText;  // allow text to blink

    bool _isFixedSize;           //Columns / lines are locked.
    QTimer* _blinkTimer;         // active when hasBlinker
    QTimer* _blinkCursorTimer;   // active when hasBlinkingCursor
    QTimer* _resizeTimer;

    bool _flowControlWarningEnabled;

    uint _lineSpacing;
    bool _colorsInverted; // true during visual bell
    QRgb _blendColor;

    KeyboardCursorShape _cursorShape;

    // custom cursor color.  if this is invalid then the foreground
    // color of the character under the cursor is used
    QColor _cursorColor;


    struct InputMethodData
    {
        QString preeditString;
        QRectF previousPreeditRect;
    };
    InputMethodData _inputMethodData;

    static bool _antialiasText;   // do we antialias or not

    //the delay in milliseconds between redrawing blinking text
    static const int TEXT_BLINK_DELAY = 500;
    static const int DEFAULT_LEFT_MARGIN = 1;
    static const int DEFAULT_TOP_MARGIN = 1;
    /////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////

public:
    static void setTransparencyEnabled(bool enable)
    {
        HAVE_TRANSPARENCY = enable;
    }
};

class AutoScrollHandler : public QObject
{
    Q_OBJECT

public:
    AutoScrollHandler(QQuickItem* parent);

protected:
    virtual void timerEvent(QTimerEvent* event);
    virtual bool eventFilter(QObject* watched,QEvent* event);

private:
    QQuickItem* widget() const { return static_cast<QQuickItem*>(parent()); }
    int _timerId;
};

#endif // TERMINALDISPLAY_H
