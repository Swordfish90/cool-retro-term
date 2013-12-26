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

#include "text.h"

#include "screen.h"
#include "block.h"
#include <QtQuick/QQuickItem>

#include <QtCore/QDebug>

Text::Text(Screen *screen)
    : QObject(screen)
    , m_screen(screen)
    , m_text_line(0)
    , m_start_index(0)
    , m_old_start_index(0)
    , m_end_index(0)
    , m_line(0)
    , m_old_line(0)
    , m_width(1)
    , m_style_dirty(true)
    , m_text_dirty(true)
    , m_visible(true)
    , m_visible_old(true)
    , m_latin(true)
    , m_latin_old(true)
    , m_forgroundColor(m_screen->defaultForgroundColor())
    , m_backgroundColor(m_screen->defaultBackgroundColor())
{
    connect(m_screen->colorPalette(), SIGNAL(changed()), this, SLOT(paletteChanged()));
    connect(m_screen, SIGNAL(dispatchTextSegmentChanges()), this, SLOT(dispatchEvents()));
}

Text::~Text()
{
}

int Text::index() const
{
    return m_start_index % m_width;
}

int Text::line() const
{
    return m_line + (m_start_index / m_width);
}

void Text::setLine(int line, int width, const QString *textLine)
{
    m_line = line;
    m_width = width;
    m_text_dirty = true;
    m_text_line = textLine;
}

bool Text::visible() const
{
    return m_visible;
}

void Text::setVisible(bool visible)
{
    m_visible = visible;
}

QString Text::text() const
{
    return m_text;
}

QColor Text::foregroundColor() const
{
    return m_forgroundColor;
}


QColor Text::backgroundColor() const
{
    return m_backgroundColor;
}

void Text::setStringSegment(int start_index, int end_index, bool text_changed)
{
    m_start_index = start_index;
    m_end_index = end_index;

    m_text_dirty = text_changed;
}

void Text::setTextStyle(const TextStyle &style)
{
    m_new_style = style;
    m_style_dirty = true;
}

bool Text::bold() const
{
    return m_style.style & TextStyle::Bold;
}

bool Text::blinking() const
{
    return m_style.style & TextStyle::Blinking;
}

bool Text::underline() const
{
    return m_style.style & TextStyle::Underlined;
}

void Text::setLatin(bool latin)
{
    m_latin = latin;
}

bool Text::latin() const
{
    return m_latin_old;
}

static bool differentStyle(TextStyle::Styles a, TextStyle::Styles b, TextStyle::Style style)
{
    return (a & style) != (b & style);
}

void Text::dispatchEvents()
{
    int old_line = m_old_line + (m_old_start_index / m_width);
    int new_line = m_line + (m_start_index / m_width);
    if (old_line != new_line) {
        m_old_line = m_line;
        emit lineChanged();
    }

    if (m_latin != m_latin_old) {
        m_latin_old = m_latin;
        emit latinChanged();
    }

    if (m_old_start_index != m_start_index
            || m_text_dirty) {
        m_text_dirty = false;
        QString old_text = m_text;
        m_text = m_text_line->mid(m_start_index, m_end_index - m_start_index + 1);
        if (m_old_start_index != m_start_index) {
            m_old_start_index = m_start_index;
            emit indexChanged();
        }
        emit textChanged();
    }

    if (m_style_dirty) {
        m_style_dirty = false;

        bool emit_forground = m_new_style.forground != m_style.forground;
        bool emit_background = m_new_style.background != m_style.background;
        TextStyle::Styles new_style = m_new_style.style;
        TextStyle::Styles old_style = m_style.style;

        bool emit_bold = false;
        bool emit_blink = false;
        bool emit_underline = false;
        bool emit_inverse = false;
        if (new_style != old_style) {
            emit_bold = differentStyle(new_style, old_style, TextStyle::Bold);
            emit_blink = differentStyle(new_style, old_style, TextStyle::Blinking);
            emit_underline = differentStyle(new_style, old_style, TextStyle::Underlined);
            emit_inverse = differentStyle(new_style, old_style, TextStyle::Inverse);
        }

        m_style = m_new_style;
        if (emit_inverse) {
            setForgroundColor();
            setBackgroundColor();
        } else {
            if (emit_forground || emit_bold) {
                setForgroundColor();
            }
            if (emit_background) {
                setBackgroundColor();
            }
        }

        if (emit_bold) {
            emit boldChanged();
        }

        if (emit_blink) {
            emit blinkingChanged();
        }

        if (emit_underline) {
            emit underlineChanged();
        }

    }


    if (m_visible_old != m_visible) {
        m_visible_old = m_visible;
        emit visibleChanged();
    }
}

void Text::paletteChanged()
{
    setBackgroundColor();
    setForgroundColor();
}

void Text::setBackgroundColor()
{
    QColor new_background;
    if (m_style.style & TextStyle::Inverse) {
        new_background = m_screen->colorPalette()->color(m_style.forground, false);
    } else {
        new_background = m_screen->colorPalette()->color(m_style.background, false);
    }
    if (new_background != m_backgroundColor) {
        m_backgroundColor = new_background;
        emit backgroundColorChanged();
    }
}

void Text::setForgroundColor()
{
    QColor new_forground;
    if (m_style.style & TextStyle::Inverse) {
        new_forground = m_screen->colorPalette()->color(m_style.background, false);
    } else {
        new_forground = m_screen->colorPalette()->color(m_style.forground, false);
    }
    if (new_forground != m_forgroundColor) {
        m_forgroundColor = new_forground;
        emit forgroundColorChanged();
    }
}
