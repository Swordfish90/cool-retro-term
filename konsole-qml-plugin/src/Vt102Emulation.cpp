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
#include "Vt102Emulation.h"

// XKB
//#include <config-konsole.h>

// this allows konsole to be compiled without XKB and XTEST extensions
// even though it might be available on a particular system.
#if defined(AVOID_XKB)
    #undef HAVE_XKB
#endif

#if defined(HAVE_XKB)
    void scrolllock_set_off();
    void scrolllock_set_on();
#endif

// Standard
#include <stdio.h>
#include <unistd.h>
#include <assert.h>

// Qt
#include <QtCore/QEvent>
#include <QtGui/QKeyEvent>
#include <QtCore/QByteRef>

// KDE
//#include <kdebug.h>
//#include <klocale.h>

// Konsole
#include "KeyboardTranslator.h"
#include "Screen.h"

Vt102Emulation::Vt102Emulation()
    : Emulation(),
     _titleUpdateTimer(new QTimer(this))
{
  _titleUpdateTimer->setSingleShot(true);
  QObject::connect(_titleUpdateTimer , SIGNAL(timeout()) , this , SLOT(updateTitle()));

  initTokenizer();
  reset();
}

Vt102Emulation::~Vt102Emulation()
{}

void Vt102Emulation::clearEntireScreen()
{
  _currentScreen->clearEntireScreen();
  bufferedUpdate();
}

