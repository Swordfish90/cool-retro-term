/*******************************************************************************
* Copyright (c) 2012 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*******************************************************************************/

#include "parser.h"

#include "controll_chars.h"
#include "screen.h"
#include "cursor.h"
#include "nrc_text_codec.h"

#include <QtCore/QTextCodec>
#include <QtCore/QDebug>


static bool yat_parser_debug = qEnvironmentVariableIsSet("YAT_PARSER_DEBUG");

namespace CharacterSet {
enum CharacterSet {
    utf_8,
    ascii,
    latin_1,
    dec_special_graphics,
    nrc_british,
    nrc_norwegian_danish,
    nrc_dutch,
    nrc_finnish,
    nrc_french,
    nrc_french_canadian,
    nrc_german,
    nrc_italian,
    nrc_spanish,
    nrc_swedish,
    nrc_swiss
};
}

QTextCodec *codecForCharacterset(CharacterSet::CharacterSet characterSet) {
    QTextCodec *codec = 0;
    switch(characterSet) {
        case CharacterSet::utf_8:
            codec = QTextCodec::codecForName("utf-8");
            break;
        case CharacterSet::ascii:
            codec = QTextCodec::codecForName("utf-8");
            break;
        case CharacterSet::latin_1:
            codec = QTextCodec::codecForName("latin-1");
            break;
        case CharacterSet::dec_special_graphics:
            codec = QTextCodec::codecForName("dec_special_graphics");
            break;
        case CharacterSet::nrc_british:
            codec = QTextCodec::codecForName("nrc_british");
            break;
        case CharacterSet::nrc_norwegian_danish:
            codec = QTextCodec::codecForName("nrc_norwegian_danish");
            break;
        case CharacterSet::nrc_dutch:
            codec = QTextCodec::codecForName("nrc_dutch");
            break;
        case CharacterSet::nrc_finnish:
            codec = QTextCodec::codecForName("nrc_finnish");
            break;
        case CharacterSet::nrc_french:
            codec = QTextCodec::codecForName("nrc_french");
            break;
        case CharacterSet::nrc_french_canadian:
            codec = QTextCodec::codecForName("nrc_french_canadian");
            break;
        case CharacterSet::nrc_german:
            codec = QTextCodec::codecForName("nrc_german");
            break;
        case CharacterSet::nrc_italian:
            codec = QTextCodec::codecForName("nrc_italian");
            break;
        case CharacterSet::nrc_spanish:
            codec = QTextCodec::codecForName("nrc_spanish");
            break;
        case CharacterSet::nrc_swedish:
            codec = QTextCodec::codecForName("nrc_swedish");
            break;
        case CharacterSet::nrc_swiss:
            codec = QTextCodec::codecForName("nrc_swiss");
            break;
    }
    if (!codec) {
        qDebug() << "Failed to find codec for" << characterSet << ". Returning utf-8";
        return QTextCodec::codecForName("utf-8");
    }
    return codec;
}


static const QByteArray getByteArrayMidNoCopy(const QByteArray &array, int start, int length)
{
    length = std::min(length, array.size() - start);

    if (start >= array.size() || length < 1)
        return QByteArray();

    const char *data_at_start = array.data() + start;
    return QByteArray::fromRawData(data_at_start, length);
}
static void printParameters(const QVector<int> &parameters, QDebug &debug, bool dec_private = false)
{
    if (dec_private)
        debug << "?";
    for (int i = 0; i < parameters.size(); i++) {
        if (i == 0)
            debug << " ";
        else
            debug << ";";
        debug << parameters.at(i);
    }
}

Parser::Parser(Screen *screen)
    : m_decode_state(PlainText)
    , m_current_token_start(0)
    , m_current_position(0)
    , m_intermediate_char(QChar())
    , m_parameters(10)
    , m_parameters_expecting_more(false)
    , m_dec_mode(false)
    , m_gt_param(false)
    , m_lnm_mode_set(false)
    , m_contains_only_latin(true)
    , m_screen(screen)
{
    for (uint i = 0; i < sizeof(m_graphic_codecs) / sizeof *m_graphic_codecs; i++) {
        m_graphic_codecs[i] = QTextCodec::codecForName("utf-8");
    }

    NrcTextCodec::initialize();
}

