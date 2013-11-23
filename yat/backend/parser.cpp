/**************************************************************************************************
* Copyright (c) 2012 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
* OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************************************/

#include "parser.h"

#include "controll_chars.h"
#include "screen.h"

#include <QtCore/QDebug>


static bool yat_parser_debug = qEnvironmentVariableIsSet("YAT_PARSER_DEBUG");

Parser::Parser(Screen *screen)
    : m_decode_state(PlainText)
    , m_current_token_start(0)
    , m_currrent_position(0)
    , m_intermediate_char(QChar())
    , m_parameters(10)
    , m_screen(screen)
{
}

void Parser::addData(const QByteArray &data)
{
    m_current_token_start = 0;
    m_current_data = data;
    for (m_currrent_position = 0; m_currrent_position < data.size(); m_currrent_position++) {
        uchar character = data.at(m_currrent_position);
        switch (m_decode_state) {
        case PlainText:
            //UTF-8
            if (character > 127)
                continue;
            if (character < C0::C0_END ||
                    (character >= C1_8bit::C1_8bit_Start &&
                     character <= C1_8bit::C1_8bit_Stop)) {
                if (m_currrent_position != m_current_token_start) {
                    m_screen->replaceAtCursor(QString::fromUtf8(data.mid(m_current_token_start,
                                                                        m_currrent_position - m_current_token_start)));
                    tokenFinished();
                    m_current_token_start--;
                }
                m_decode_state = DecodeC0;
                decodeC0(data.at(m_currrent_position));
            }
            break;
        case DecodeC0:
            decodeC0(character);
            break;
        case DecodeC1_7bit:
            decodeC1_7bit(character);
            break;
        case DecodeCSI:
            decodeCSI(character);
            break;
        case DecodeOSC:
            decodeOSC(character);
            break;
        case DecodeOtherEscape:
            decodeOtherEscape(character);
            break;
       }

    }
    if (m_decode_state == PlainText) {
        QByteArray text = data.mid(m_current_token_start);
        if (text.size()) {
            m_screen->replaceAtCursor(QString::fromUtf8(text));
            tokenFinished();
        }
    }
    m_current_data = QByteArray();
}

void Parser::decodeC0(uchar character)
{
    if (yat_parser_debug)
        qDebug() << C0::C0(character);
    switch (character) {
    case C0::NUL:
    case C0::SOH:
    case C0::STX:
    case C0::ETX:
    case C0::EOT:
    case C0::ENQ:
    case C0::ACK:
        qDebug() << "Unhandled" << C0::C0(character);
        tokenFinished();
        break;
    case C0::BEL:
        m_screen->scheduleFlash();
        tokenFinished();
        break;
    case C0::BS:
        m_screen->backspace();
        tokenFinished();
        break;
    case C0::HT: {
        int x = m_screen->cursorPosition().x();
        int spaces = 8 - (x % 8);
        m_screen->replaceAtCursor(QString(spaces,' '));
    }
        tokenFinished();
        break;
    case C0::LF:
        m_screen->lineFeed();
        tokenFinished();
        break;
    case C0::VT:
    case C0::FF:
        qDebug() << "Unhandled" << C0::C0(character);
        tokenFinished();
        break;
    case C0::CR:
        m_screen->moveCursorHome();
        tokenFinished();
        //next should be a linefeed;
        break;
    case C0::SOorLS1:
    case C0::SIorLS0:
    case C0::DLE:
    case C0::DC1:
    case C0::DC2:
    case C0::DC3:
    case C0::DC4:
    case C0::NAK:
    case C0::SYN:
    case C0::ETB:
    case C0::CAN:
    case C0::EM:
    case C0::SUB:
        qDebug() << "Unhandled" << C0::C0(character);
        tokenFinished();
        break;
    case C0::ESC:
        m_decode_state = DecodeC1_7bit;
        break;
    case C0::IS4:
    case C0::IS3:
    case C0::IS2:
    case C0::IS1:
    default:
        qDebug() << "Unhandled" << C0::C0(character);
        tokenFinished();
        break;
    }
}