void Vt102Emulation::reset()
{
  resetTokenizer();
  resetModes();
  resetCharset(0);
  _screen[0]->reset();
  resetCharset(1);
  _screen[1]->reset();
  setCodec(LocaleCodec);

  bufferedUpdate();
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                     Processing the incoming byte stream                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/* Incoming Bytes Event pipeline

   This section deals with decoding the incoming character stream.
   Decoding means here, that the stream is first separated into `tokens'
   which are then mapped to a `meaning' provided as operations by the
   `Screen' class or by the emulation class itself.

   The pipeline proceeds as follows:

   - Tokenizing the ESC codes (onReceiveChar)
   - VT100 code page translation of plain characters (applyCharset)
   - Interpretation of ESC codes (processToken)

   The escape codes and their meaning are described in the
   technical reference of this program.
*/

// Tokens ------------------------------------------------------------------ --

/*
   Since the tokens are the central notion if this section, we've put them
   in front. They provide the syntactical elements used to represent the
   terminals operations as byte sequences.

   They are encodes here into a single machine word, so that we can later
   switch over them easily. Depending on the token itself, additional
   argument variables are filled with parameter values.

   The tokens are defined below:

   - CHR        - Printable characters     (32..255 but DEL (=127))
   - CTL        - Control characters       (0..31 but ESC (= 27), DEL)
   - ESC        - Escape codes of the form <ESC><CHR but `[]()+*#'>
   - ESC_DE     - Escape codes of the form <ESC><any of `()+*#%'> C
   - CSI_PN     - Escape codes of the form <ESC>'['     {Pn} ';' {Pn} C
   - CSI_PS     - Escape codes of the form <ESC>'['     {Pn} ';' ...  C
   - CSI_PR     - Escape codes of the form <ESC>'[' '?' {Pn} ';' ...  C
   - CSI_PE     - Escape codes of the form <ESC>'[' '!' {Pn} ';' ...  C
   - VT52       - VT52 escape codes
                  - <ESC><Chr>
                  - <ESC>'Y'{Pc}{Pc}
   - XTE_HA     - Xterm window/terminal attribute commands
                  of the form <ESC>`]' {Pn} `;' {Text} <BEL>
                  (Note that these are handled differently to the other formats)

   The last two forms allow list of arguments. Since the elements of
   the lists are treated individually the same way, they are passed
   as individual tokens to the interpretation. Further, because the
   meaning of the parameters are names (althought represented as numbers),
   they are includes within the token ('N').

*/

#define TY_CONSTRUCT(T,A,N) ( ((((int)N) & 0xffff) << 16) | ((((int)A) & 0xff) << 8) | (((int)T) & 0xff) )

#define TY_CHR(   )     TY_CONSTRUCT(0,0,0)
#define TY_CTL(A  )     TY_CONSTRUCT(1,A,0)
#define TY_ESC(A  )     TY_CONSTRUCT(2,A,0)
#define TY_ESC_CS(A,B)  TY_CONSTRUCT(3,A,B)
#define TY_ESC_DE(A  )  TY_CONSTRUCT(4,A,0)
#define TY_CSI_PS(A,N)  TY_CONSTRUCT(5,A,N)
#define TY_CSI_PN(A  )  TY_CONSTRUCT(6,A,0)
#define TY_CSI_PR(A,N)  TY_CONSTRUCT(7,A,N)

#define TY_VT52(A)    TY_CONSTRUCT(8,A,0)
#define TY_CSI_PG(A)  TY_CONSTRUCT(9,A,0)
#define TY_CSI_PE(A)  TY_CONSTRUCT(10,A,0)

#define MAX_ARGUMENT 4096

// Tokenizer --------------------------------------------------------------- --

/* The tokenizer's state

   The state is represented by the buffer (tokenBuffer, tokenBufferPos),
   and accompanied by decoded arguments kept in (argv,argc).
   Note that they are kept internal in the tokenizer.
*/

void Vt102Emulation::resetTokenizer()
{
  tokenBufferPos = 0;
  argc = 0;
  argv[0] = 0;
  argv[1] = 0;
}

void Vt102Emulation::addDigit(int digit)
{
  if (argv[argc] < MAX_ARGUMENT)
      argv[argc] = 10*argv[argc] + digit;
}

void Vt102Emulation::addArgument()
{
  argc = qMin(argc+1,MAXARGS-1);
  argv[argc] = 0;
}

void Vt102Emulation::addToCurrentToken(int cc)
{
  tokenBuffer[tokenBufferPos] = cc;
  tokenBufferPos = qMin(tokenBufferPos+1,MAX_TOKEN_LENGTH-1);
}

// Character Class flags used while decoding

#define CTL  1  // Control character
#define CHR  2  // Printable character
#define CPN  4  // TODO: Document me
#define DIG  8  // Digit
#define SCS 16  // TODO: Document me
#define GRP 32  // TODO: Document me
#define CPS 64  // Character which indicates end of window resize
                // escape sequence '\e[8;<row>;<col>t'

void Vt102Emulation::initTokenizer()
{
  int i;
  quint8* s;
  for(i = 0;i < 256; ++i)
    charClass[i] = 0;
  for(i = 0;i < 32; ++i)
    charClass[i] |= CTL;
  for(i = 32;i < 256; ++i)
    charClass[i] |= CHR;
  for(s = (quint8*)"@ABCDGHILMPSTXZcdfry"; *s; ++s)
    charClass[*s] |= CPN;
  // resize = \e[8;<row>;<col>t
  for(s = (quint8*)"t"; *s; ++s)
    charClass[*s] |= CPS;
  for(s = (quint8*)"0123456789"; *s; ++s)
    charClass[*s] |= DIG;
  for(s = (quint8*)"()+*%"; *s; ++s)
    charClass[*s] |= SCS;
  for(s = (quint8*)"()+*#[]%"; *s; ++s)
    charClass[*s] |= GRP;

  resetTokenizer();
}

/* Ok, here comes the nasty part of the decoder.

   Instead of keeping an explicit state, we deduce it from the
   token scanned so far. It is then immediately combined with
   the current character to form a scanning decision.

   This is done by the following defines.

   - P is the length of the token scanned so far.
   - L (often P-1) is the position on which contents we base a decision.
   - C is a character or a group of characters (taken from 'charClass').

   - 'cc' is the current character
   - 's' is a pointer to the start of the token buffer
   - 'p' is the current position within the token buffer

   Note that they need to applied in proper order.
*/

#define lec(P,L,C) (p == (P) && s[(L)] == (C))
#define lun(     ) (p ==  1  && cc >= 32 )
#define les(P,L,C) (p == (P) && s[L] < 256 && (charClass[s[(L)]] & (C)) == (C))
#define eec(C)     (p >=  3  && cc == (C))
#define ees(C)     (p >=  3  && cc < 256 && (charClass[cc] & (C)) == (C))
#define eps(C)     (p >=  3  && s[2] != '?' && s[2] != '!' && s[2] != '>' && cc < 256 && (charClass[cc] & (C)) == (C))
#define epp( )     (p >=  3  && s[2] == '?')
#define epe( )     (p >=  3  && s[2] == '!')
#define egt( )     (p >=  3  && s[2] == '>')
#define Xpe        (tokenBufferPos >= 2 && tokenBuffer[1] == ']')
#define Xte        (Xpe      && cc ==  7 )
#define ces(C)     (cc < 256 && (charClass[cc] & (C)) == (C) && !Xte)

#define ESC 27
#define CNTL(c) ((c)-'@')

// process an incoming unicode character
void Vt102Emulation::receiveChar(int cc)
{
  if (cc == 127)
    return; //VT100: ignore.

  if (ces(CTL))
  {
    // DEC HACK ALERT! Control Characters are allowed *within* esc sequences in VT100
    // This means, they do neither a resetTokenizer() nor a pushToToken(). Some of them, do
    // of course. Guess this originates from a weakly layered handling of the X-on
    // X-off protocol, which comes really below this level.
    if (cc == CNTL('X') || cc == CNTL('Z') || cc == ESC)
        resetTokenizer(); //VT100: CAN or SUB
    if (cc != ESC)
    {
        processToken(TY_CTL(cc+'@' ),0,0);
        return;
    }
  }
  // advance the state
  addToCurrentToken(cc);

  int* s = tokenBuffer;
  int  p = tokenBufferPos;

  if (getMode(MODE_Ansi))
  {
    if (lec(1,0,ESC)) { return; }
    if (lec(1,0,ESC+128)) { s[0] = ESC; receiveChar('['); return; }
    if (les(2,1,GRP)) { return; }
    if (Xte         ) { processWindowAttributeChange(); resetTokenizer(); return; }
    if (Xpe         ) { return; }
    if (lec(3,2,'?')) { return; }
    if (lec(3,2,'>')) { return; }
    if (lec(3,2,'!')) { return; }
    if (lun(       )) { processToken( TY_CHR(), applyCharset(cc), 0);   resetTokenizer(); return; }
    if (lec(2,0,ESC)) { processToken( TY_ESC(s[1]), 0, 0);              resetTokenizer(); return; }
    if (les(3,1,SCS)) { processToken( TY_ESC_CS(s[1],s[2]), 0, 0);      resetTokenizer(); return; }
    if (lec(3,1,'#')) { processToken( TY_ESC_DE(s[2]), 0, 0);           resetTokenizer(); return; }
    if (eps(    CPN)) { processToken( TY_CSI_PN(cc), argv[0],argv[1]);  resetTokenizer(); return; }

    // resize = \e[8;<row>;<col>t
    if (eps(CPS))
    {
        processToken( TY_CSI_PS(cc, argv[0]), argv[1], argv[2]);
        resetTokenizer();
        return;
    }

    if (epe(   )) { processToken( TY_CSI_PE(cc), 0, 0); resetTokenizer(); return; }
    if (ees(DIG)) { addDigit(cc-'0'); return; }
    if (eec(';')) { addArgument();    return; }
    for (int i=0;i<=argc;i++)
    {
        if (epp())
            processToken( TY_CSI_PR(cc,argv[i]), 0, 0);
        else if (egt())
            processToken( TY_CSI_PG(cc), 0, 0); // spec. case for ESC]>0c or ESC]>c
        else if (cc == 'm' && argc - i >= 4 && (argv[i] == 38 || argv[i] == 48) && argv[i+1] == 2)
        {
            // ESC[ ... 48;2;<red>;<green>;<blue> ... m -or- ESC[ ... 38;2;<red>;<green>;<blue> ... m
            i += 2;
            processToken( TY_CSI_PS(cc, argv[i-2]), COLOR_SPACE_RGB, (argv[i] << 16) | (argv[i+1] << 8) | argv[i+2]);
            i += 2;
        }
        else if (cc == 'm' && argc - i >= 2 && (argv[i] == 38 || argv[i] == 48) && argv[i+1] == 5)
        {
            // ESC[ ... 48;5;<index> ... m -or- ESC[ ... 38;5;<index> ... m
            i += 2;
            processToken( TY_CSI_PS(cc, argv[i-2]), COLOR_SPACE_256, argv[i]);
        }
        else
            processToken( TY_CSI_PS(cc,argv[i]), 0, 0);
    }
    resetTokenizer();
  }
  else
  {
    // VT52 Mode
    if (lec(1,0,ESC))
        return;
    if (les(1,0,CHR))
    {
        processToken( TY_CHR(), s[0], 0);
        resetTokenizer();
        return;
    }
    if (lec(2,1,'Y'))
        return;
    if (lec(3,1,'Y'))
        return;
    if (p < 4)
    {
        processToken( TY_VT52(s[1] ), 0, 0);
        resetTokenizer();
        return;
    }
    processToken( TY_VT52(s[1]), s[2], s[3]);
    resetTokenizer();
    return;
  }
}
void Vt102Emulation::processWindowAttributeChange()
{
  // Describes the window or terminal session attribute to change
  // See Session::UserTitleChange for possible values
  int attributeToChange = 0;
  int i;
  for (i = 2; i < tokenBufferPos     &&
              tokenBuffer[i] >= '0'  &&
              tokenBuffer[i] <= '9'; i++)
  {
    attributeToChange = 10 * attributeToChange + (tokenBuffer[i]-'0');
  }

  if (tokenBuffer[i] != ';')
  {
    reportDecodingError();
    return;
  }

  QString newValue;
  newValue.reserve(tokenBufferPos-i-2);
  for (int j = 0; j < tokenBufferPos-i-2; j++)
    newValue[j] = tokenBuffer[i+1+j];

  _pendingTitleUpdates[attributeToChange] = newValue;
  _titleUpdateTimer->start(20);
}

void Vt102Emulation::updateTitle()
{
    QListIterator<int> iter( _pendingTitleUpdates.keys() );
    while (iter.hasNext()) {
        int arg = iter.next();
        emit titleChanged( arg , _pendingTitleUpdates[arg] );
    }
    _pendingTitleUpdates.clear();
}

// Interpreting Codes ---------------------------------------------------------

/*
   Now that the incoming character stream is properly tokenized,
   meaning is assigned to them. These are either operations of
   the current _screen, or of the emulation class itself.

   The token to be interpreteted comes in as a machine word
   possibly accompanied by two parameters.

   Likewise, the operations assigned to, come with up to two
   arguments. One could consider to make up a proper table
   from the function below.

   The technical reference manual provides more information
   about this mapping.
*/

void Vt102Emulation::processToken(int token, int p, int q)
{
  switch (token)
  {

    case TY_CHR(         ) : _currentScreen->displayCharacter     (p         ); break; //UTF16

    //             127 DEL    : ignored on input

    case TY_CTL('@'      ) : /* NUL: ignored                      */ break;
    case TY_CTL('A'      ) : /* SOH: ignored                      */ break;
    case TY_CTL('B'      ) : /* STX: ignored                      */ break;
    case TY_CTL('C'      ) : /* ETX: ignored                      */ break;
    case TY_CTL('D'      ) : /* EOT: ignored                      */ break;
    case TY_CTL('E'      ) :      reportAnswerBack     (          ); break; //VT100
    case TY_CTL('F'      ) : /* ACK: ignored                      */ break;
    case TY_CTL('G'      ) : emit stateSet(NOTIFYBELL);
                                break; //VT100
    case TY_CTL('H'      ) : _currentScreen->backspace            (          ); break; //VT100
    case TY_CTL('I'      ) : _currentScreen->tab                  (          ); break; //VT100
    case TY_CTL('J'      ) : _currentScreen->newLine              (          ); break; //VT100
    case TY_CTL('K'      ) : _currentScreen->newLine              (          ); break; //VT100
    case TY_CTL('L'      ) : _currentScreen->newLine              (          ); break; //VT100
    case TY_CTL('M'      ) : _currentScreen->toStartOfLine        (          ); break; //VT100

    case TY_CTL('N'      ) :      useCharset           (         1); break; //VT100
    case TY_CTL('O'      ) :      useCharset           (         0); break; //VT100

    case TY_CTL('P'      ) : /* DLE: ignored                      */ break;
    case TY_CTL('Q'      ) : /* DC1: XON continue                 */ break; //VT100
    case TY_CTL('R'      ) : /* DC2: ignored                      */ break;
    case TY_CTL('S'      ) : /* DC3: XOFF halt                    */ break; //VT100
    case TY_CTL('T'      ) : /* DC4: ignored                      */ break;
    case TY_CTL('U'      ) : /* NAK: ignored                      */ break;
    case TY_CTL('V'      ) : /* SYN: ignored                      */ break;
    case TY_CTL('W'      ) : /* ETB: ignored                      */ break;
    case TY_CTL('X'      ) : _currentScreen->displayCharacter     (    0x2592); break; //VT100
    case TY_CTL('Y'      ) : /* EM : ignored                      */ break;
    case TY_CTL('Z'      ) : _currentScreen->displayCharacter     (    0x2592); break; //VT100
    case TY_CTL('['      ) : /* ESC: cannot be seen here.         */ break;
    case TY_CTL('\\'     ) : /* FS : ignored                      */ break;
    case TY_CTL(']'      ) : /* GS : ignored                      */ break;
    case TY_CTL('^'      ) : /* RS : ignored                      */ break;
    case TY_CTL('_'      ) : /* US : ignored                      */ break;

    case TY_ESC('D'      ) : _currentScreen->index                (          ); break; //VT100
    case TY_ESC('E'      ) : _currentScreen->nextLine             (          ); break; //VT100
    case TY_ESC('H'      ) : _currentScreen->changeTabStop        (true      ); break; //VT100
    case TY_ESC('M'      ) : _currentScreen->reverseIndex         (          ); break; //VT100
    case TY_ESC('Z'      ) :      reportTerminalType   (          ); break;
    case TY_ESC('c'      ) :      reset                (          ); break;

    case TY_ESC('n'      ) :      useCharset           (         2); break;
    case TY_ESC('o'      ) :      useCharset           (         3); break;
    case TY_ESC('7'      ) :      saveCursor           (          ); break;
    case TY_ESC('8'      ) :      restoreCursor        (          ); break;

    case TY_ESC('='      ) :          setMode      (MODE_AppKeyPad); break;
    case TY_ESC('>'      ) :        resetMode      (MODE_AppKeyPad); break;
    case TY_ESC('<'      ) :          setMode      (MODE_Ansi     ); break; //VT100

    case TY_ESC_CS('(', '0') :      setCharset           (0,    '0'); break; //VT100
    case TY_ESC_CS('(', 'A') :      setCharset           (0,    'A'); break; //VT100
    case TY_ESC_CS('(', 'B') :      setCharset           (0,    'B'); break; //VT100

    case TY_ESC_CS(')', '0') :      setCharset           (1,    '0'); break; //VT100
    case TY_ESC_CS(')', 'A') :      setCharset           (1,    'A'); break; //VT100
    case TY_ESC_CS(')', 'B') :      setCharset           (1,    'B'); break; //VT100

    case TY_ESC_CS('*', '0') :      setCharset           (2,    '0'); break; //VT100
    case TY_ESC_CS('*', 'A') :      setCharset           (2,    'A'); break; //VT100
    case TY_ESC_CS('*', 'B') :      setCharset           (2,    'B'); break; //VT100

    case TY_ESC_CS('+', '0') :      setCharset           (3,    '0'); break; //VT100
    case TY_ESC_CS('+', 'A') :      setCharset           (3,    'A'); break; //VT100
    case TY_ESC_CS('+', 'B') :      setCharset           (3,    'B'); break; //VT100

    case TY_ESC_CS('%', 'G') :      setCodec             (Utf8Codec   ); break; //LINUX
    case TY_ESC_CS('%', '@') :      setCodec             (LocaleCodec ); break; //LINUX

    case TY_ESC_DE('3'      ) : /* Double height line, top half    */
                                _currentScreen->setLineProperty( LINE_DOUBLEWIDTH , true );
                                _currentScreen->setLineProperty( LINE_DOUBLEHEIGHT , true );
                                    break;
    case TY_ESC_DE('4'      ) : /* Double height line, bottom half */
                                _currentScreen->setLineProperty( LINE_DOUBLEWIDTH , true );
                                _currentScreen->setLineProperty( LINE_DOUBLEHEIGHT , true );
                                    break;
    case TY_ESC_DE('5'      ) : /* Single width, single height line*/
                                _currentScreen->setLineProperty( LINE_DOUBLEWIDTH , false);
                                _currentScreen->setLineProperty( LINE_DOUBLEHEIGHT , false);
                                break;
    case TY_ESC_DE('6'      ) : /* Double width, single height line*/
                                _currentScreen->setLineProperty( LINE_DOUBLEWIDTH , true);
                                _currentScreen->setLineProperty( LINE_DOUBLEHEIGHT , false);
                                break;
    case TY_ESC_DE('8'      ) : _currentScreen->helpAlign            (          ); break;

// resize = \e[8;<row>;<col>t
    case TY_CSI_PS('t',   8) : setImageSize( q /* columns */, p /* lines */ );    break;

// change tab text color : \e[28;<color>t  color: 0-16,777,215
    case TY_CSI_PS('t',   28) : emit changeTabTextColorRequest      ( p        );          break;

    case TY_CSI_PS('K',   0) : _currentScreen->clearToEndOfLine     (          ); break;
    case TY_CSI_PS('K',   1) : _currentScreen->clearToBeginOfLine   (          ); break;
    case TY_CSI_PS('K',   2) : _currentScreen->clearEntireLine      (          ); break;
    case TY_CSI_PS('J',   0) : _currentScreen->clearToEndOfScreen   (          ); break;
    case TY_CSI_PS('J',   1) : _currentScreen->clearToBeginOfScreen (          ); break;
    case TY_CSI_PS('J',   2) : _currentScreen->clearEntireScreen    (          ); break;
    case TY_CSI_PS('J',      3) : clearHistory();                            break;
    case TY_CSI_PS('g',   0) : _currentScreen->changeTabStop        (false     ); break; //VT100
    case TY_CSI_PS('g',   3) : _currentScreen->clearTabStops        (          ); break; //VT100
    case TY_CSI_PS('h',   4) : _currentScreen->    setMode      (MODE_Insert   ); break;
    case TY_CSI_PS('h',  20) :          setMode      (MODE_NewLine  ); break;
    case TY_CSI_PS('i',   0) : /* IGNORE: attached printer          */ break; //VT100
    case TY_CSI_PS('l',   4) : _currentScreen->  resetMode      (MODE_Insert   ); break;
    case TY_CSI_PS('l',  20) :        resetMode      (MODE_NewLine  ); break;
    case TY_CSI_PS('s',   0) :      saveCursor           (          ); break;
    case TY_CSI_PS('u',   0) :      restoreCursor        (          ); break;

    case TY_CSI_PS('m',   0) : _currentScreen->setDefaultRendition  (          ); break;
    case TY_CSI_PS('m',   1) : _currentScreen->  setRendition     (RE_BOLD     ); break; //VT100
    case TY_CSI_PS('m',   4) : _currentScreen->  setRendition     (RE_UNDERLINE); break; //VT100
    case TY_CSI_PS('m',   5) : _currentScreen->  setRendition     (RE_BLINK    ); break; //VT100
    case TY_CSI_PS('m',   7) : _currentScreen->  setRendition     (RE_REVERSE  ); break;
    case TY_CSI_PS('m',  10) : /* IGNORED: mapping related          */ break; //LINUX
    case TY_CSI_PS('m',  11) : /* IGNORED: mapping related          */ break; //LINUX
    case TY_CSI_PS('m',  12) : /* IGNORED: mapping related          */ break; //LINUX
    case TY_CSI_PS('m',  22) : _currentScreen->resetRendition     (RE_BOLD     ); break;
    case TY_CSI_PS('m',  24) : _currentScreen->resetRendition     (RE_UNDERLINE); break;
    case TY_CSI_PS('m',  25) : _currentScreen->resetRendition     (RE_BLINK    ); break;
    case TY_CSI_PS('m',  27) : _currentScreen->resetRendition     (RE_REVERSE  ); break;

    case TY_CSI_PS('m',   30) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  0); break;
    case TY_CSI_PS('m',   31) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  1); break;
    case TY_CSI_PS('m',   32) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  2); break;
    case TY_CSI_PS('m',   33) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  3); break;
    case TY_CSI_PS('m',   34) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  4); break;
    case TY_CSI_PS('m',   35) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  5); break;
    case TY_CSI_PS('m',   36) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  6); break;
    case TY_CSI_PS('m',   37) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  7); break;

    case TY_CSI_PS('m',   38) : _currentScreen->setForeColor         (p,       q); break;

    case TY_CSI_PS('m',   39) : _currentScreen->setForeColor         (COLOR_SPACE_DEFAULT,  0); break;

    case TY_CSI_PS('m',   40) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  0); break;
    case TY_CSI_PS('m',   41) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  1); break;
    case TY_CSI_PS('m',   42) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  2); break;
    case TY_CSI_PS('m',   43) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  3); break;
    case TY_CSI_PS('m',   44) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  4); break;
    case TY_CSI_PS('m',   45) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  5); break;
    case TY_CSI_PS('m',   46) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  6); break;
    case TY_CSI_PS('m',   47) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  7); break;

    case TY_CSI_PS('m',   48) : _currentScreen->setBackColor         (p,       q); break;

    case TY_CSI_PS('m',   49) : _currentScreen->setBackColor         (COLOR_SPACE_DEFAULT,  1); break;

    case TY_CSI_PS('m',   90) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  8); break;
    case TY_CSI_PS('m',   91) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM,  9); break;
    case TY_CSI_PS('m',   92) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 10); break;
    case TY_CSI_PS('m',   93) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 11); break;
    case TY_CSI_PS('m',   94) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 12); break;
    case TY_CSI_PS('m',   95) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 13); break;
    case TY_CSI_PS('m',   96) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 14); break;
    case TY_CSI_PS('m',   97) : _currentScreen->setForeColor         (COLOR_SPACE_SYSTEM, 15); break;

    case TY_CSI_PS('m',  100) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  8); break;
    case TY_CSI_PS('m',  101) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM,  9); break;
    case TY_CSI_PS('m',  102) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 10); break;
    case TY_CSI_PS('m',  103) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 11); break;
    case TY_CSI_PS('m',  104) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 12); break;
    case TY_CSI_PS('m',  105) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 13); break;
    case TY_CSI_PS('m',  106) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 14); break;
    case TY_CSI_PS('m',  107) : _currentScreen->setBackColor         (COLOR_SPACE_SYSTEM, 15); break;

    case TY_CSI_PS('n',   5) :      reportStatus         (          ); break;
    case TY_CSI_PS('n',   6) :      reportCursorPosition (          ); break;
    case TY_CSI_PS('q',   0) : /* IGNORED: LEDs off                 */ break; //VT100
    case TY_CSI_PS('q',   1) : /* IGNORED: LED1 on                  */ break; //VT100
    case TY_CSI_PS('q',   2) : /* IGNORED: LED2 on                  */ break; //VT100
    case TY_CSI_PS('q',   3) : /* IGNORED: LED3 on                  */ break; //VT100
    case TY_CSI_PS('q',   4) : /* IGNORED: LED4 on                  */ break; //VT100
    case TY_CSI_PS('x',   0) :      reportTerminalParms  (         2); break; //VT100
    case TY_CSI_PS('x',   1) :      reportTerminalParms  (         3); break; //VT100

    case TY_CSI_PN('@'      ) : _currentScreen->insertChars          (p         ); break;
    case TY_CSI_PN('A'      ) : _currentScreen->cursorUp             (p         ); break; //VT100
    case TY_CSI_PN('B'      ) : _currentScreen->cursorDown           (p         ); break; //VT100
    case TY_CSI_PN('C'      ) : _currentScreen->cursorRight          (p         ); break; //VT100
    case TY_CSI_PN('D'      ) : _currentScreen->cursorLeft           (p         ); break; //VT100
    case TY_CSI_PN('G'      ) : _currentScreen->setCursorX           (p         ); break; //LINUX
    case TY_CSI_PN('H'      ) : _currentScreen->setCursorYX          (p,      q); break; //VT100
    case TY_CSI_PN('I'      ) : _currentScreen->tab                  (p         ); break;
    case TY_CSI_PN('L'      ) : _currentScreen->insertLines          (p         ); break;
    case TY_CSI_PN('M'      ) : _currentScreen->deleteLines          (p         ); break;
    case TY_CSI_PN('P'      ) : _currentScreen->deleteChars          (p         ); break;
    case TY_CSI_PN('S'      ) : _currentScreen->scrollUp             (p         ); break;
    case TY_CSI_PN('T'      ) : _currentScreen->scrollDown           (p         ); break;
    case TY_CSI_PN('X'      ) : _currentScreen->eraseChars           (p         ); break;
    case TY_CSI_PN('Z'      ) : _currentScreen->backtab              (p         ); break;
    case TY_CSI_PN('c'      ) :      reportTerminalType   (          ); break; //VT100
    case TY_CSI_PN('d'      ) : _currentScreen->setCursorY           (p         ); break; //LINUX
    case TY_CSI_PN('f'      ) : _currentScreen->setCursorYX          (p,      q); break; //VT100
    case TY_CSI_PN('r'      ) :      setMargins           (p,      q); break; //VT100
    case TY_CSI_PN('y'      ) : /* IGNORED: Confidence test          */ break; //VT100

    case TY_CSI_PR('h',   1) :          setMode      (MODE_AppCuKeys); break; //VT100
    case TY_CSI_PR('l',   1) :        resetMode      (MODE_AppCuKeys); break; //VT100
    case TY_CSI_PR('s',   1) :         saveMode      (MODE_AppCuKeys); break; //FIXME
    case TY_CSI_PR('r',   1) :      restoreMode      (MODE_AppCuKeys); break; //FIXME

    case TY_CSI_PR('l',   2) :        resetMode      (MODE_Ansi     ); break; //VT100

    case TY_CSI_PR('h',   3) :          setMode      (MODE_132Columns);break; //VT100
    case TY_CSI_PR('l',   3) :        resetMode      (MODE_132Columns);break; //VT100

    case TY_CSI_PR('h',   4) : /* IGNORED: soft scrolling           */ break; //VT100
    case TY_CSI_PR('l',   4) : /* IGNORED: soft scrolling           */ break; //VT100

    case TY_CSI_PR('h',   5) : _currentScreen->    setMode      (MODE_Screen   ); break; //VT100
    case TY_CSI_PR('l',   5) : _currentScreen->  resetMode      (MODE_Screen   ); break; //VT100

    case TY_CSI_PR('h',   6) : _currentScreen->    setMode      (MODE_Origin   ); break; //VT100
    case TY_CSI_PR('l',   6) : _currentScreen->  resetMode      (MODE_Origin   ); break; //VT100
    case TY_CSI_PR('s',   6) : _currentScreen->   saveMode      (MODE_Origin   ); break; //FIXME
    case TY_CSI_PR('r',   6) : _currentScreen->restoreMode      (MODE_Origin   ); break; //FIXME

    case TY_CSI_PR('h',   7) : _currentScreen->    setMode      (MODE_Wrap     ); break; //VT100
    case TY_CSI_PR('l',   7) : _currentScreen->  resetMode      (MODE_Wrap     ); break; //VT100
    case TY_CSI_PR('s',   7) : _currentScreen->   saveMode      (MODE_Wrap     ); break; //FIXME
    case TY_CSI_PR('r',   7) : _currentScreen->restoreMode      (MODE_Wrap     ); break; //FIXME

    case TY_CSI_PR('h',   8) : /* IGNORED: autorepeat on            */ break; //VT100
    case TY_CSI_PR('l',   8) : /* IGNORED: autorepeat off           */ break; //VT100
    case TY_CSI_PR('s',   8) : /* IGNORED: autorepeat on            */ break; //VT100
    case TY_CSI_PR('r',   8) : /* IGNORED: autorepeat off           */ break; //VT100

    case TY_CSI_PR('h',   9) : /* IGNORED: interlace                */ break; //VT100
    case TY_CSI_PR('l',   9) : /* IGNORED: interlace                */ break; //VT100
    case TY_CSI_PR('s',   9) : /* IGNORED: interlace                */ break; //VT100
    case TY_CSI_PR('r',   9) : /* IGNORED: interlace                */ break; //VT100

    case TY_CSI_PR('h',  12) : /* IGNORED: Cursor blink             */ break; //att610
    case TY_CSI_PR('l',  12) : /* IGNORED: Cursor blink             */ break; //att610
    case TY_CSI_PR('s',  12) : /* IGNORED: Cursor blink             */ break; //att610
    case TY_CSI_PR('r',  12) : /* IGNORED: Cursor blink             */ break; //att610

    case TY_CSI_PR('h',  25) :          setMode      (MODE_Cursor   ); break; //VT100
    case TY_CSI_PR('l',  25) :        resetMode      (MODE_Cursor   ); break; //VT100
    case TY_CSI_PR('s',  25) :         saveMode      (MODE_Cursor   ); break; //VT100
    case TY_CSI_PR('r',  25) :      restoreMode      (MODE_Cursor   ); break; //VT100

    case TY_CSI_PR('h',  40) :         setMode(MODE_Allow132Columns ); break; // XTERM
    case TY_CSI_PR('l',  40) :       resetMode(MODE_Allow132Columns ); break; // XTERM

    case TY_CSI_PR('h',  41) : /* IGNORED: obsolete more(1) fix     */ break; //XTERM
    case TY_CSI_PR('l',  41) : /* IGNORED: obsolete more(1) fix     */ break; //XTERM
    case TY_CSI_PR('s',  41) : /* IGNORED: obsolete more(1) fix     */ break; //XTERM
    case TY_CSI_PR('r',  41) : /* IGNORED: obsolete more(1) fix     */ break; //XTERM

    case TY_CSI_PR('h',  47) :          setMode      (MODE_AppScreen); break; //VT100
    case TY_CSI_PR('l',  47) :        resetMode      (MODE_AppScreen); break; //VT100
    case TY_CSI_PR('s',  47) :         saveMode      (MODE_AppScreen); break; //XTERM
    case TY_CSI_PR('r',  47) :      restoreMode      (MODE_AppScreen); break; //XTERM

    case TY_CSI_PR('h',  67) : /* IGNORED: DECBKM                   */ break; //XTERM
    case TY_CSI_PR('l',  67) : /* IGNORED: DECBKM                   */ break; //XTERM
    case TY_CSI_PR('s',  67) : /* IGNORED: DECBKM                   */ break; //XTERM
    case TY_CSI_PR('r',  67) : /* IGNORED: DECBKM                   */ break; //XTERM

    // XTerm defines the following modes:
    // SET_VT200_MOUSE             1000
    // SET_VT200_HIGHLIGHT_MOUSE   1001
    // SET_BTN_EVENT_MOUSE         1002
    // SET_ANY_EVENT_MOUSE         1003
    //

    //Note about mouse modes:
    //There are four mouse modes which xterm-compatible terminals can support - 1000,1001,1002,1003
    //Konsole currently supports mode 1000 (basic mouse press and release) and mode 1002 (dragging the mouse).
    //TODO:  Implementation of mouse modes 1001 (something called hilight tracking) and
    //1003 (a slight variation on dragging the mouse)
    //

    case TY_CSI_PR('h', 1000) :          setMode      (MODE_Mouse1000); break; //XTERM
    case TY_CSI_PR('l', 1000) :        resetMode      (MODE_Mouse1000); break; //XTERM
    case TY_CSI_PR('s', 1000) :         saveMode      (MODE_Mouse1000); break; //XTERM
    case TY_CSI_PR('r', 1000) :      restoreMode      (MODE_Mouse1000); break; //XTERM

    case TY_CSI_PR('h', 1001) : /* IGNORED: hilite mouse tracking    */ break; //XTERM
    case TY_CSI_PR('l', 1001) :        resetMode      (MODE_Mouse1001); break; //XTERM
    case TY_CSI_PR('s', 1001) : /* IGNORED: hilite mouse tracking    */ break; //XTERM
    case TY_CSI_PR('r', 1001) : /* IGNORED: hilite mouse tracking    */ break; //XTERM

    case TY_CSI_PR('h', 1002) :          setMode      (MODE_Mouse1002); break; //XTERM
    case TY_CSI_PR('l', 1002) :        resetMode      (MODE_Mouse1002); break; //XTERM
    case TY_CSI_PR('s', 1002) :         saveMode      (MODE_Mouse1002); break; //XTERM
    case TY_CSI_PR('r', 1002) :      restoreMode      (MODE_Mouse1002); break; //XTERM

    case TY_CSI_PR('h', 1003) :          setMode      (MODE_Mouse1003); break; //XTERM
    case TY_CSI_PR('l', 1003) :        resetMode      (MODE_Mouse1003); break; //XTERM
    case TY_CSI_PR('s', 1003) :         saveMode      (MODE_Mouse1003); break; //XTERM
    case TY_CSI_PR('r', 1003) :      restoreMode      (MODE_Mouse1003); break; //XTERM

    case TY_CSI_PR('h', 1034) : /* IGNORED: 8bitinput activation     */ break; //XTERM

    case TY_CSI_PR('h', 1047) :          setMode      (MODE_AppScreen); break; //XTERM
    case TY_CSI_PR('l', 1047) : _screen[1]->clearEntireScreen(); resetMode(MODE_AppScreen); break; //XTERM
    case TY_CSI_PR('s', 1047) :         saveMode      (MODE_AppScreen); break; //XTERM
    case TY_CSI_PR('r', 1047) :      restoreMode      (MODE_AppScreen); break; //XTERM

    //FIXME: Unitoken: save translations
    case TY_CSI_PR('h', 1048) :      saveCursor           (          ); break; //XTERM
    case TY_CSI_PR('l', 1048) :      restoreCursor        (          ); break; //XTERM
    case TY_CSI_PR('s', 1048) :      saveCursor           (          ); break; //XTERM
    case TY_CSI_PR('r', 1048) :      restoreCursor        (          ); break; //XTERM

    //FIXME: every once new sequences like this pop up in xterm.
    //       Here's a guess of what they could mean.
    case TY_CSI_PR('h', 1049) : saveCursor(); _screen[1]->clearEntireScreen(); setMode(MODE_AppScreen); break; //XTERM
    case TY_CSI_PR('l', 1049) : resetMode(MODE_AppScreen); restoreCursor(); break; //XTERM

    //FIXME: weird DEC reset sequence
    case TY_CSI_PE('p'      ) : /* IGNORED: reset         (        ) */ break;

    //FIXME: when changing between vt52 and ansi mode evtl do some resetting.
    case TY_VT52('A'      ) : _currentScreen->cursorUp             (         1); break; //VT52
    case TY_VT52('B'      ) : _currentScreen->cursorDown           (         1); break; //VT52
    case TY_VT52('C'      ) : _currentScreen->cursorRight          (         1); break; //VT52
    case TY_VT52('D'      ) : _currentScreen->cursorLeft           (         1); break; //VT52

    case TY_VT52('F'      ) :      setAndUseCharset     (0,    '0'); break; //VT52
    case TY_VT52('G'      ) :      setAndUseCharset     (0,    'B'); break; //VT52

    case TY_VT52('H'      ) : _currentScreen->setCursorYX          (1,1       ); break; //VT52
    case TY_VT52('I'      ) : _currentScreen->reverseIndex         (          ); break; //VT52
    case TY_VT52('J'      ) : _currentScreen->clearToEndOfScreen   (          ); break; //VT52
    case TY_VT52('K'      ) : _currentScreen->clearToEndOfLine     (          ); break; //VT52
    case TY_VT52('Y'      ) : _currentScreen->setCursorYX          (p-31,q-31 ); break; //VT52
    case TY_VT52('Z'      ) :      reportTerminalType   (           ); break; //VT52
    case TY_VT52('<'      ) :          setMode      (MODE_Ansi     ); break; //VT52
    case TY_VT52('='      ) :          setMode      (MODE_AppKeyPad); break; //VT52
    case TY_VT52('>'      ) :        resetMode      (MODE_AppKeyPad); break; //VT52

    case TY_CSI_PG('c'      ) :  reportSecondaryAttributes(          ); break; //VT100

    default:
        reportDecodingError();
        break;
  };
}

