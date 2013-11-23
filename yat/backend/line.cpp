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

#include "line.h"

#include "text.h"
#include "screen.h"

#include <QtQuick/QQuickView>
#include <QtQuick/QQuickItem>

#include <QtCore/QDebug>

#include <algorithm>

QDebug operator<<(QDebug debug, TextStyleLine line)
{
    debug << "TextStyleLine: [" << line.start_index << ":" << line.end_index << "] : style:" << line.style;
    return debug;
}

Line::Line(Screen *screen)
    : QObject(screen)
    , m_screen(screen)
    , m_index(0)
    , m_old_index(-1)
    , m_visible(true)
    , m_changed(true)
{
    m_text_line.resize(screen->width());
    m_style_list.reserve(25);

    clear();
}

Line::~Line()
{
    releaseTextObjects();
}

Screen *Line::screen() const
{
    return m_screen;
}

void Line::releaseTextObjects()
{
    m_changed = true;
    for (int i = 0; i < m_style_list.size(); i++) {
        if (m_style_list.at(i).text_segment) {
            m_style_list.at(i).text_segment->setVisible(false);
            delete m_style_list.at(i).text_segment;
            m_style_list[i].text_segment = 0;
        }
    }
}

void Line::clear()
{
    m_text_line.fill(QChar(' '));

    for (int i = 0; i < m_style_list.size(); i++) {
        if (m_style_list.at(i).text_segment)
            releaseTextSegment(m_style_list.at(i).text_segment);
    }

    m_style_list.clear();
    m_style_list.append(TextStyleLine(m_screen->defaultTextStyle(),0,m_text_line.size() -1));

    m_changed = true;
}

void Line::clearToEndOfLine(int index)
{
    m_changed = true;

    QString empty(m_text_line.size() - index, QChar(' '));
    m_text_line.replace(index, m_text_line.size()-index,empty);
    bool found = false;
    for (int i = 0; i < m_style_list.size(); i++) {
        const TextStyleLine current_style = m_style_list.at(i);
        if (found) {
            if (current_style.text_segment)
                releaseTextSegment(current_style.text_segment);
            m_style_list.remove(i);
            i--;
        } else {
            if (index <= current_style.end_index) {
                found = true;
                if (current_style.start_index == index) {
                    if (current_style.text_segment)
                        releaseTextSegment(current_style.text_segment);
                    m_style_list.remove(i);
                    i--;
                } else {
                    m_style_list[i].end_index = index - 1;
                    m_style_list[i].text_dirty = true;
                }
            }
        }
    }

    if (m_style_list.size() && m_style_list.last().isCompatible(m_screen->defaultTextStyle())) {
        m_style_list.last().end_index = m_text_line.size() -1;
    } else {
        m_style_list.append(TextStyleLine(m_screen->defaultTextStyle(),index, m_text_line.size() -1));
    }
}

void Line::clearCharacters(int from, int to)
{
    QString empty(to-from, QChar(' '));
    const TextStyle &defaultTextStyle = m_screen->defaultTextStyle();
    replaceAtPos(from, empty, defaultTextStyle);
}

