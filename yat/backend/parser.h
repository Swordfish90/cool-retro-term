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

#ifndef PARSER_H
#define PARSER_H

#include <QtCore/QString>
#include <QtCore/QVector>
#include <QtCore/QLinkedList>

#include "text.h"

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
        DecodeOtherEscape
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
    void decodeOtherEscape(uchar character);

    void tokenFinished();

    void appendParameter();

    DecodeState m_decode_state;
    DecodeOSCState m_decode_osc_state;

    QByteArray m_current_data;

    int m_current_token_start;
    int m_currrent_position;

    QChar m_intermediate_char;

    QByteArray m_parameter_string;
    QVector<int> m_parameters;

    Screen *m_screen;
};

#endif // PARSER_H
