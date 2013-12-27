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
 ******************************************************************************/

#include "block.h"

#include "text.h"
#include "screen.h"

#include <QtQuick/QQuickView>
#include <QtQuick/QQuickItem>

#include <QtCore/QDebug>

#include <algorithm>

Block::Block(Screen *screen)
    : m_screen(screen)
    , m_line(0)
    , m_new_line(-1)
    , m_width(m_screen->width())
    , m_visible(true)
    , m_changed(true)
    , m_only_latin(true)
{
    clear();
}

Block::~Block()
{
    for (int i = 0; i < m_style_list.size(); i++) {
        m_style_list[i].releaseTextSegment(m_screen);
    }
}

Screen *Block::screen() const
{
    return m_screen;
}

void Block::clear()
{
    m_text_line.clear();

    for (int i = 0; i < m_style_list.size(); i++) {
        m_style_list[i].releaseTextSegment(m_screen);
    }

    m_style_list.clear();

    m_only_latin = true;
    m_changed = true;
}

void Block::clearToEnd(int from)
{
    clearCharacters(from, m_text_line.size() - 1);
}

void Block::clearCharacters(int from, int to)
{
    if (from > m_text_line.size())
        return;

    QString empty(to+1-from, QChar(' '));
    const TextStyle &defaultTextStyle = m_screen->defaultTextStyle();
    replaceAtPos(from, empty, defaultTextStyle);
}

void Block::deleteCharacters(int from, int to)
{
    m_changed = true;

    int removed = 0;
    const int size = (to + 1) - from;
    bool found = false;

    int last_index = -1;

    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        last_index = i;
        if (found) {
            current_style.start_index -= removed;
            current_style.end_index -= removed;
            current_style.index_dirty = true;
            if (removed != size) {
                int current_style_size = current_style.end_index + 1  - current_style.start_index;
                if (current_style_size <= size - removed) {
                    removed += current_style.end_index + 1 - current_style.start_index;
                    current_style.releaseTextSegment(m_screen);
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
                    current_style.releaseTextSegment(m_screen);
                    m_style_list.remove(i);
                    i--;
                }
            }
        }
    }

    if (last_index >= 0) {
        TextStyleLine &last_modified = m_style_list[last_index];
        TextStyle defaultStyle = m_screen->defaultTextStyle();
        if (last_modified.isCompatible(defaultStyle)) {
            last_modified.end_index += size;
            last_modified.text_dirty = true;
        } else {
            m_style_list.insert(last_index + 1, TextStyleLine(defaultStyle,
                        last_modified.end_index + 1, last_modified.end_index + size));
        }
    }

    m_text_line.remove(from, size);
}

void Block::deleteToEnd(int from)
{
    deleteCharacters(from, m_text_line.size() - 1);
}

void Block::deleteLines(int from)
{
    if (from > lineCount())
        return;
}