void Parser::addData(const QByteArray &data)
{
    m_current_token_start = 0;
    m_current_data = data;

    for (m_current_position = 0; m_current_position < m_current_data.size(); m_current_position++) {
        uchar character = m_current_data.at(m_current_position);
        if (character > 127)
            m_utf8_decoder.addChar(character);
        switch (m_decode_state) {
        case PlainText:
            if (character < C0::C0_END || m_utf8_decoder.isC1()) {
                if (m_current_position != m_current_token_start) {
                    const QByteArray to_insert = getByteArrayMidNoCopy(m_current_data, m_current_token_start, m_current_position - m_current_token_start);
                    if (yat_parser_debug)
                        qDebug() << "Parser Insert text:" << to_insert;
                    m_screen->currentCursor()->addAtCursor(to_insert, m_contains_only_latin);
                    tokenFinished();
                    m_current_token_start--;
                }
                m_decode_state = DecodeC0;
                decodeC0(m_current_data.at(m_current_position));
            }
            m_contains_only_latin = m_contains_only_latin && m_utf8_decoder.isLatin();
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
        case DecodeCharacterSet:
            decodeCharacterSet(character);
            break;
        case DecodeFontSize:
            decodeFontSize(character);
            break;
       }

    }
    if (m_decode_state == PlainText) {
        QByteArray to_insert = getByteArrayMidNoCopy(m_current_data, m_current_token_start, m_current_data.size() - m_current_token_start);
        if (to_insert.size()) {
            if (yat_parser_debug)
                qDebug() << "Parser Insert text:" << to_insert;
            m_screen->currentCursor()->addAtCursor(to_insert, m_contains_only_latin);
            tokenFinished();
        }
    }
    m_current_data = QByteArray();
}

void Parser::decodeC0(uchar character)
{
    if (yat_parser_debug) {
        qDebug() << C0::C0(character);
    }
    switch (character) {
    case C0::NUL:
    case C0::SOH:
    case C0::STX:
    case C0::ETX:
    case C0::EOT:
    case C0::ENQ:
    case C0::ACK:
        qDebug() << "Unhandled" << C0::C0(character);
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::BEL:
        m_screen->scheduleFlash();
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::BS:
        m_screen->currentCursor()->moveLeft();
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::HT:
        m_screen->currentCursor()->moveToNextTab();
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::LF:
    case C0::VT:
    case C0::FF:
        if (m_lnm_mode_set)
            m_screen->currentCursor()->moveBeginningOfLine();
        m_screen->currentCursor()->lineFeed();
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::CR:
        m_screen->currentCursor()->moveBeginningOfLine();
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::SOorLS1:
        m_screen->currentCursor()->setTextCodec(m_graphic_codecs[1]);
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::SIorLS0:
        m_screen->currentCursor()->setTextCodec(m_graphic_codecs[0]);
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
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
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    case C0::ESC:
        if (m_decode_state != DecodeC0) {
            tokenFinished();
            break;
        }
        m_decode_state = DecodeC1_7bit;
        break;
        if (m_decode_state != DecodeC0)
            tokenFinished();
        break;
    case C0::IS4:
    case C0::IS3:
    case C0::IS2:
    case C0::IS1:
    default:
        qDebug() << "Unhandled" << C0::C0(character);
        if (m_decode_state == DecodeC0)
            tokenFinished();
        break;
    }
}