void Parser::decodeC1_7bit(uchar character)
{
    if (yat_parser_debug)
        qDebug() << C1_7bit::C1_7bit(character);
    switch(character) {
    case C1_7bit::CSI:
        m_decode_state = DecodeCSI;
        break;
    case C1_7bit::OSC:
        m_decode_state = DecodeOSC;
        break;
    case C1_7bit::RI:
        m_screen->reverseLineFeed();
        tokenFinished();
        break;
    case '%':
    case '#':
    case '(':
        m_parameters.append(-character);
        m_decode_state = DecodeOtherEscape;
        break;
    case '=':
        qDebug() << "Application keypad";
        tokenFinished();
        break;
    case '>':
        qDebug() << "Normal keypad mode";
        tokenFinished();
        break;
    default:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
    }
}

void Parser::decodeParameters(uchar character)
{
    switch (character) {
    case 0x30:
    case 0x31:
    case 0x32:
    case 0x33:
    case 0x34:
    case 0x35:
    case 0x36:
    case 0x37:
    case 0x38:
    case 0x39:
        m_parameter_string.append(character);
        break;
    case 0x3a:
        qDebug() << "Encountered special delimiter in parameterbyte";
        break;
    case 0x3b:
        appendParameter();
        break;
    case 0x3c:
    case 0x3d:
    case 0x3e:
    case 0x3f:
        appendParameter();
        m_parameters.append(-character);
        break;
    default:
        //this is undefined for now
        qDebug() << "Encountered undefined parameter byte";
        break;
    }
}

