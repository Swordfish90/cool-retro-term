/*******************************************************************************
* Copyright (c) 2013 Jørgen Lind
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

#ifndef UTF8_DECODER
#define UTF8_DECODER

#include "controll_chars.h"

class Utf8Decoder
{
public:
    inline Utf8Decoder();

    inline void addChar(uchar character);

    inline bool isLatin() const;
    inline bool isC1() const;

    inline void clear();
private:
    short m_expected_length;
    short m_length;
    uint32_t m_unicode;
};

Utf8Decoder::Utf8Decoder()
{
    clear();
}

void Utf8Decoder::addChar(uchar character)
{
    if (m_length && m_length == m_expected_length) {
        clear();
    }

    if (character < 0x80)
        return;

    fprintf(stderr, "Character: 0x%x\n", character);
    if (m_expected_length == 0) {
        //this is naive. There must be a faster way.
        if ((character & 0xfc) == 0xfc) {
            m_expected_length = 5;
            m_unicode = character & 0x01;
        } else if ((character & 0xf8) == 0xf8) {
            m_expected_length = 4;
            m_unicode = character & 0x03;
        } else if ((character & 0xf0) == 0xf0) {
            m_expected_length = 3;
            m_unicode = character & 0x07;
        } else if ((character & 0xe0) == 0xe0) {
            m_expected_length = 2;
            m_unicode = character & 0x0f;
        } else if ((character & 0xc0) == 0xc0) {
            m_expected_length = 1;
            m_unicode = character & 0x1f;
        } else {
            m_expected_length = 0;
            m_unicode = 0;
            qWarning("Utf8Decoder: invalid decoder character");
        }
    } else {
        fprintf(stderr, "Before 0x%x adding 0x%x pure 0x%x\n", m_unicode,(character & 0x3f), character);
        m_unicode = (m_unicode << 6) |  (character & 0x3f);
        fprintf(stderr, "After 0x%x\n", m_unicode);
        m_length++;
    }
}

bool Utf8Decoder::isLatin() const
{
    return m_expected_length < 2 && m_unicode < 0xff;
}

bool Utf8Decoder::isC1() const
{
    return m_expected_length == 2 && m_length == m_expected_length &&
        (m_unicode >= C1_8bit::C1_8bit_Start && m_unicode <= C1_8bit::C1_8bit_Stop);
}

void Utf8Decoder::clear()
{
    m_expected_length = 0;
    m_length = 0;
    m_unicode = 0;
}

#endif