void Parser::decodeC1_7bit(uchar character)
{
    if (yat_parser_debug) {
        qDebug() << C1_7bit::C1_7bit(character);
    }
    switch(character) {
    case C1_7bit::ESC:
        tokenFinished();
        break;
    case '#':
        m_decode_state = DecodeFontSize;
        break;
    case C1_7bit::SCS_G0:
        m_decode_state = DecodeCharacterSet;
        m_decode_graphics_set = 0;
        break;
    case C1_7bit::SCS_G1:
        m_decode_state = DecodeCharacterSet;
        m_decode_graphics_set = 1;
        break;
    case C1_7bit::SCS_G2:
        m_decode_state = DecodeCharacterSet;
        m_decode_graphics_set = 2;
        break;
    case C1_7bit::SCS_G3:
        m_decode_state = DecodeCharacterSet;
        m_decode_graphics_set = 3;
        break;
    case C1_7bit::DECSC:
        m_screen->saveCursor();
        tokenFinished();
        break;
    case C1_7bit::DECRC:
        m_screen->restoreCursor();
        tokenFinished();
        break;
    case '=':
        qDebug() << "Application keypad";
        tokenFinished();
        break;
    case '>':
        qDebug() << "Normal keypad mode";
        tokenFinished();
        break;
    case C1_7bit::NOT_DEFINED:
    case C1_7bit::NOT_DEFINED1:
    case C1_7bit::BPH:
    case C1_7bit::NBH:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
    case C1_7bit::IND:
        m_screen->currentCursor()->moveDown();
        tokenFinished();
        break;
    case C1_7bit::NEL:
        m_screen->currentCursor()->moveBeginningOfLine();
        m_screen->currentCursor()->lineFeed();
        tokenFinished();
        break;
    case C1_7bit::SSA:
    case C1_7bit::ESA:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
    case C1_7bit::HTS:
        m_screen->currentCursor()->setTabStop();
        tokenFinished();
        break;
    case C1_7bit::HTJ:
    case C1_7bit::VTS:
    case C1_7bit::PLD:
    case C1_7bit::PLU:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
    case C1_7bit::RI:
        m_screen->currentCursor()->reverseLineFeed();
        tokenFinished();
        break;
    case C1_7bit::SS2:
    case C1_7bit::SS3:
    case C1_7bit::DCS:
    case C1_7bit::PU1:
    case C1_7bit::PU2:
    case C1_7bit::STS:
    case C1_7bit::CCH:
    case C1_7bit::MW :
    case C1_7bit::SPA:
    case C1_7bit::EPA:
    case C1_7bit::SOS:
    case C1_7bit::NOT_DEFINED3:
    case C1_7bit::SCI:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
    case C1_7bit::CSI:
        m_decode_state = DecodeCSI;
        break;
    case C1_7bit::ST :
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
    case C1_7bit::OSC:
        m_decode_state = DecodeOSC;
        break;
    case C1_7bit::PM :
    case C1_7bit::APC:
    default:
        qDebug() << "Unhandled" << C1_7bit::C1_7bit(character);
        tokenFinished();
        break;
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
        if (!m_parameter_string.size()) {
            m_parameters.append(INT_MIN);
        } else {
            appendParameter();
        }
        m_parameters_expecting_more = true;
        break;
    case 0x3c:
    case 0x3d:
        appendParameter();
        qDebug() << "Parameter decoding INVALID RANGE" << char(character);
        m_parameters.append(-character);
        break;
    case 0x3e:
        if (m_parameters.size() == 0 && m_parameter_string.size() == 0) {
            m_gt_param = true;
        } else {
            appendParameter();
            qDebug() << "unknown parameter state";
        }
        break;
    case 0x3f:
        if (m_parameters.size() == 0 && m_parameter_string.size() == 0) {
            m_dec_mode = true;
        } else {
            appendParameter();
            qDebug() << "unknown parameter state";
        }
        break;
    default:
        //this is undefined for now
        qDebug() << "Encountered undefined parameter byte";
        break;
    }
}

