/*
    This file is part of Konsole, an X terminal.
    
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

#ifndef EMULATION_H
#define EMULATION_H

// System
#include <stdio.h>

// Qt 
#include <QtGui/QKeyEvent>
//#include <QPointer>
#include <QtCore/QTextCodec>
#include <QtCore/QTextStream>
#include <QtCore/QTimer>

// Konsole
//#include "konsole_export.h"
#define KONSOLEPRIVATE_EXPORT

class KeyboardTranslator;
class HistoryType;
class Screen;
class ScreenWindow;
class TerminalCharacterDecoder;

/** 
 * This enum describes the available states which 
 * the terminal emulation may be set to.
 *
 * These are the values used by Emulation::stateChanged() 
 */
enum 
{ 
    /** The emulation is currently receiving user input. */
    NOTIFYNORMAL=0, 
    /** 
     * The terminal program has triggered a bell event
     * to get the user's attention.
     */
    NOTIFYBELL=1, 
    /** 
     * The emulation is currently receiving data from its 
     * terminal input.
     */
    NOTIFYACTIVITY=2,

    // unused here? 
    NOTIFYSILENCE=3 
};

/**
 * Base class for terminal emulation back-ends.
 *
 * The back-end is responsible for decoding an incoming character stream and 
 * producing an output image of characters.
 *
 * When input from the terminal is received, the receiveData() slot should be called with
 * the data which has arrived.  The emulation will process the data and update the 
 * screen image accordingly.  The codec used to decode the incoming character stream
 * into the unicode characters used internally can be specified using setCodec() 
 *
 * The size of the screen image can be specified by calling setImageSize() with the 
 * desired number of lines and columns.  When new lines are added, old content
 * is moved into a history store, which can be set by calling setHistory(). 
 *
 * The screen image can be accessed by creating a ScreenWindow onto this emulation 
 * by calling createWindow().  Screen windows provide access to a section of the 
 * output.  Each screen window covers the same number of lines and columns as the 
 * image size returned by imageSize().  The screen window can be moved up and down
 * and provides transparent access to both the current on-screen image and the 
 * previous output.  The screen windows emit an outputChanged signal
 * when the section of the image they are looking at changes.
 * Graphical views can then render the contents of a screen window, listening for notifications
 * of output changes from the screen window which they are associated with and updating 
 * accordingly. 
 *
 * The emulation also is also responsible for converting input from the connected views such
 * as keypresses and mouse activity into a character string which can be sent
 * to the terminal program.  Key presses can be processed by calling the sendKeyEvent() slot,
 * while mouse events can be processed using the sendMouseEvent() slot.  When the character
 * stream has been produced, the emulation will emit a sendData() signal with a pointer
 * to the character buffer.  This data should be fed to the standard input of the terminal
 * process.  The translation of key presses into an output character stream is performed
 * using a lookup in a set of key bindings which map key sequences to output
 * character sequences.  The name of the key bindings set used can be specified using
 * setKeyBindings()
 *
 * The emulation maintains certain state information which changes depending on the 
 * input received.  The emulation can be reset back to its starting state by calling 
 * reset().  
 *
 * The emulation also maintains an activity state, which specifies whether
 * terminal is currently active ( when data is received ), normal
 * ( when the terminal is idle or receiving user input ) or trying
 * to alert the user ( also known as a "Bell" event ).  The stateSet() signal
 * is emitted whenever the activity state is set.  This can be used to determine
 * how long the emulation has been active/idle for and also respond to
 * a 'bell' event in different ways.
 */
class KONSOLEPRIVATE_EXPORT Emulation : public QObject
{ 
Q_OBJECT

public:
 
   /** Constructs a new terminal emulation */ 
   Emulation();
  ~Emulation();

  /**
   * Creates a new window onto the output from this emulation.  The contents
   * of the window are then rendered by views which are set to use this window using the
   * TerminalDisplay::setScreenWindow() method.
   */
  ScreenWindow* createWindow();

  /** Returns the size of the screen image which the emulation produces */
  QSize imageSize() const;

  /**
   * Returns the total number of lines, including those stored in the history.
   */ 
  int lineCount() const;

  /** 
   * Sets the history store used by this emulation.  When new lines
   * are added to the output, older lines at the top of the screen are transferred to a history
   * store.   
   *
   * The number of lines which are kept and the storage location depend on the 
   * type of store.
   */
  void setHistory(const HistoryType&);
  /** Returns the history store used by this emulation.  See setHistory() */
  const HistoryType& history() const;
  /** Clears the history scroll. */
  void clearHistory();