void Vt102Emulation::clearScreenAndSetColumns(int columnCount)
{
    setImageSize(_currentScreen->getLines(),columnCount);
    clearEntireScreen();
    setDefaultMargins();
    _currentScreen->setCursorYX(0,0);
}

void Vt102Emulation::sendString(const char* s , int length)
{
  if ( length >= 0 )
    emit sendData(s,length);
  else
    emit sendData(s,strlen(s));
}

void Vt102Emulation::reportCursorPosition()
{
  char tmp[20];
  sprintf(tmp,"\033[%d;%dR",_currentScreen->getCursorY()+1,_currentScreen->getCursorX()+1);
  sendString(tmp);
}

void Vt102Emulation::reportTerminalType()
{
  // Primary device attribute response (Request was: ^[[0c or ^[[c (from TT321 Users Guide))
  // VT220:  ^[[?63;1;2;3;6;7;8c   (list deps on emul. capabilities)
  // VT100:  ^[[?1;2c
  // VT101:  ^[[?1;0c
  // VT102:  ^[[?6v
  if (getMode(MODE_Ansi))
    sendString("\033[?1;2c"); // I'm a VT100
  else
    sendString("\033/Z"); // I'm a VT52
}

void Vt102Emulation::reportSecondaryAttributes()
{
  // Seconday device attribute response (Request was: ^[[>0c or ^[[>c)
  if (getMode(MODE_Ansi))
    sendString("\033[>0;115;0c"); // Why 115?  ;)
  else
    sendString("\033/Z");         // FIXME I don't think VT52 knows about it but kept for
                                  // konsoles backward compatibility.
}