void Parser::decodeCSI(uchar character)
{
        if (character < C0::C0_END) {
            decodeC0(character);
            return;
        }

        if (character >= 0x30 && character <= 0x3f) {
            decodeParameters(character);
        } else {
            appendParameter();
            if (character >= 0x20 && character <= 0x2f) {
                if (m_intermediate_char.unicode())
                    qDebug() << "Warning!: double intermediate bytes found in CSI";
                m_intermediate_char = character;
            } else if (character >= 0x40 && character <= 0x7d) {
                if (m_intermediate_char.unicode()) {
                    if (yat_parser_debug) {
                        QDebug debug = qDebug();
                        debug << FinalBytesSingleIntermediate::FinalBytesSingleIntermediate(character);
                        printParameters(m_parameters, debug, m_dec_mode);
                    }
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
                        break;
                    }
                    tokenFinished();
                } else {
                    if (yat_parser_debug) {
                        QDebug debug = qDebug();
                        debug << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        printParameters(m_parameters, debug, m_dec_mode);
                    }
                    switch (character) {
                    case FinalBytesNoIntermediate::ICH: {
                        int n_chars = m_parameters.size() ? m_parameters.at(0) : 1;
                        QByteArray empty(n_chars, ' ');
                        m_screen->currentCursor()->insertAtCursor(empty);
                    }
                        break;
                    case FinalBytesNoIntermediate::CUU: {
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_up = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->moveUp(move_up ? move_up : 1);
                    }
                        break;
                    case FinalBytesNoIntermediate::CUD: {
                        int move_down = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->moveDown(move_down ? move_down : 1);
                    }
                        break;
                    case FinalBytesNoIntermediate::CUF:{
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_right = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->moveRight(move_right ? move_right : 1);
                    }
                        break;
                    case FinalBytesNoIntermediate::CUB: {
                        Q_ASSERT(m_parameters.size() < 2);
                        int move_left = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->moveLeft(move_left ? move_left : 1);
                    }
                        break;
                    case FinalBytesNoIntermediate::CNL:
                    case FinalBytesNoIntermediate::CPL:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::CHA: {
                        Q_ASSERT(m_parameters.size() < 2);
                        handleDefaultParameters(1);
                        int move_to_pos_on_line = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->moveToCharacter(move_to_pos_on_line - 1);
                    }
                        break;
                    case FinalBytesNoIntermediate::CUP:
                        handleDefaultParameters(1);
                        if (!m_parameters.size()) {
                            m_screen->currentCursor()->moveOrigin();
                        } else if (m_parameters.size() == 2){
                                m_screen->currentCursor()->move(m_parameters.at(1) - 1, m_parameters.at(0) - 1);
                        } else if (m_parameters.size() == 1){
                                m_screen->currentCursor()->move(m_parameters.at(0) - 1, 0);
                        }
                        break;
                    case FinalBytesNoIntermediate::CHT:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::ED:
                        if (!m_parameters.size()) {
                            m_screen->currentCursor()->clearToEndOfScreen();
                        } else {
                            int param = m_parameters.size() ? m_parameters.at(0) : 0;
                            switch (param) {
                            case 0:
                                m_screen->currentCursor()->clearToEndOfScreen();
                                break;
                            case 1:
                                m_screen->currentCursor()->clearToBeginningOfScreen();
                                break;
                            case 2:
                                m_screen->clearScreen();
                                break;
                            default:
                                qDebug() << "Invalid parameter value for FinalBytesNoIntermediate::ED";
                            }
                        }

                        break;
                    case FinalBytesNoIntermediate::EL:
                        if (!m_parameters.size() || m_parameters.at(0) == 0) {
                            m_screen->currentCursor()->clearToEndOfLine();
                        } else if (m_parameters.at(0) == 1) {
                            m_screen->currentCursor()->clearToBeginningOfLine();
                        } else if (m_parameters.at(0) == 2) {
                            m_screen->currentCursor()->clearLine();
                        } else{
                            qDebug() << "Fault when processing FinalBytesNoIntermediate::EL";
                        }
                        break;
                    case FinalBytesNoIntermediate::IL: {
                        int count = 1;
                        if (m_parameters.size()) {
                            count = m_parameters.at(0);
                        }
                        m_screen->currentCursor()->scrollUp(count);
                    }
                        break;
                    case FinalBytesNoIntermediate::DL: {
                        int count = 1;
                        if (m_parameters.size()) {
                            count = m_parameters.at(0);
                        }
                        m_screen->currentCursor()->scrollDown(count);
                    }
                        break;
                    case FinalBytesNoIntermediate::EF:
                    case FinalBytesNoIntermediate::EA:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::DCH:{
                        Q_ASSERT(m_parameters.size() < 2);
                        int n_chars = m_parameters.size() ? m_parameters.at(0) : 1;
                        m_screen->currentCursor()->deleteCharacters(n_chars);
                    }
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
                        break;
                    case FinalBytesNoIntermediate::DA:
                        if (m_gt_param) {
                            m_screen->sendSecondaryDA();
                        } else {
                            m_screen->sendPrimaryDA();
                        }
                        break;
                    case FinalBytesNoIntermediate::VPA: {
                        Q_ASSERT(m_parameters.size() < 2);
                        handleDefaultParameters(1);
                        int move_to_line = m_parameters.size() ? m_parameters.at(0) -1 : 0;
                        m_screen->currentCursor()->moveToLine(move_to_line);
                    }
                        break;
                    case FinalBytesNoIntermediate::VPR:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::HVP: {
                        Q_ASSERT(m_parameters.size() <= 2);
                        handleDefaultParameters(1);
                        if (!m_parameters.size()) {
                            m_screen->currentCursor()->moveOrigin();
                        } else if (m_parameters.size() == 2){
                                m_screen->currentCursor()->move(m_parameters.at(1) - 1, m_parameters.at(0) - 1);
                        } else if (m_parameters.size() == 1){
                                m_screen->currentCursor()->move(m_parameters.at(0) - 1, 0);
                        }
                        break;
                    }
                    case FinalBytesNoIntermediate::TBC:
                        if (!m_parameters.size() || m_parameters.at(0) == 0) {
                            m_screen->currentCursor()->removeTabStop();
                        } else if (m_parameters.at(0) == 3) {
                            m_screen->currentCursor()->clearTabStops();
                        }
                        break;
                    case FinalBytesNoIntermediate::SM:
                        if (!m_parameters.size()) {
                            qDebug() << FinalBytesNoIntermediate::SM << "called without parameter";
                            break;
                        }
                        for (int i = 0; i < m_parameters.size(); i++) {
                            if (m_dec_mode) {
                                setDecMode(m_parameters.at(i));
                            } else {
                                setMode(m_parameters.at(i));
                            }
                        }
                        break;
                    case FinalBytesNoIntermediate::MC:
                    case FinalBytesNoIntermediate::HPB:
                    case FinalBytesNoIntermediate::VPB:
                        qDebug() << "unhandled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::RM:
                        if (!m_parameters.size()) {
                            qDebug() << FinalBytesNoIntermediate::RM << "called without parameter";
                            break;
                        }
                        for (int i = 0; i < m_parameters.size(); i++) {
                            if (m_dec_mode) {
                                resetDecMode(m_parameters.at(i));
                            } else {
                                resetMode(m_parameters.at(i));
                            }
                        }

                        break;
                    case FinalBytesNoIntermediate::SGR:
                        handleDefaultParameters(0);
                        if (!m_parameters.size())
                            m_parameters << 0;
                        handleSGR();
                        break;
                    case FinalBytesNoIntermediate::DSR:
                        qDebug() << "report";
                    case FinalBytesNoIntermediate::DAQ:
                    case FinalBytesNoIntermediate::Reserved0:
                    case FinalBytesNoIntermediate::Reserved1:
                        qDebug() << "Unhandeled CSI" << FinalBytesNoIntermediate::FinalBytesNoIntermediate(character);
                        break;
                    case FinalBytesNoIntermediate::DECSTBM:
                        if (m_parameters.size() == 2) {
                            if (m_parameters.at(0) >= 0) {
                                m_screen->currentCursor()->setScrollArea(m_parameters.at(0) - 1,m_parameters.at(1) - 1);
                            } else {
                                qDebug() << "Unknown value for scrollRegion" << m_parameters.at(0);
                            }
                        } else {
                            m_screen->currentCursor()->resetScrollArea();
                        }
                        m_screen->currentCursor()->moveOrigin();
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
                        break;
                    }
                    tokenFinished();
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
        appendParameter();
        if (m_decode_osc_state ==  None) {
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
                                m_current_position - m_current_token_start -1));
                    m_screen->setTitle(title);
                }
                tokenFinished();
            }
        }
    }
}