void Line::deleteCharacters(int from, int to)
{
    m_changed = true;

    int removed = 0;
    const int size = (to + 1) - from;
    bool found = false;

    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        if (found) {
            current_style.start_index -= removed;
            current_style.end_index -= removed;
            current_style.index_dirty = true;
            if (removed != size) {
                int current_style_size = current_style.end_index + 1  - current_style.start_index;
                if (current_style_size <= size - removed) {
                    removed += current_style.end_index + 1 - current_style.start_index;
                    if (current_style.text_segment)
                        releaseTextSegment(current_style.text_segment);
                    m_style_list.remove(i);
                    i--;
                } else {
                    current_style.end_index -= size - removed;
                    removed = size;
                }
            }
        } else {
            if (current_style.start_index <= from && current_style.end_index >= from) {
                found = true;
                int left_in_style = (current_style.end_index + 1) - from;
                int subtract = std::min(left_in_style, size);
                current_style.end_index -= subtract;
                current_style.text_dirty = true;
                removed = subtract;
                if (current_style.end_index < current_style.start_index) {
                    if (current_style.text_segment)
                        releaseTextSegment(current_style.text_segment);
                    m_style_list.remove(i);
                    i--;
                }
            }
        }
    }

    TextStyle defaultStyle = m_screen->defaultTextStyle();
    if (m_style_list.last().isCompatible(defaultStyle)) {
        m_style_list.last().end_index += size;
        m_style_list.last().text_dirty = true;
    } else {
        m_style_list.append(TextStyleLine(defaultStyle, m_style_list.last().end_index + 1,
                    m_style_list.last().end_index + size));
    }

    m_text_line.remove(from, size);
    QString empty(size,' ');
    m_text_line.append(empty);
}

void Line::setWidth(int width)
{
    bool emit_changed = m_text_line.size() != width;
    if (m_text_line.size() > width) {
        m_text_line.chop(m_text_line.size() - width);
    } else if (m_text_line.size() < width) {
        m_text_line.append(QString(width - m_text_line.size(), QChar(' ')));
    }

    if (emit_changed)
        emit widthChanged();
}

int Line::width() const
{
    return m_style_list.size();
}

void Line::replaceAtPos(int pos, const QString &text, const TextStyle &style)
{
    Q_ASSERT(pos + text.size() <= m_text_line.size());

    m_changed = true;

    m_text_line.replace(pos,text.size(),text);
    bool found = false;
    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        if (found) {
            if (current_style.end_index <= pos + text.size()) {
                if (current_style.text_segment)
                    releaseTextSegment(current_style.text_segment);
                m_style_list.remove(i);
                i--;
            } else if (current_style.start_index <= pos + text.size()) {
                current_style.start_index = pos + text.size();
                current_style.style_dirty = true;
                current_style.text_dirty = true;
                current_style.index_dirty = true;
            } else {
                break;
            }
        } else if (pos >= current_style.start_index && pos <= current_style.end_index) {
            found = true;
            if (pos + text.size() -1 <= current_style.end_index) {
                if (current_style.isCompatible(style)) {
                    current_style.text_dirty = true;
                } else {
                    if (current_style.start_index == pos && current_style.end_index == pos + text.size() - 1) {
                        current_style.setStyle(style);
                    } else if (current_style.start_index == pos) {
                        current_style.start_index = pos + text.size();
                        current_style.text_dirty = true;
                        m_style_list.insert(i, TextStyleLine(style,pos, pos+text.size() -1));
                    } else if (current_style.end_index == pos + text.size()) {
                        current_style.end_index = pos - 1;
                        current_style.text_dirty = true;
                        m_style_list.insert(i+1, TextStyleLine(style,pos, pos+text.size()));
                    } else {
                        int old_end = current_style.end_index;
                        current_style.end_index = pos - 1;
                        current_style.text_dirty = true;
                        m_style_list.insert(i+1, TextStyleLine(style,pos, pos + text.size() - 1));
                        if (pos + text.size() < m_text_line.size()) {
                            m_style_list.insert(i+2, TextStyleLine(current_style,pos + text.size(), old_end));
                        }
                    }
                }
                break;
            } else {
                if (current_style.isCompatible(style)) {
                    current_style.end_index = pos + text.size() - 1;
                    current_style.text_dirty = true;
                } else {
                    if (current_style.start_index == pos) {
                        current_style.end_index = pos + text.size() - 1;
                        current_style.style = style.style;
                        current_style.forground = style.forground;
                        current_style.background = style.background;
                        current_style.text_dirty = true;
                        current_style.style_dirty = true;
                    } else {
                        current_style.end_index = pos - 1;
                        current_style.text_dirty = true;
                        m_style_list.insert(i+1, TextStyleLine(style, pos, pos + text.size() -1));
                        i++;
                    }
                }
            }
        }
    }
}