void Vt102Emulation::reportTerminalParms(int p)
// DECREPTPARM
{
  char tmp[100];
  sprintf(tmp,"\033[%d;1;1;112;112;1;0x",p); // not really true.
  sendString(tmp);
}

void Vt102Emulation::reportStatus()
{
  sendString("\033[0n"); //VT100. Device status report. 0 = Ready.
}

void Vt102Emulation::reportAnswerBack()
{
  // FIXME - Test this with VTTEST
  // This is really obsolete VT100 stuff.
  const char* ANSWER_BACK = "";
  sendString(ANSWER_BACK);
}

/*!
    `cx',`cy' are 1-based.
    `eventType' indicates the button pressed (0-2)
                or a general mouse release (3).

    eventType represents the kind of mouse action that occurred:
        0 = Mouse button press or release
        1 = Mouse drag
*/

void Vt102Emulation::sendMouseEvent( int cb, int cx, int cy , int eventType )
{
  if (cx < 1 || cy < 1)
    return;

  // normal buttons are passed as 0x20 + button,
  // mouse wheel (buttons 4,5) as 0x5c + button
  if (cb >= 4)
    cb += 0x3c;

  //Mouse motion handling
  if ((getMode(MODE_Mouse1002) || getMode(MODE_Mouse1003)) && eventType == 1)
      cb += 0x20; //add 32 to signify motion event

  char command[20];
  sprintf(command,"\033[M%c%c%c",cb+0x20,cx+0x20,cy+0x20);
  sendString(command);
}