void Parser::decodeCharacterSet(uchar character)
{
    if (m_decode_graphics_set < 0 || m_decode_graphics_set > (int) (sizeof(m_graphic_codecs) / sizeof(*m_graphic_codecs))) {
        qDebug() << "Parser state is illigal. m_decode_graphics_set is: " << m_decode_graphics_set << "array size is:" << (sizeof(m_graphic_codecs) / sizeof(*m_graphic_codecs));
        m_decode_graphics_set = 0;
        return;
    }
    switch(character) {
        case '0':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::dec_special_graphics);
            break;
        case '4':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_dutch);
            break;
        case '5':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_finnish);
            break;
        case '6':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_norwegian_danish);
            break;
        case '7':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_swedish);
            break;
        case 'A':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_british);
            break;
        case 'B':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::ascii);
            break;
        case 'C':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_finnish);
            break;
        case 'R':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_french);
            break;
        case 'Q':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_french_canadian);
            break;
        case 'K':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_german);
            break;
        case 'Y':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_italian);
            break;
        case 'E':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_norwegian_danish);
            break;
        case 'Z':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_spanish);
            break;
        case 'H':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_swedish);
            break;
        case '=':
            m_graphic_codecs[m_decode_graphics_set] = codecForCharacterset(CharacterSet::nrc_swiss);
            break;
        default:
            qDebug() << "Not supported Character set!" << character << (char) character;
    }
    tokenFinished();
}

void Parser::decodeFontSize(uchar character)
{
    switch(character) {
        case '8':
            if (yat_parser_debug)
                qDebug() << "Filling screen with 'E'";
            m_screen->fill(QChar('E'));
            break;
        default:
            qDebug() << "Failed to decode font size for" << character;
            break;
    }
    tokenFinished();
}

void Parser::setMode(int mode)
{
    switch(mode) {
//Guarded area transfer           GATM*   1
//Keyboard action                 KAM     2
//Control representation          CRM†    3
//Insert/replace                  IRM     4
        case 4:
            m_screen->currentCursor()->setInsertMode(Cursor::Insert);
            break;
//Status reporting transfer       SRTM*   5
//Vertical editing                VEM*    7
//Horizontal editing              HEM*    10
//Positioning unit                PUM*    11
//Send/receive                    SRM     12
//Format effector action          FEAM*   13
//Format effector transfer        FETM*   14
//Multiple area transfer          MATM*   15
//Transfer termination            TTM*    16
//Selected area transfer          SATM*   17
//Tabulation stop                 TSM*    18
//Editing boundary                EBM*    19
//Line feed/new line              LNM     20
        case 20:
            m_lnm_mode_set = true;
            break;
        default:
            qDebug() << "Unhandeled setMode" << mode;
            break;
    }
}

