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

#ifndef PARSER_H
#define PARSER_H

#include <QtCore/QString>
#include <QtCore/QVector>
#include <QtCore/QLinkedList>

#include "controll_chars.h"
#include "utf8_decoder.h"

class Screen;

class Parser
{
public:
    Parser(Screen *screen);

    void addData(const QByteArray &data);

private:

    enum DecodeState {
        PlainText,
        DecodeC0,
        DecodeC1_7bit,
        DecodeCSI,
        DecodeOSC,
        DecodeCharacterSet,
        DecodeFontSize
    };

    enum DecodeOSCState {
        None,
        ChangeWindowAndIconName,
        ChangeIconTitle,
        ChangeWindowTitle,
        Unknown
    };

    void decodeC0(uchar character);
    void decodeC1_7bit(uchar character);
    void decodeParameters(uchar character);
    void decodeCSI(uchar character);
    void decodeOSC(uchar character);
    void decodeCharacterSet(uchar character);
    void decodeFontSize(uchar character);

    void setMode(int mode);
    void setDecMode(int mode);
    void resetMode(int mode);
    void resetDecMode(int mode);

    void handleSGR();

    void tokenFinished();

    void appendParameter();
    void handleDefaultParameters(int defaultValue);

    DecodeState m_decode_state;
    DecodeOSCState m_decode_osc_state;

    QByteArray m_current_data;

    int m_current_token_start;
    int m_current_position;

    QChar m_intermediate_char;

    QByteArray m_parameter_string;
    QVector<int> m_parameters;
    bool m_parameters_expecting_more;
    bool m_dec_mode;
    bool m_gt_param;
    bool m_lnm_mode_set;
    bool m_contains_only_latin;

    int m_decode_graphics_set;
    QTextCodec *m_graphic_codecs[4];
    Utf8Decoder m_utf8_decoder;

    Screen *m_screen;
    friend QDebug operator<<(QDebug debug, DecodeState decodeState);
};
QDebug operator<<(QDebug debug, Parser::DecodeState decodeState);

#endif // PARSER_H