void Block::replaceAtPos(int pos, const QString &text, const TextStyle &style, bool only_latin)
{
    m_changed = true;
    m_only_latin = m_only_latin && only_latin;

    if (pos >= m_text_line.size()) {
        if (pos > m_text_line.size()) {
            int old_size = m_text_line.size();
            QString filling(pos - m_text_line.size(), QChar(' '));
            m_text_line.append(filling);
            m_style_list.append(TextStyleLine(m_screen->defaultTextStyle(), old_size, old_size + filling.size() -1));
        }
        m_text_line.append(text);
        m_style_list.append(TextStyleLine(style, pos, pos + text.size()-1));
        return;
    } else if (pos + text.size() > m_text_line.size()) {
        m_style_list.append(TextStyleLine(m_screen->defaultTextStyle(), pos + text.size() - m_text_line.size(), pos + text.size() -1));
    }

    m_text_line.replace(pos,text.size(),text);
    bool found = false;
    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        if (found) {
            if (current_style.end_index <= pos + text.size() - 1) {
                current_style.releaseTextSegment(m_screen);
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
                        current_style.text_dirty = true;
                        current_style.style_dirty = true;
                    } else if (current_style.start_index == pos) {
                        current_style.start_index = pos + text.size();
                        current_style.text_dirty = true;
                        m_style_list.insert(i, TextStyleLine(style,pos, pos+text.size() -1));
                    } else if (current_style.end_index == pos + text.size() - 1) {
                        current_style.end_index = pos - 1;
                        current_style.text_dirty = true;
                        m_style_list.insert(i+1, TextStyleLine(style,pos, pos + text.size() - 1));
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
                        if (i > 0 && m_style_list.at(i-1).isCompatible(style)) {
                            TextStyleLine &previous_style = m_style_list[i -1];
                            previous_style.end_index+= text.size();
                            previous_style.text_dirty = true;
                            current_style.releaseTextSegment(m_screen);
                            m_style_list.remove(i);
                            i--;
                        } else {
                            current_style.end_index = pos + text.size() - 1;
                            current_style.style = style.style;
                            current_style.forground = style.forground;
                            current_style.background = style.background;
                            current_style.text_dirty = true;
                            current_style.style_dirty = true;
                            current_style.index_dirty = true;
                        }
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

void Block::insertAtPos(int pos, const QString &text, const TextStyle &style, bool only_latin)
{
    m_changed = true;
    m_only_latin = m_only_latin && only_latin;

    m_text_line.insert(pos,text);
    bool found = false;

    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &current_style = m_style_list[i];
        if (found) {
            current_style.start_index += text.size();
            current_style.end_index += text.size();
            current_style.index_dirty = true;
            if (current_style.start_index >= m_text_line.size()) {
                current_style.releaseTextSegment(m_screen);
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

void Block::setIndex(int index)
{
    if (index != m_new_line) {
        m_changed = true;
        m_new_line = index;
    }
}

QString *Block::textLine()
{
    return &m_text_line;
}

void Block::setVisible(bool visible)
{
    if (visible != m_visible) {
        m_changed = true;
        m_visible = visible;
        for (int i = 0; i < m_style_list.size(); i++) {
            if (m_style_list.at(i).text_segment) {
                m_style_list.at(i).text_segment->setVisible(visible);
            }
        }
    }
}

bool Block::visible() const
{
    return m_visible;
}

Block *Block::split(int line)
{
    if (line >= lineCount())
        return nullptr;
    m_changed = true;
    Block *to_return = new Block(m_screen);
    int start_index = line * m_width;
    for (int i = 0; i < m_style_list.size(); i++) {
        ensureStyleAlignWithLines(i);
        TextStyleLine &current_style = m_style_list[i];
        if (current_style.start_index >= start_index) {
            current_style.start_index -= start_index;
            current_style.old_index = current_style.start_index - 1;
            current_style.end_index -= start_index;
            current_style.index_dirty = true;
            current_style.text_dirty = true;
            current_style.index_dirty = true;
            to_return->m_style_list.append(TextStyleLine(current_style, current_style.start_index,
                        current_style.end_index));
            m_style_list.remove(i);
            i--;
        }
    }
    to_return->m_text_line = m_text_line.mid(start_index, m_text_line.size() - start_index);
    m_text_line.remove(start_index, m_text_line.size() - start_index);
    return to_return;
}

Block *Block::takeLine(int line)
{
    if (line >= lineCount())
        return nullptr;
    m_changed = true;
    Block *to_return = new Block(m_screen);
    int start_index = line * m_width;
    int end_index = start_index + (m_width - 1);
    for (int i = 0; i < m_style_list.size(); i++) {
        ensureStyleAlignWithLines(i);
        TextStyleLine &current_style = m_style_list[i];
        if (current_style.start_index >= start_index && current_style.end_index <= end_index) {
            current_style.releaseTextSegment(m_screen);
            current_style.start_index -= start_index;
            current_style.end_index -= start_index;
            current_style.index_dirty = true;
            to_return->m_style_list.append(TextStyleLine(current_style, current_style.start_index,
                        current_style.end_index));
            m_style_list.remove(i);
            i--;
        } else if (current_style.start_index > end_index) {
            current_style.start_index -= (end_index + 1) - start_index;
            current_style.end_index -= (end_index + 1) - start_index;
            current_style.index_dirty = true;
            current_style.text_dirty = true;
        }
    }
    to_return->m_text_line = m_text_line.mid(start_index, m_width);
    m_text_line.remove(start_index, m_width);
    return to_return;
}

void Block::removeLine(int line)
{
    if (line >= lineCount())
        return;

    m_changed = true;
    int start_index = line * m_width;
    int end_index = start_index + (m_width - 1);
    for (int i = 0; i < m_style_list.size(); i++) {
        ensureStyleAlignWithLines(i);
        TextStyleLine &current_style = m_style_list[i];
        if (current_style.start_index >= start_index && current_style.end_index <= end_index) {
            current_style.releaseTextSegment(m_screen);
            m_style_list.remove(i);
            i--;
        } else if (current_style.start_index > end_index) {
            current_style.start_index -= (end_index + 1) - start_index;
            current_style.end_index -= (end_index + 1) - start_index;
            current_style.index_dirty = true;
            current_style.text_dirty = true;
        }
    }
    m_text_line.remove(start_index, m_width);
}

void Block::moveLinesFromBlock(Block *block, int start_line, int count)
{
    Q_ASSERT(block);
    Q_ASSERT(block->lineCount() >= start_line + count);

    int start_char = block->width() * start_line;
    int end_char = (block->width() * (start_line + count)) - 1;

    for (int i = 0; i < block->m_style_list.size(); i++) {
        TextStyleLine &current_style = block->m_style_list[i];
        if (current_style.start_index >= start_char && current_style.end_index <= end_char) {
            current_style.start_index += (-start_char + m_text_line.size());
            current_style.end_index += (-start_char + m_text_line.size());
            current_style.releaseTextSegment(m_screen);
            m_style_list.append(TextStyleLine(current_style, current_style.start_index,
                        current_style.end_index));
            block->m_style_list.remove(i);
            i--;
        } else if (current_style.start_index > end_char) {
            current_style.start_index -= (end_char + 1) - start_char;
            current_style.end_index -= (end_char + 1) - start_char;
            current_style.index_dirty = true;
            current_style.text_dirty = true;
        }
    }

    m_text_line.append(block->m_text_line.mid(start_char, (end_char + 1) - start_char));
    block->m_text_line.remove(start_char, (end_char + 1) - start_char);
    m_changed = true;
    block->m_changed = true;
}

void Block::dispatchEvents()
{
    if (!m_changed) {
        return;
    }

    mergeCompatibleStyles();

    for (int i = 0; i < m_style_list.size(); i++) {
        ensureStyleAlignWithLines(i);
        TextStyleLine &current_style = m_style_list[i];
         if (current_style.text_segment == 0) {
             current_style.text_segment = m_screen->createTextSegment(current_style);
            current_style.text_segment->setLine(m_new_line, m_width, &m_text_line);
         } else if (m_new_line != m_line) {
            current_style.text_segment->setLine(m_new_line, m_width, &m_text_line);
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

        current_style.text_segment->setLatin(m_only_latin);
        current_style.text_segment->dispatchEvents();
    }

    m_changed = false;
    m_line = m_new_line;

}

void Block::releaseTextObjects()
{
    m_changed = true;
    for (int i = 0; i < m_style_list.size(); i++) {
        TextStyleLine &currentStyleLine = m_style_list[i];
        currentStyleLine.releaseTextSegment(m_screen);
        currentStyleLine.text_dirty = true;
        currentStyleLine.style_dirty = true;
    }
}

QVector<TextStyleLine> Block::style_list()
{
    return m_style_list;
}

void Block::printStyleList() const
{
    QDebug debug = qDebug();
    printStyleList(debug);
}

void Block::printStyleList(QDebug &debug) const
{
    QString text_line = m_text_line;
    debug << "  " << m_line << lineCount() << m_text_line.size() << (void *) this << text_line << "\n"; debug << "\t";
    for (int i= 0; i < m_style_list.size(); i++) {
        debug << m_style_list.at(i);
    }
}

void Block::printStyleListWidthText() const
{
    QString text_line = m_text_line;
    for (int i= 0; i < m_style_list.size(); i++) {
        const TextStyleLine &currentStyle = m_style_list.at(i);
        QDebug debug = qDebug();
        debug << m_text_line.mid(currentStyle.start_index, (currentStyle.end_index + 1) - currentStyle.start_index) << currentStyle;
    }
}

void Block::mergeCompatibleStyles()
{
    for (int i = 1; i < m_style_list.size(); i++) {
        TextStyleLine &current = m_style_list[i];
        if (m_style_list.at(i - 1).isCompatible(current) &&
                current.start_index % m_width != 0) {
            TextStyleLine &prev = m_style_list[i-1];
            prev.end_index = current.end_index;
            prev.text_dirty = true;
            current.releaseTextSegment(m_screen);
            m_style_list.remove(i);
            i--;
        }
    }
}

void Block::ensureStyleAlignWithLines(int i)
{
    int start_line = m_style_list[i].start_index / m_width;
    int end_line = m_style_list[i].end_index / m_width;
    if (start_line != end_line) {
        int remainder_start_line = ((m_width * (start_line + 1))-1) - m_style_list[i].start_index;
        int next_line_end_index = m_style_list[i].end_index;
        m_style_list[i].end_index = m_style_list[i].start_index + remainder_start_line;
        m_style_list.insert(i + 1, TextStyleLine(m_style_list[i], m_style_list[i].end_index + 1, next_line_end_index));
    }
}