  /** 
   * Copies the output history from @p startLine to @p endLine 
   * into @p stream, using @p decoder to convert the terminal
   * characters into text. 
   *
   * @param decoder A decoder which converts lines of terminal characters with 
   * appearance attributes into output text.  PlainTextDecoder is the most commonly
   * used decoder.
   * @param startLine Index of first line to copy
   * @param endLine Index of last line to copy
   */
  virtual void writeToStream(TerminalCharacterDecoder* decoder,int startLine,int endLine);
  
  /** Returns the codec used to decode incoming characters.  See setCodec() */
  const QTextCodec* codec() const { return _codec; }
  /** Sets the codec used to decode incoming characters.  */
  void setCodec(const QTextCodec*);

  /** 
   * Convenience method.  
   * Returns true if the current codec used to decode incoming
   * characters is UTF-8
   */
  bool utf8() const
  { Q_ASSERT(_codec); return _codec->mibEnum() == 106; }
  

  /** TODO Document me */
  virtual char eraseChar() const;

  /** 
   * Sets the key bindings used to key events
   * ( received through sendKeyEvent() ) into character
   * streams to send to the terminal.
   */
  void setKeyBindings(const QString& name);
  /** 
   * Returns the name of the emulation's current key bindings.
   * See setKeyBindings()
   */
  QString keyBindings() const;

  /** 
   * Copies the current image into the history and clears the screen.
   */
  virtual void clearEntireScreen() =0;

  /** Resets the state of the terminal. */
  virtual void reset() =0;

  /** 
   * Returns true if the active terminal program wants
   * mouse input events.
   *
   * The programUsesMouseChanged() signal is emitted when this
   * changes.
   */
  bool programUsesMouse() const;

public slots: 

  /** Change the size of the emulation's image */
  virtual void setImageSize(int lines, int columns);
  
  /** 
   * Interprets a sequence of characters and sends the result to the terminal.
   * This is equivalent to calling sendKeyEvent() for each character in @p text in succession.
   */
  virtual void sendText(const QString& text) = 0;

  /** 
   * Interprets a key press event and emits the sendData() signal with
   * the resulting character stream. 
   */
  virtual void sendKeyEvent(QKeyEvent*);
 
  /** 
   * Converts information about a mouse event into an xterm-compatible escape
   * sequence and emits the character sequence via sendData()
   */
  virtual void sendMouseEvent(int buttons, int column, int line, int eventType);
  
  /**
   * Sends a string of characters to the foreground terminal process. 
   *
   * @param string The characters to send.  
   * @param length Length of @p string or if set to a negative value, @p string will
   * be treated as a null-terminated string and its length will be determined automatically.
   */
  virtual void sendString(const char* string, int length = -1) = 0;

  /** 
   * Processes an incoming stream of characters.  receiveData() decodes the incoming
   * character buffer using the current codec(), and then calls receiveChar() for
   * each unicode character in the resulting buffer.  
   *
   * receiveData() also starts a timer which causes the outputChanged() signal
   * to be emitted when it expires.  The timer allows multiple updates in quick
   * succession to be buffered into a single outputChanged() signal emission.
   *
   * @param buffer A string of characters received from the terminal program.
   * @param len The length of @p buffer
   */
  void receiveData(const char* buffer,int len);

signals:

  /** 
   * Emitted when a buffer of data is ready to send to the 
   * standard input of the terminal.
   *
   * @param data The buffer of data ready to be sent
   * @param len The length of @p data in bytes
   */
  void sendData(const char* data,int len);

  /** 
   * Requests that sending of input to the emulation
   * from the terminal process be suspended or resumed.
   *
   * @param suspend If true, requests that sending of 
   * input from the terminal process' stdout be 
   * suspended.  Otherwise requests that sending of
   * input be resumed. 
   */
  void lockPtyRequest(bool suspend);

  /**
   * Requests that the pty used by the terminal process
   * be set to UTF 8 mode.  
   *
   * TODO: More documentation
   */
  void useUtf8Request(bool);

  /**
   * Emitted when the activity state of the emulation is set.
   *
   * @param state The new activity state, one of NOTIFYNORMAL, NOTIFYACTIVITY
   * or NOTIFYBELL
   */
  void stateSet(int state);

  /** TODO Document me */
  void zmodemDetected();


  /**
   * Requests that the color of the text used
   * to represent the tabs associated with this
   * emulation be changed.  This is a Konsole-specific
   * extension from pre-KDE 4 times.
   *
   * TODO: Document how the parameter works.
   */
  void changeTabTextColorRequest(int color);

  /** 
   * This is emitted when the program running in the shell indicates whether or
   * not it is interested in mouse events.
   *
   * @param usesMouse This will be true if the program wants to be informed about
   * mouse events or false otherwise.
   */
  void programUsesMouseChanged(bool usesMouse);