void Line::insertAtPos(int pos, const QString &text, const TextStyle &style)
{
    m_changed = true;

    m_text_line.insert(pos,text);
    m_text_line.chop(text.size());
    bool found = false;

    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        if (found) {
            current_style.start_index += text.size();
            current_style.end_index += text.size();
            current_style.index_dirty = true;
            if (current_style.start_index >= m_text_line.size()) {
                releaseTextSegment(current_style.text_segment);
                m_style_list.remove(i);
                i--;
            } else if (current_style.end_index >= m_text_line.size()) {
                current_style.end_index = m_text_line.size()-1;
            }
        } else if (pos >= current_style.start_index && pos <= current_style.end_index) {
            found = true;
            if (current_style.start_index == pos) {
                current_style.start_index += text.size();
                current_style.end_index += text.size();
                current_style.index_dirty = true;
                m_style_list.insert(i, TextStyleLine(style, pos, pos+ text.size() - 1));
                i++;
            } else if (current_style.end_index == pos) {
                current_style.end_index--;
                current_style.text_dirty = true;
                m_style_list.insert(i+1, TextStyleLine(style, pos, pos+ text.size() - 1));
                i++;
            } else {
                int old_end = current_style.end_index;
                current_style.end_index = pos -1;
                current_style.text_dirty = true;
                m_style_list.insert(i+1, TextStyleLine(style, pos, pos + text.size() - 1));
                if (pos + text.size() < m_text_line.size()) {
                    int segment_end = std::min(m_text_line.size() -1, old_end + text.size());
                    m_style_list.insert(i+2, TextStyleLine(current_style, pos + text.size(), segment_end));
                    i+=2;
                } else {
                    i++;
                }
            }
        }
    }
}

int Line::index() const
{
    return m_index;
}

void Line::setIndex(int index)
{
    m_index = index;
}

QString *Line::textLine()
{
    return &m_text_line;
}

void Line::setVisible(bool visible)
{
    if (visible != m_visible) {
        m_visible = visible;
        emit visibleChanged();
    }
}

bool Line::visible() const
{
    return m_visible;
}

void Line::dispatchEvents()
{
    if (m_index != m_old_index) {
        m_old_index = m_index;
        emit indexChanged();
    }

    if (!m_changed) {
        return;
    }

    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];

        if (current_style.text_segment == 0) {
            current_style.text_segment = createTextSegment(current_style);
        }

        if (current_style.style_dirty) {
            current_style.text_segment->setTextStyle(current_style);
            current_style.style_dirty = false;
        }

        if (current_style.index_dirty || current_style.text_dirty) {
            current_style.text_segment->setStringSegment(current_style.start_index, current_style.end_index, current_style.text_dirty);
            current_style.index_dirty = false;
            current_style.text_dirty = false;
        }

        m_style_list.at(i).text_segment->dispatchEvents();
    }

    m_changed = false;

    for (int i = 0; i< m_to_delete.size(); i++) {
        delete m_to_delete[i];
    }
    m_to_delete.clear();
}

QVector<TextStyleLine> Line::style_list()
{
    return m_style_list;
}

Text *Line::createTextSegment(const TextStyleLine &style_line)
{
    Text *to_return;
    if (m_to_delete.size()) {
        to_return = m_to_delete.takeLast();
    } else {
        to_return = new Text(screen());
        to_return->setLine(this);
        emit textCreated(to_return);
    }

    to_return->setVisible(true);

    return to_return;
}

void Line::releaseTextSegment(Text *text)
{
    text->setVisible(false);
    m_to_delete.append(text);
}

void Line::printStyleList() const
{
    for (int i= 0; i < m_style_list.size(); i++) {
        qDebug() << "i" << m_style_list.at(i);
    }
}
