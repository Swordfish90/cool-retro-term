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
#include "line.h"
#include <QtQuick/QQuickItem>

#include <QtCore/QDebug>

Text::Text(Screen *screen)
    : QObject(screen)
    , m_style_dirty(true)
    , m_text_dirty(true)
    , m_visible(true)
    , m_visible_old(true)
    , m_line(0)
{
}

Text::~Text()
{
    emit aboutToBeDestroyed();
}

void Text::setLine(Line *line)
{
    if (line == m_line)
        return;
    m_line = line;
    if (m_line) {
        m_text_line = line->textLine();
    }
}

int Text::index() const
{
    return m_start_index;
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
    if (m_style.style & TextStyle::Inverse) {
        if (m_style.background == ColorPalette::DefaultBackground)
            return screen()->screenBackground();
        return screen()->colorPalette()->color(m_style.background, m_style.style & TextStyle::Bold);
    }

    return screen()->colorPalette()->color(m_style.forground, m_style.style & TextStyle::Bold);
}


QColor Text::backgroundColor() const
{
    if (m_style.style & TextStyle::Inverse)
        return screen()->colorPalette()->color(m_style.forground, false);

    return screen()->colorPalette()->color(m_style.background, false);
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

Screen *Text::screen() const
{
    return m_line->screen();
}

void Text::dispatchEvents()
{
    if (m_style_dirty) {
        m_style_dirty = false;

        bool emit_forground = m_new_style.forground != m_style.forground;
        bool emit_background = m_new_style.background != m_style.background;
        bool emit_text_style = m_new_style.style != m_style.style;

        m_style = m_new_style;
        if (emit_forground)
            emit forgroundColorChanged();
        if (emit_background)
            emit backgroundColorChanged();
        if (emit_text_style)
            emit textStyleChanged();
    }

    if (m_old_start_index != m_start_index
            || m_text_dirty) {
        m_text_dirty = false;
        m_text = m_text_line->mid(m_start_index, m_end_index + 1 - m_start_index);
        if (m_old_start_index != m_start_index) {
            m_old_start_index = m_start_index;
            emit indexChanged();
        }
        emit textChanged();
    }

    if (m_visible_old != m_visible) {
        m_visible_old = m_visible;
        emit visibleChanged();
    }
}