void Vt102Emulation::sendText( const QString& text )
{
  if (!text.isEmpty())
  {
    QKeyEvent event(QEvent::KeyPress,
                    0,
                    Qt::NoModifier,
                    text);
    sendKeyEvent(&event); // expose as a big fat keypress event
  }
}
void Vt102Emulation::sendKeyEvent( QKeyEvent* event )
{
    Qt::KeyboardModifiers modifiers = event->modifiers();
    KeyboardTranslator::States states = KeyboardTranslator::NoState;

    // get current states
    if (getMode(MODE_NewLine)  ) states |= KeyboardTranslator::NewLineState;
    if (getMode(MODE_Ansi)     ) states |= KeyboardTranslator::AnsiState;
    if (getMode(MODE_AppCuKeys)) states |= KeyboardTranslator::CursorKeysState;
    if (getMode(MODE_AppScreen)) states |= KeyboardTranslator::AlternateScreenState;
    if (getMode(MODE_AppKeyPad) && (modifiers & Qt::KeypadModifier))
        states |= KeyboardTranslator::ApplicationKeypadState;

    // check flow control state
    if (modifiers & Qt::ControlModifier)
    {
        if (event->key() == Qt::Key_S)
            emit flowControlKeyPressed(true);
        else if (event->key() == Qt::Key_Q)
            emit flowControlKeyPressed(false);
    }

    // lookup key binding
    if ( _keyTranslator )
    {
    KeyboardTranslator::Entry entry = _keyTranslator->findEntry(
                                                event->key() ,
                                                modifiers,
                                                states );

        // send result to terminal
        QByteArray textToSend;

        // special handling for the Alt (aka. Meta) modifier.  pressing
        // Alt+[Character] results in Esc+[Character] being sent
        // (unless there is an entry defined for this particular combination
        //  in the keyboard modifier)
        bool wantsAltModifier = entry.modifiers() & entry.modifierMask() & Qt::AltModifier;
        bool wantsAnyModifier = entry.state() &
                                entry.stateMask() & KeyboardTranslator::AnyModifierState;

        if ( modifiers & Qt::AltModifier && !(wantsAltModifier || wantsAnyModifier)
             && !event->text().isEmpty() )
        {
            textToSend.prepend("\033");
        }

        if ( entry.command() != KeyboardTranslator::NoCommand )
        {
            if (entry.command() & KeyboardTranslator::EraseCommand)
                textToSend += eraseChar();

            // TODO command handling
        }
        else if ( !entry.text().isEmpty() )
        {
            textToSend += _codec->fromUnicode(entry.text(true,modifiers));
        }
        else
            textToSend += _codec->fromUnicode(event->text());

        sendData( textToSend.constData() , textToSend.length() );
    }
    else
    {
        // print an error message to the terminal if no key translator has been
        // set
        QString translatorError =  tr("No keyboard translator available.  "
                                         "The information needed to convert key presses "
                                         "into characters to send to the terminal "
                                         "is missing.");
        reset();
        receiveData( translatorError.toLatin1().constData() , translatorError.count() );
    }
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                VT100 Charsets                             */
/*                                                                           */
/* ------------------------------------------------------------------------- */

// Character Set Conversion ------------------------------------------------ --

/*
   The processing contains a VT100 specific code translation layer.
   It's still in use and mainly responsible for the line drawing graphics.

   These and some other glyphs are assigned to codes (0x5f-0xfe)
   normally occupied by the latin letters. Since this codes also
   appear within control sequences, the extra code conversion
   does not permute with the tokenizer and is placed behind it
   in the pipeline. It only applies to tokens, which represent
   plain characters.

   This conversion it eventually continued in TerminalDisplay.C, since
   it might involve VT100 enhanced fonts, which have these
   particular glyphs allocated in (0x00-0x1f) in their code page.
*/

#define CHARSET _charset[_currentScreen==_screen[1]]

// Apply current character map.

unsigned short Vt102Emulation::applyCharset(unsigned short c)
{
  if (CHARSET.graphic && 0x5f <= c && c <= 0x7e) return vt100_graphics[c-0x5f];
  if (CHARSET.pound && c == '#' ) return 0xa3; //This mode is obsolete
  return c;
}

/*
   "Charset" related part of the emulation state.
   This configures the VT100 charset filter.

   While most operation work on the current _screen,
   the following two are different.
*/

void Vt102Emulation::resetCharset(int scrno)
{
  _charset[scrno].cu_cs = 0;
  strncpy(_charset[scrno].charset,"BBBB",4);
  _charset[scrno].sa_graphic = false;
  _charset[scrno].sa_pound = false;
  _charset[scrno].graphic = false;
  _charset[scrno].pound = false;
}

void Vt102Emulation::setCharset(int n, int cs) // on both screens.
{
  _charset[0].charset[n&3] = cs; useCharset(_charset[0].cu_cs);
  _charset[1].charset[n&3] = cs; useCharset(_charset[1].cu_cs);
}

void Vt102Emulation::setAndUseCharset(int n, int cs)
{
  CHARSET.charset[n&3] = cs;
  useCharset(n&3);
}

void Vt102Emulation::useCharset(int n)
{
  CHARSET.cu_cs   = n&3;
  CHARSET.graphic = (CHARSET.charset[n&3] == '0');
  CHARSET.pound   = (CHARSET.charset[n&3] == 'A'); //This mode is obsolete
}

void Vt102Emulation::setDefaultMargins()
{
    _screen[0]->setDefaultMargins();
    _screen[1]->setDefaultMargins();
}

void Vt102Emulation::setMargins(int t, int b)
{
  _screen[0]->setMargins(t, b);
  _screen[1]->setMargins(t, b);
}

void Vt102Emulation::saveCursor()
{
  CHARSET.sa_graphic = CHARSET.graphic;
  CHARSET.sa_pound   = CHARSET.pound; //This mode is obsolete
  // we are not clear about these
  //sa_charset = charsets[cScreen->_charset];
  //sa_charset_num = cScreen->_charset;
  _currentScreen->saveCursor();
}

void Vt102Emulation::restoreCursor()
{
  CHARSET.graphic = CHARSET.sa_graphic;
  CHARSET.pound   = CHARSET.sa_pound; //This mode is obsolete
  _currentScreen->restoreCursor();
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Mode Operations                            */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/*
   Some of the emulations state is either added to the state of the screens.

   This causes some scoping problems, since different emulations choose to
   located the mode either to the current _screen or to both.

   For strange reasons, the extend of the rendition attributes ranges over
   all screens and not over the actual _screen.

   We decided on the precise precise extend, somehow.
*/

// "Mode" related part of the state. These are all booleans.

void Vt102Emulation::resetModes()
{
  // MODE_Allow132Columns is not reset here
  // to match Xterm's behaviour (see Xterm's VTReset() function)

  resetMode(MODE_132Columns); saveMode(MODE_132Columns);
  resetMode(MODE_Mouse1000);  saveMode(MODE_Mouse1000);
  resetMode(MODE_Mouse1001);  saveMode(MODE_Mouse1001);
  resetMode(MODE_Mouse1002);  saveMode(MODE_Mouse1002);
  resetMode(MODE_Mouse1003);  saveMode(MODE_Mouse1003);

  resetMode(MODE_AppScreen);  saveMode(MODE_AppScreen);
  resetMode(MODE_AppCuKeys);  saveMode(MODE_AppCuKeys);
  resetMode(MODE_AppKeyPad);  saveMode(MODE_AppKeyPad);
  resetMode(MODE_NewLine);
  setMode(MODE_Ansi);
}

void Vt102Emulation::setMode(int m)
{
  _currentModes.mode[m] = true;
  switch (m)
  {
    case MODE_132Columns:
        if (getMode(MODE_Allow132Columns))
            clearScreenAndSetColumns(132);
        else
            _currentModes.mode[m] = false;
        break;
    case MODE_Mouse1000:
    case MODE_Mouse1001:
    case MODE_Mouse1002:
    case MODE_Mouse1003:
         emit programUsesMouseChanged(false);
    break;

    case MODE_AppScreen : _screen[1]->clearSelection();
                          setScreen(1);
    break;
  }
  if (m < MODES_SCREEN || m == MODE_NewLine)
  {
    _screen[0]->setMode(m);
    _screen[1]->setMode(m);
  }
}

void Vt102Emulation::resetMode(int m)
{
  _currentModes.mode[m] = false;
  switch (m)
  {
    case MODE_132Columns:
        if (getMode(MODE_Allow132Columns))
            clearScreenAndSetColumns(80);
        break;
    case MODE_Mouse1000 :
    case MODE_Mouse1001 :
    case MODE_Mouse1002 :
    case MODE_Mouse1003 :
        emit programUsesMouseChanged(true);
    break;

    case MODE_AppScreen :
        _screen[0]->clearSelection();
        setScreen(0);
    break;
  }
  if (m < MODES_SCREEN || m == MODE_NewLine)
  {
    _screen[0]->resetMode(m);
    _screen[1]->resetMode(m);
  }
}

void Vt102Emulation::saveMode(int m)
{
  _savedModes.mode[m] = _currentModes.mode[m];
}

void Vt102Emulation::restoreMode(int m)
{
  if (_savedModes.mode[m])
      setMode(m);
  else
      resetMode(m);
}

bool Vt102Emulation::getMode(int m)
{
  return _currentModes.mode[m];
}

char Vt102Emulation::eraseChar() const
{
  KeyboardTranslator::Entry entry = _keyTranslator->findEntry(
                                            Qt::Key_Backspace,
                                            0,
                                            0);
  if ( entry.text().count() > 0 )
      return entry.text()[0];
  else
      return '\b';
}

// print contents of the scan buffer
static void hexdump(int* s, int len)
{ int i;
  for (i = 0; i < len; i++)
  {
    if (s[i] == '\\')
      printf("\\\\");
    else
    if ((s[i]) > 32 && s[i] < 127)
      printf("%c",s[i]);
    else
      printf("\\%04x(hex)",s[i]);
  }
}

void Vt102Emulation::reportDecodingError()
{
  if (tokenBufferPos == 0 || ( tokenBufferPos == 1 && (tokenBuffer[0] & 0xff) >= 32) )
    return;
  printf("Undecodable sequence: ");
  hexdump(tokenBuffer,tokenBufferPos);
  printf("\n");
}

//#include "Vt102Emulation.moc"