void Parser::decodeCSI(uchar character)
{
        if (character >= 0x30 && character <= 0x3f) {
            decodeParameters(character);
        } else {
            if (character >= 0x20 && character <= 0x2f) {
                if (m_intermediate_char.unicode())
                    qDebug() << "Warning!: double intermediate bytes found in CSI";
                m_intermediate_char = character;
            } else if (character >= 0x40 && character <= 0x7d) {
                if (m_intermediate_char.unicode()) {
                    if (yat_parser_debug)
                        qDebug() << FinalBytesSingleIntermediate::FinalBytesSingleIntermediate(character);
                    switch (character) {
                    case FinalBytesSingleIntermediate::SL:
                    case FinalBytesSingleIntermediate::SR:
                    case FinalBytesSingleIntermediate::GSM:
                    case FinalBytesSingleIntermediate::GSS:
                    case FinalBytesSingleIntermediate::FNT:
                    case FinalBytesSingleIntermediate::TSS:
                    case FinalBytesSingleIntermediate::JFY:
                    case FinalBytesSingleIntermediate::SPI:
                    case FinalBytesSingleIntermediate::QUAD:
                    case FinalBytesSingleIntermediate::SSU:
                    case FinalBytesSingleIntermediate::PFS:
                    case FinalBytesSingleIntermediate::SHS:
                    case FinalBytesSingleIntermediate::SVS:
                    case FinalBytesSingleIntermediate::IGS:
                    case FinalBytesSingleIntermediate::IDCS:
                    case FinalBytesSingleIntermediate::PPA:
                    case FinalBytesSingleIntermediate::PPR:
                    case FinalBytesSingleIntermediate::PPB:
                    case FinalBytesSingleIntermediate::SPD:
                    case FinalBytesSingleIntermediate::DTA:
                    case FinalBytesSingleIntermediate::SHL:
                    case FinalBytesSingleIntermediate::SLL:
                    case FinalBytesSingleIntermediate::FNK:
                    case FinalBytesSingleIntermediate::SPQR:
                    case FinalBytesSingleIntermediate::SEF:
                    case FinalBytesSingleIntermediate::PEC:
                    case FinalBytesSingleIntermediate::SSW:
                    case FinalBytesSingleIntermediate::SACS:
                    case FinalBytesSingleIntermediate::SAPV:
                    case FinalBytesSingleIntermediate::STAB:
                    case FinalBytesSingleIntermediate::GCC:
                    case FinalBytesSingleIntermediate::TATE:
                    case FinalBytesSingleIntermediate::TALE:
                    case FinalBytesSingleIntermediate::TAC:
                    case FinalBytesSingleIntermediate::TCC:
                    case FinalBytesSingleIntermediate::TSR:
                    case FinalBytesSingleIntermediate::SCO:
                    case FinalBytesSingleIntermediate::SRCS:
                    case FinalBytesSingleIntermediate::SCS:
                    case FinalBytesSingleIntermediate::SLS:
                    case FinalBytesSingleIntermediate::SCP:
                    default:
                        qDebug() << "unhandled CSI" << FinalBytesSingleIntermediate::FinalBytesSingleIntermediate(character);
                        tokenFinished();
                        break;
                    }
                } else {
                    if (yat_parser_debug)
                        qDebug() << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                    switch (character) {
                    case FinalBytesNoIntermediate::ICH: {
                        appendParameter();
                        int n_chars = m_parameters.size() ? m_parameters.at(0) : 1;
                        qDebug() << "ICH WITH n_chars" << n_chars;
                        m_screen->insertEmptyCharsAtCursor(n_chars);
                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::CUU: {
                        appendParameter();
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_up = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->moveCursorUp(move_up);
                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::CUD:
                        tokenFinished();
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::CUF:{
                        appendParameter();
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_right = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->moveCursorRight(move_right);
                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::CUB:
                    case FinalBytesNoIntermediate::CNL:
                    case FinalBytesNoIntermediate::CPL:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::CHA: {
                        appendParameter();
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_to_pos_on_line = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->moveCursorToCharacter(move_to_pos_on_line);
                    }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::CUP:
                        appendParameter();
                        if (!m_parameters.size()) {
                            m_screen->moveCursorTop();
                            m_screen->moveCursorHome();
                        } else if (m_parameters.size() == 2){
                                m_screen->moveCursor(m_parameters.at(1), m_parameters.at(0));
                        } else {
                            qDebug() << "OHOHOHOH";
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::CHT:
                        tokenFinished();
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::ED:
                        appendParameter();
                        if (!m_parameters.size()) {
                            m_screen->eraseFromCurrentLineToEndOfScreen();
                        } else {
                            switch (m_parameters.at(0)) {
                            case 1:
                                m_screen->eraseFromCurrentLineToBeginningOfScreen();
                                break;
                            case 2:
                                m_screen->eraseScreen();
                                break;
                            default:
                                qDebug() << "Invalid parameter value for FinalBytesNoIntermediate::ED";
                            }
                        }

                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::EL:
                        appendParameter();
                        if (!m_parameters.size() || m_parameters.at(0) == 0) {
                            m_screen->eraseFromCursorPositionToEndOfLine();
                        } else if (m_parameters.at(0) == 1) {
                            m_screen->eraseToCursorPosition();
                        } else if (m_parameters.at(0) == 2) {
                            m_screen->eraseLine();
                        } else{
                            qDebug() << "Fault when processing FinalBytesNoIntermediate::EL";
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::IL: {
                        appendParameter();
                        int count = 1;
                        if (m_parameters.size()) {
                            count = m_parameters.at(0);
                        }
                        m_screen->insertLines(count);
                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::DL: {
                        appendParameter();
                        int count = 1;
                        if (m_parameters.size()) {
                            count = m_parameters.at(0);
                        }
                        m_screen->deleteLines(count);
                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::EF:
                    case FinalBytesNoIntermediate::EA:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::DCH:{
                        appendParameter();
                        Q_ASSERT(m_parameters.size() < 2);
                        int n_chars = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->deleteCharacters(n_chars);
                    }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::SSE:
                    case FinalBytesNoIntermediate::CPR:
                    case FinalBytesNoIntermediate::SU:
                    case FinalBytesNoIntermediate::SD:
                    case FinalBytesNoIntermediate::NP:
                    case FinalBytesNoIntermediate::PP:
                    case FinalBytesNoIntermediate::CTC:
                    case FinalBytesNoIntermediate::ECH:
                    case FinalBytesNoIntermediate::CVT:
                    case FinalBytesNoIntermediate::CBT:
                    case FinalBytesNoIntermediate::SRS:
                    case FinalBytesNoIntermediate::PTX:
                    case FinalBytesNoIntermediate::SDS:
                    case FinalBytesNoIntermediate::SIMD:
                    case FinalBytesNoIntermediate::HPA:
                    case FinalBytesNoIntermediate::HPR:
                    case FinalBytesNoIntermediate::REP:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::DA:
                        appendParameter();
                        if (m_parameters.size()) {
                            switch (m_parameters.at(0)) {
                            case -'>':
                                m_screen->sendSecondaryDA();
                                break;
                            case -'?':
                                qDebug() << "WHAT!!!";
                                break; //ignore
                            case 0:
                            default:
                                m_screen->sendPrimaryDA();
                            }
                        } else {
                            m_screen->sendPrimaryDA();
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::VPA: {
                        appendParameter();
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_to_line = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->moveCursorToLine(move_to_line);
                    }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::VPR:
                    case FinalBytesNoIntermediate::HVP:
                    case FinalBytesNoIntermediate::TBC:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::SM:
                        appendParameter();
                        if (m_parameters.size() && m_parameters.at(0) == -'?') {
                            if (m_parameters.size() > 1) {
                                switch (m_parameters.at(1)) {
                                case 1:
                                    m_screen->setApplicationCursorKeysMode(true);
                                    break;
                                case 4:
                                    qDebug() << "Insertion mode";
                                    break;
                                case 7:
                                    qDebug() << "MODE 7";
                                    break;
                                case 12:
                                    m_screen->setCursorBlinking(true);
                                    break;
                                case 25:
                                    m_screen->setCursorVisible(true);
                                    break;
                                case 1034:
                                    //I don't know what this sequence is
                                    break;
                                case 1049:
                                    m_screen->saveCursor();
                                    m_screen->saveScreenData();
                                    break;
                                default:
                                    qDebug() << "unhandled CSI FinalBytesNoIntermediate::SM ? with parameter:" << m_parameters.at(1);
                                }
                            } else {
                                qDebug() << "unhandled CSI FinalBytesNoIntermediate::SM ?";
                            }
                        } else {
                            qDebug() << "unhandled CSI FinalBytesNoIntermediate::SM";
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::MC:
                    case FinalBytesNoIntermediate::HPB:
                    case FinalBytesNoIntermediate::VPB:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::RM:
                        appendParameter();
                        if (m_parameters.size()) {
                            switch(m_parameters.at(0)) {
                            case -'?':
                                if (m_parameters.size() > 1) {
                                    switch(m_parameters.at(1)) {
                                    case 1:
                                        qDebug() << "Normal cursor keys";
                                        break;
                                    case 12:
                                        m_screen->setCursorBlinking(false);
                                        break;
                                    case 25:
                                        m_screen->setCursorVisible(false);
                                        break;
                                    case 1049:
                                        m_screen->restoreCursor();
                                        m_screen->restoreScreenData();
                                        break;
                                    default:
                                        qDebug() << "unhandled CSI FinalBytesNoIntermediate::RM? with "
                                                    "parameter " << m_parameters.at(1);
                                    }
                                } else {
                                    qDebug() << "unhandled CSI FinalBytesNoIntermediate::RM";
                                }
                                break;
                            case 4:
                                m_screen->setInsertMode(Screen::Replace);
                            default:
                                qDebug() << "unhandled CSI FinalBytesNoIntermediate::RM";
                                break;
                            }
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::SGR: {
                        appendParameter();

                        if (!m_parameters.size())
                            m_parameters << 0;

                        for (int i = 0; i < m_parameters.size();i++) {
                            switch(m_parameters.at(i)) {
                            case 0:
                                //                                    m_screen->setTextStyle(TextStyle::Normal);
                                m_screen->resetStyle();
                                break;
                            case 1:
                                m_screen->setTextStyle(TextStyle::Bold);
                                break;
                            case 5:
                                m_screen->setTextStyle(TextStyle::Blinking);
                                break;
                            case 7:
                                m_screen->setTextStyle(TextStyle::Inverse);
                                break;
                            case 8:
                                qDebug() << "SGR: Hidden text not supported";
                                break;
                            case 22:
                                m_screen->setTextStyle(TextStyle::Normal);
                                break;
                            case 24:
                                m_screen->setTextStyle(TextStyle::Underlined, false);
                                break;
                            case 25:
                                m_screen->setTextStyle(TextStyle::Blinking, false);
                                break;
                            case 27:
                                m_screen->setTextStyle(TextStyle::Inverse, false);
                                break;
                            case 28:
                                qDebug() << "SGR: Visible text is allways on";
                                break;
                            case 30:
                            case 31:
                            case 32:
                            case 33:
                            case 34:
                            case 35:
                            case 36:
                            case 37:
                                //                                case 38:
                            case 39:
                            case 40:
                            case 41:
                            case 42:
                            case 43:
                            case 44:
                            case 45:
                            case 46:
                            case 47:
                                //                                case 38:
                            case 49:
                                m_screen->setTextStyleColor(m_parameters.at(i));
                                break;




                            default:
                                qDebug() << "Unknown SGR" << m_parameters.at(i);
                            }
                        }

                        tokenFinished();
                    }
                        break;
                    case FinalBytesNoIntermediate::DSR:
                        qDebug() << "report";
                    case FinalBytesNoIntermediate::DAQ:
                    case FinalBytesNoIntermediate::Reserved0:
                    case FinalBytesNoIntermediate::Reserved1:
                        qDebug() << "Unhandeled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::Reserved2:
                        appendParameter();
                        if (m_parameters.size() == 2) {
                            if (m_parameters.at(0) >= 0) {
                                m_screen->setScrollArea(m_parameters.at(0),m_parameters.at(1));
                            } else {
                                qDebug() << "Unknown value for scrollRegion";
                            }
                        } else {
                            qDebug() << "Unknown parameterset for scrollRegion";
                        }
                        tokenFinished();
                        break;
                    case FinalBytesNoIntermediate::Reserved3:
                    case FinalBytesNoIntermediate::Reserved4:
                    case FinalBytesNoIntermediate::Reserved5:
                    case FinalBytesNoIntermediate::Reserved6:
                    case FinalBytesNoIntermediate::Reserved7:
                    case FinalBytesNoIntermediate::Reserved8:
                    case FinalBytesNoIntermediate::Reserved9:
                    case FinalBytesNoIntermediate::Reserveda:
                    case FinalBytesNoIntermediate::Reservedb:
                    case FinalBytesNoIntermediate::Reservedc:
                    case FinalBytesNoIntermediate::Reservedd:
                    case FinalBytesNoIntermediate::Reservede:
                    case FinalBytesNoIntermediate::Reservedf:
                    default:
                        qDebug() << "Unhandeled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        tokenFinished();
                        break;
                    }
                }
            }
        }
}

void Parser::decodeOSC(uchar character)
{
    if (!m_parameters.size() &&
            character >= 0x30 && character <= 0x3f) {
        decodeParameters(character);
    } else {
        if (m_decode_osc_state ==  None) {
            appendParameter();
            if (m_parameters.size() != 1) {
                tokenFinished();
                return;
            }

            switch (m_parameters.at(0)) {
                case 0:
                    m_decode_osc_state = ChangeWindowAndIconName;
                    break;
                case 1:
                    m_decode_osc_state = ChangeIconTitle;
                    break;
                case 2:
                    m_decode_osc_state = ChangeWindowTitle;
                    break;
                default:
                    m_decode_osc_state = Unknown;
                    break;
            }
        } else {
            if (character == 0x07) {
                if (m_decode_osc_state == ChangeWindowAndIconName ||
                        m_decode_osc_state == ChangeWindowTitle) {
                    QString title = QString::fromUtf8(m_current_data.mid(m_current_token_start+4,
                                m_currrent_position - m_current_token_start -1));
                    m_screen->setTitle(title);
                }
                tokenFinished();
            }
        }
    }
}

void Parser::decodeOtherEscape(uchar character)
{
    Q_ASSERT(m_parameters.size());
    switch(m_parameters.at(0)) {
    case -'(':
        switch(character) {
        case 0:
            m_screen->setCharacterMap("DEC Special Character and Line Drawing Set");
            break;
        case 'A':
            m_screen->setCharacterMap("UK");
            break;
        case 'B':
            m_screen->setCharacterMap("USASCII");
            break;
        case '4':
            m_screen->setCharacterMap("Dutch");
            break;
        case 'C':
        case '5':
            m_screen->setCharacterMap("Finnish");
            break;
        case 'R':
            m_screen->setCharacterMap("French");
            break;
        case 'Q':
            m_screen->setCharacterMap("FrenchCanadian");
            break;
        case 'K':
            m_screen->setCharacterMap("German");
            break;
        case 'Y':
            m_screen->setCharacterMap("Italian");
            break;
        case 'E':
        case '6':
            m_screen->setCharacterMap("NorDan");
            break;
        case 'Z':
            m_screen->setCharacterMap("Spanish");
            break;
        case 'H':
        case '7':
            m_screen->setCharacterMap("Sweedish");
            break;
        case '=':
            m_screen->setCharacterMap("Swiss");
            break;
        default:
            qDebug() << "Not supported Character set!";
        }
        break;
    default:
        qDebug() << "Other Escape sequence not recognized";
    }
    tokenFinished();
}

void Parser::tokenFinished()
{
    m_decode_state = PlainText;
    m_decode_osc_state = None;

    m_parameters.clear();
    m_parameter_string.clear();

    m_current_token_start = m_currrent_position + 1;
    m_intermediate_char = 0;
}

void Parser::appendParameter()
{
    if (m_parameter_string.size()) {
        m_parameters.append(m_parameter_string.toUShort());
        m_parameter_string.clear();
    }
}