void Parser::setDecMode(int mode)
{
//taken from http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
    switch (mode) {
//1 -> Application Cursor Keys (DECCKM).
    case 1:
        m_screen->setApplicationCursorKeysMode(true);
        break;
//2 -> Designate USASCII for character sets G0-G3 (DECANM), and set VT100 mode.
//3 -> 132 Column Mode (DECCOLM).
    case 3:
        m_screen->emitRequestWidth(132);
        m_screen->emitRequestHeight(24);
        m_screen->clear();
        m_screen->currentCursor()->moveOrigin();
        m_screen->currentCursor()->resetScrollArea();
        break;
//4 -> Smooth (Slow) Scroll (DECSCLM).
    case 4:
        m_screen->setFastScroll(false);
        break;
//5 -> Reverse Video (DECSCNM).
    case 5:
        m_screen->colorPalette()->setInverseDefaultColors(true);
        break;
//6 -> Origin Mode (DECOM).
    case 6:
        m_screen->currentCursor()->setOriginAtMargin(true);
        break;
//7 -> Wraparound Mode (DECAWM).
    case 7:
        m_screen->currentCursor()->setWrapAround(true);
        break;

//8 -> Auto-repeat Keys (DECARM).
//9 -> Send Mouse X & Y on button press. See the section Mouse Tracking.
//10 -> Show toolbar (rxvt).
//12 -> Start Blinking Cursor (att610).
    case 12:
        m_screen->currentCursor()->setBlinking(true);
        break;
//18 -> Print form feed (DECPFF).
//19 -> Set print extent to full screen (DECPEX).
//25 -> Show Cursor (DECTCEM).
    case 25:
        m_screen->currentCursor()->setVisible(true);
        break;
//30 -> Show scrollbar (rxvt).
//35 -> Enable font-shifting functions (rxvt).
//38 -> Enter Tektronix Mode (DECTEK).
//40 -> Allow 80 → 132 Mode.
//41 -> more(1) fix (see curses resource).
//42 -> Enable Nation Replacement Character sets (DECNRCM).
//44 -> Turn On Margin Bell.
//45 -> Reverse-wraparound Mode.
//46 -> Start Logging. This is normally disabled by a compile-time option.
//47 -> Use Alternate Screen Buffer. (This may be disabled by the titeInhibit resource).
    case 47:
        m_screen->useAlternateScreenBuffer();
        break;
//66 -> Application keypad (DECNKM).
//67 -> Backarrow key sends backspace (DECBKM).
//69 -> Enable left and right margin mode (DECLRMM), VT420 and up.
//95 -> Do not clear screen when DECCOLM is set/reset (DECNCSM), VT510 and up.
//1000 → Send Mouse X & Y on button press and release. See the section Mouse Tracking.
//1001 -> Use Hilite Mouse Tracking.
//1002 -> Use Cell Motion Mouse Tracking.
//1003 -> Use All Motion Mouse Tracking.
//1004 -> Send FocusIn/FocusOut events.
//1005 -> Enable UTF-8 Mouse Mode.
//1006 -> Enable SGR Mouse Mode.
//1007 -> Enable Alternate Scroll Mode.
//1010 -> Scroll to bottom on tty output (rxvt).
//1015 -> Enable urxvt Mouse Mode.
//1011 -> Scroll to bottom on key press (rxvt).
//1034 -> Interpret "meta" key, sets eighth bit. (enables the eightBitInput resource).
//1035 -> Enable special modifiers for Alt and NumLock keys. (This enables the numLock resource).
//1036 -> Send ESC when Meta modifies a key. (This enables the metaSendsEscape resource).
//1037 -> Send DEL from the editing-keypad Delete key.
//1039 -> Send ESC when Alt modifies a key. (This enables the altSendsEscape resource).
//1040 -> Keep selection even if not highlighted. (This enables the keepSelection resource).
//1041 -> Use the CLIPBOARD selection. (This enables the selectToClipboard resource).
//1042 -> Enable Urgency window manager hint when Control-G is received. (This enables the bellIsUrgent resource).
//1043 -> Enable raising of the window when Control-G is received. (enables the popOnBell resource).
//1047 -> Use Alternate Screen Buffer. (This may be disabled by the titeInhibit resource).
    case 1047:
        m_screen->useAlternateScreenBuffer();
        break;
//1048 -> Save cursor as in DECSC. (This may be disabled by the titeInhibit resource).
    case 1048:
        m_screen->saveCursor();
        break;
//1049 -> Save cursor as in DECSC and use Alternate Screen Buffer, clearing it first. (This may be disabled by the titeInhibit resource). This combines the effects of the 1047 and 1048 modes. Use this with terminfo-based applications rather than the 47 mode.
    case 1049:
        m_screen->saveCursor();
        m_screen->useAlternateScreenBuffer();
        break;
//1050 -> Set terminfo/termcap function-key mode.
//1051 -> Set Sun function-key mode.
//1052 -> Set HP function-key mode.
//1053 -> Set SCO function-key mode.
//1060 -> Set legacy keyboard emulation (X11R6).
//1061 -> Set VT220 keyboard emulation.
//2004 -> Set bracketed paste mode
    default:
        qDebug() << "Unhandeled setDecMode" << mode;
    }
}