  /** 
   * Emitted when the contents of the screen image change.
   * The emulation buffers the updates from successive image changes,
   * and only emits outputChanged() at sensible intervals when
   * there is a lot of terminal activity.
   *
   * Normally there is no need for objects other than the screen windows
   * created with createWindow() to listen for this signal.
   *
   * ScreenWindow objects created using createWindow() will emit their
   * own outputChanged() signal in response to this signal. 
   */
  void outputChanged();

  /**
   * Emitted when the program running in the terminal wishes to update the 
   * session's title.  This also allows terminal programs to customize other
   * aspects of the terminal emulation display. 
   *
   * This signal is emitted when the escape sequence "\033]ARG;VALUE\007"
   * is received in the input string, where ARG is a number specifying what
   * should change and VALUE is a string specifying the new value.
   *
   * TODO:  The name of this method is not very accurate since this method
   * is used to perform a whole range of tasks besides just setting
   * the user-title of the session.    
   *
   * @param title Specifies what to change.
   * <ul>
   * <li>0 - Set window icon text and session title to @p newTitle</li>
   * <li>1 - Set window icon text to @p newTitle</li>
   * <li>2 - Set session title to @p newTitle</li>
   * <li>11 - Set the session's default background color to @p newTitle,
   *         where @p newTitle can be an HTML-style string ("#RRGGBB") or a named
   *         color (eg 'red', 'blue').  
   *         See http://doc.trolltech.com/4.2/qcolor.html#setNamedColor for more
   *         details.
   * </li>
   * <li>31 - Supposedly treats @p newTitle as a URL and opens it (NOT IMPLEMENTED)</li>
   * <li>32 - Sets the icon associated with the session.  @p newTitle is the name 
   *    of the icon to use, which can be the name of any icon in the current KDE icon
   *    theme (eg: 'konsole', 'kate', 'folder_home')</li>
   * </ul>
   * @param newTitle Specifies the new title 
   */

  void titleChanged(int title,const QString& newTitle);

  /**
   * Emitted when the program running in the terminal changes the
   * screen size.
   */
  void imageSizeChanged(int lineCount , int columnCount);

  /** 
   * Emitted when the terminal program requests to change various properties
   * of the terminal display.  
   *
   * A profile change command occurs when a special escape sequence, followed
   * by a string containing a series of name and value pairs is received.
   * This string can be parsed using a ProfileCommandParser instance.
   *
   * @param text A string expected to contain a series of key and value pairs in
   * the form:  name=value;name2=value2 ...
   */
  void profileChangeCommandReceived(const QString& text);

  /** 
   * Emitted when a flow control key combination ( Ctrl+S or Ctrl+Q ) is pressed.
   * @param suspendKeyPressed True if Ctrl+S was pressed to suspend output or Ctrl+Q to
   * resume output.
   */
  void flowControlKeyPressed(bool suspendKeyPressed);

protected:
  virtual void setMode(int mode) = 0;
  virtual void resetMode(int mode) = 0;
   
  /** 
   * Processes an incoming character.  See receiveData()
   * @p ch A unicode character code. 
   */
  virtual void receiveChar(int ch);

  /** 
   * Sets the active screen.  The terminal has two screens, primary and alternate.
   * The primary screen is used by default.  When certain interactive programs such
   * as Vim are run, they trigger a switch to the alternate screen.
   *
   * @param index 0 to switch to the primary screen, or 1 to switch to the alternate screen
   */
  void setScreen(int index); 

  enum EmulationCodec
  {
      LocaleCodec = 0,
      Utf8Codec   = 1
  };
  void setCodec(EmulationCodec codec); // codec number, 0 = locale, 1=utf8


  QList<ScreenWindow*> _windows;
  
  Screen* _currentScreen;  // pointer to the screen which is currently active, 
                            // this is one of the elements in the screen[] array

  Screen* _screen[2];      // 0 = primary screen ( used by most programs, including the shell
                            //                      scrollbars are enabled in this mode )
                            // 1 = alternate      ( used by vi , emacs etc.
                            //                      scrollbars are not enabled in this mode )
                            
  
  //decodes an incoming C-style character stream into a unicode QString using 
  //the current text codec.  (this allows for rendering of non-ASCII characters in text files etc.)
  const QTextCodec* _codec;
  QTextDecoder* _decoder;
  const KeyboardTranslator* _keyTranslator; // the keyboard layout

protected slots:
  /** 
   * Schedules an update of attached views.
   * Repeated calls to bufferedUpdate() in close succession will result in only a single update,
   * much like the Qt buffered update of widgets. 
   */
  void bufferedUpdate();

private slots: 

  // triggered by timer, causes the emulation to send an updated screen image to each
  // view
  void showBulk(); 

  void usesMouseChanged(bool usesMouse);

private:
  bool _usesMouse;
  QTimer _bulkTimer1;
  QTimer _bulkTimer2;
  
};


#endif // ifndef EMULATION_H
