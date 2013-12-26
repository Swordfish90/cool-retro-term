/******************************************************************************
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

#include "nrc_text_codec.h"

static bool nrc_text_codec_init = false;
void NrcTextCodec::initialize()
{
    if (!nrc_text_codec_init) {
        nrc_text_codec_init = true;
        new NrcTextCodec("dec_special_graphics", 500001, dec_special_graphics_char_set);
        new NrcTextCodec("nrc_british", 500002, nrc_british_char_set);
        new NrcTextCodec("nrc_norwegian_danish", 5002, nrc_norwegian_danish_char_set);
        new NrcTextCodec("nrc_dutch", 5002, nrc_dutch_char_set);
        new NrcTextCodec("nrc_finnish", 5002, nrc_finnish_char_set);
        new NrcTextCodec("nrc_french", 5002, nrc_french_char_set);
        new NrcTextCodec("nrc_french_canadian", 5002, nrc_french_canadian_char_set);
        new NrcTextCodec("nrc_german", 5002, nrc_german_char_set);
        new NrcTextCodec("nrc_italian", 5002, nrc_italian_char_set);
        new NrcTextCodec("nrc_spanish", 5002, nrc_spanish_char_set);
        new NrcTextCodec("nrc_swedish", 5002, nrc_swedish_char_set);
        new NrcTextCodec("nrc_swiss", 5002, nrc_swiss_char_set);
    }
}

NrcTextCodec::NrcTextCodec(const QByteArray &name, int mib, const QChar character_set[])
    : QTextCodec()
    , m_name(name)
    , m_mib(mib)
    , m_character_set(character_set)
{
}

QByteArray  NrcTextCodec::name() const
{
    return m_name;
}
int NrcTextCodec::mibEnum() const
{
    return m_mib;
}

QString NrcTextCodec::convertToUnicode(const char *in, int length, QTextCodec::ConverterState *state) const
{
    QString ret_str;
    ret_str.reserve(length);
    for (int i = 0; i < length; i++) {
        uchar in_char = *(in + i);
        if (in_char < 128) {
            QChar unicode = m_character_set[in_char];
            if (unicode.isNull())
                unicode = QChar(in_char);
            ret_str.append(unicode);
        } else {
            if (state) {
                if (state->flags & QTextCodec::ConvertInvalidToNull) {
                    state->invalidChars++;
                    ret_str.append(0);
                } else {
                    state->invalidChars++;
                    state->remainingChars = length - i;
                    return ret_str;
                }
            }
        }
    }
    return ret_str;
}

QByteArray NrcTextCodec::convertFromUnicode(const QChar *in, int length, ConverterState *state) const
{
    QByteArray ret_array;
    ret_array.reserve(length);

    for (int i = 0; i < length; i++) {
        QChar out_char = *(in + i);
        if (out_char.unicode() < 128) {
            uchar out = out_char.unicode();
            ret_array.append(out);
        } else {
            bool found = false;
            for (uchar n = 0; n < 128; n++) {
                if (m_character_set[n] == out_char) {
                    ret_array.append(n);
                    found = true;
                    break;
                }
            }

            if (!found && state) {
                if (state->flags & QTextCodec::ConvertInvalidToNull) {
                    state->invalidChars++;
                    ret_array.append(char(0));
                } else {
                    state->invalidChars++;
                    state->remainingChars = length - i;
                    return ret_array;
                }
            }
        }
    }
    return ret_array;
}