void Parser::resetMode(int mode)
{
    switch(mode) {
//Guarded area transfer           GATM*   1
//Keyboard action                 KAM     2
//Control representation          CRM†    3
//Insert/replace                  IRM     4
        case 4:
            m_screen->currentCursor()->setInsertMode(Cursor::Replace);
            break;
//Status reporting transfer       SRTM*   5
//Vertical editing                VEM*    7
//Horizontal editing              HEM*    10
//Positioning unit                PUM*    11
//Send/receive                    SRM     12
//Format effector action          FEAM*   13
//Format effector transfer        FETM*   14
//Multiple area transfer          MATM*   15
//Transfer termination            TTM*    16
//Selected area transfer          SATM*   17
//Tabulation stop                 TSM*    18
//Editing boundary                EBM*    19
//Line feed/new line              LNM     20
        case 20:
            m_lnm_mode_set = false;
            break;
        default:
            qDebug() << "Unhandeled resetMode" << mode;
            break;
    }
}

void Parser::resetDecMode(int mode)
{
    switch(mode) {
//taken from http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
//1 -> Normal Cursor Keys (DECCKM).
        case 1:
            m_screen->setApplicationCursorKeysMode(false);
            break;
//2 -> Designate VT52 mode (DECANM).
//3 -> 80 Column Mode (DECCOLM).
        case 3:
            m_screen->emitRequestWidth(80);
            m_screen->emitRequestHeight(24);
            m_screen->clear();
            m_screen->currentCursor()->moveOrigin();
            m_screen->currentCursor()->resetScrollArea();
            break;
//4 -> Jump (Fast) Scroll (DECSCLM).
        case 4:
            m_screen->setFastScroll(true);
            break;
//5 -> Normal Video (DECSCNM).
        case 5:
            m_screen->colorPalette()->setInverseDefaultColors(false);
            break;
//6 -> Normal Cursor Mode (DECOM).
        case 6:
            m_screen->currentCursor()->setOriginAtMargin(false);
            break;
//7 -> No Wraparound Mode (DECAWM).
        case 7:
            m_screen->currentCursor()->setWrapAround(false);
            break;
//8 -> No Auto-repeat Keys (DECARM).
//9 -> Don’t send Mouse X & Y on button press.
//10 -> Hide toolbar (rxvt).
//12 -> Stop Blinking Cursor (att610).
        case 12:
            m_screen->currentCursor()->setBlinking(false);
            break;
//18 -> Don’t print form feed (DECPFF).
//19 -> Limit print to scrolling region (DECPEX).
//25 -> Hide Cursor (DECTCEM).
        case 25:
            m_screen->currentCursor()->setVisible(false);
            break;
//30 -> Don’t show scrollbar (rxvt).
//35 -> Disable font-shifting functions (rxvt).
//40 -> Disallow 80 → 132 Mode.
//41 -> No more(1) fix (see curses resource).
//42 -> Disable Nation Replacement Character sets (DECNRCM).
//44 -> Turn Off Margin Bell.
//45 -> No Reverse-wraparound Mode.
//46 -> Stop Logging. (This is normally disabled by a compile-time option).
//47 -> Use Normal Screen Buffer.
        case 47:
            m_screen->useNormalScreenBuffer();
            break;
//66 -> Numeric keypad (DECNKM).
//67 -> Backarrow key sends delete (DECBKM).
//69 -> Disable left and right margin mode (DECLRMM), VT420 and up.
//95 -> Clear screen when DECCOLM is set/reset (DECNCSM), VT510 and up.
//1000 -> Don’t send Mouse X & Y on button press and release. See the section Mouse Tracking.
//1001 -> Don’t use Hilite Mouse Tracking.
//1002 -> Don’t use Cell Motion Mouse Tracking.
//1003 -> Don’t use All Motion Mouse Tracking.
//1004 -> Don’t send FocusIn/FocusOut events.
//1005 -> Disable UTF-8 Mouse Mode.
//1006 -> Disable SGR Mouse Mode.
//1007 -> Disable Alternate Scroll Mode.
//1010 -> Don’t scroll to bottom on tty output (rxvt).
//1015 -> Disable urxvt Mouse Mode.
//1011 -> Don’t scroll to bottom on key press (rxvt).
//1034 -> Don’t interpret "meta" key. (This disables the eightBitInput resource).
//1035 -> Disable special modifiers for Alt and NumLock keys. (This disables the numLock resource).
//1036 -> Don’t send ESC when Meta modifies a key. (This disables the metaSendsEscape resource).
//1037 -> Send VT220 Remove from the editing-keypad Delete key.
//1039 -> Don’t send ESC when Alt modifies a key. (This disables the altSendsEscape resource).
//1040 -> Do not keep selection when not highlighted. (This disables the keepSelection resource).
//1041 -> Use the PRIMARY selection. (This disables the selectToClipboard resource).
//1042 -> Disable Urgency window manager hint when Control-G is received. (This disables the bellIsUrgent resource).
//1043 -> Disable raising of the window when Control-G is received. (This disables the popOnBell resource).
//1047 -> Use Normal Screen Buffer, clearing screen first if in the Alternate Screen. (This may be disabled by the titeInhibit resource).
    case 1047:
            m_screen->useNormalScreenBuffer();
            break;
//1048 -> Restore cursor as in DECRC. (This may be disabled by the titeInhibit resource).
    case 1048:
            m_screen->restoreCursor();
            break;
//1049 -> Use Normal Screen Buffer and restore cursor as in DECRC. (This may be disabled by the titeInhibit resource). This combines the effects of the 1047 and 1048 modes. Use this with terminfo-based applications rather than the 47 mode.
    case 1049:
            m_screen->restoreCursor();
            m_screen->useNormalScreenBuffer();
            break;
//1050 -> Reset terminfo/termcap function-key mode.
//1051 -> Reset Sun function-key mode.
//1052 -> Reset HP function-key mode.
//1053 -> Reset SCO function-key mode.
//1060 -> Reset legacy keyboard emulation (X11R6).
//1061 -> Reset keyboard emulation to Sun/PC style.
//2004 -> Reset bracketed paste mode
    default:
        qDebug() << "Unhandeled resetDecMode" << mode;
        break;
    }
}

void Parser::handleSGR()
{
    for (int i = 0; i < m_parameters.size();i++) {
        switch(m_parameters.at(i)) {
            case 0:
                //                                    m_screen->setTextStyle(TextStyle::Normal);
                m_screen->currentCursor()->resetStyle();
                break;
            case 1:
                m_screen->currentCursor()->setTextStyle(TextStyle::Bold);
                break;
            case 4:
                m_screen->currentCursor()->setTextStyle(TextStyle::Underlined);
                break;
            case 5:
                m_screen->currentCursor()->setTextStyle(TextStyle::Blinking);
                break;
            case 7:
                m_screen->currentCursor()->setTextStyle(TextStyle::Inverse);
                break;
            case 8:
                qDebug() << "SGR: Hidden text not supported";
                break;
            case 22:
                m_screen->currentCursor()->setTextStyle(TextStyle::Bold, false);
                break;
            case 24:
                m_screen->currentCursor()->setTextStyle(TextStyle::Underlined, false);
                break;
            case 25:
                m_screen->currentCursor()->setTextStyle(TextStyle::Blinking, false);
                break;
            case 27:
                m_screen->currentCursor()->setTextStyle(TextStyle::Inverse, false);
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
                m_screen->currentCursor()->setTextStyleColor(m_parameters.at(i));
                break;
            default:
                qDebug() << "Unknown SGR" << m_parameters.at(i);
                break;
        }

    }
}

void Parser::tokenFinished()
{
    m_decode_state = PlainText;
    m_decode_osc_state = None;

    m_parameters.clear();
    m_parameter_string.clear();

    m_current_token_start = m_current_position + 1;
    m_intermediate_char = 0;

    m_parameters_expecting_more = false;
    m_dec_mode = false;
    m_gt_param = false;
    m_contains_only_latin = true;
}

void Parser::appendParameter()
{
    if (m_parameter_string.size()) {
        m_parameters.append(m_parameter_string.toUShort());
        m_parameter_string.clear();
        m_parameters_expecting_more = false;
    }
}

void Parser::handleDefaultParameters(int defaultValue)
{
    for (int i = 0; i < m_parameters.size(); i++) {
        if (m_parameters.at(i) == INT_MIN)
            m_parameters.replace(i, defaultValue);
    }
    if (m_parameters_expecting_more)
        m_parameters.append(defaultValue);
}

QDebug operator<<(QDebug debug, Parser::DecodeState decodeState)
{
    switch(decodeState) {
        case Parser::PlainText:
            debug << "PlainText";
            break;
        case Parser::DecodeC0:
            debug << "DecodeC0";
            break;
        case Parser::DecodeC1_7bit:
            debug << "DecodeC1_7bit";
            break;
        case Parser::DecodeCSI:
            debug << "DecodeCSI";
            break;
        case Parser::DecodeOSC:
            debug << "DecodeOSC";
            break;
        case Parser::DecodeCharacterSet:
            debug << "DecodeCharacterSet";
            break;
        case Parser::DecodeFontSize:
            debug << "DecodeFontSize";
            break;
    }
    return debug;
}
