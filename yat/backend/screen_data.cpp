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

#include "screen_data.h"

#include "line.h"
#include "screen.h"

#include <stdio.h>

#include <QtGui/QGuiApplication>
#include <QtCore/QDebug>

ScreenData::ScreenData(Screen *screen)
    : m_screen(screen)
    , m_scroll_start(0)
    , m_scroll_end(0)
    , m_scroll_area_set(false)
{
}

ScreenData::~ScreenData()
{
    for (int i = 0; i < m_screen_lines.size(); i++) {
        delete m_screen_lines.at(i);
    }
}


int ScreenData::width() const
{
    return m_width;
}

void ScreenData::setWidth(int width)
{
    if (width == m_width)
        return;

    m_width = width;

    for (int i = 0; i < m_screen_lines.size(); i++) {
        m_screen_lines.at(i)->setWidth(width);
    }
}

int ScreenData::height() const
{
    return m_screen_lines.size();
}

void ScreenData::setHeight(int height)
{
    if (height == m_screen_lines.size())
        return;

    if (m_screen_lines.size() > height) {
        int removeElements = m_screen_lines.size() - height;
        for (int i = 0; i < m_screen_lines.size(); i++) {
            if (i <removeElements) {
                int not_broadcasted = m_new_lines.indexOf(m_screen_lines.at(i));
                if (not_broadcasted >= 0)
                    m_new_lines.remove(not_broadcasted);
                delete m_screen_lines[i];
            } else {
                m_screen_lines.at(i)->setIndex(i - removeElements);
            }
        }
        m_screen_lines.remove(0, removeElements);
    } else if (m_screen_lines.size() < height){
        int rowsToAdd = height - m_screen_lines.size();
        for (int i = 0; i < rowsToAdd; i++) {
            Line *newLine = new Line(m_screen);
            m_screen_lines.append(newLine);
            m_new_lines.append(newLine);
            newLine->setIndex(m_screen_lines.size()-1);
        }
    }
    if (!m_scroll_area_set)
        m_scroll_end = height - 1;
}

int ScreenData::scrollAreaStart() const
{
    return m_scroll_start;
}

int ScreenData::scrollAreaEnd() const
{
    return m_scroll_end;
}

Line *ScreenData::at(int index) const
{
    return m_screen_lines.at(index);
}

void ScreenData::clearToEndOfLine(int row, int from_char)
{
    m_screen_lines.at(row)->clearToEndOfLine(from_char);
}

void ScreenData::clearToEndOfScreen(int row)
{
    for(int i = row; i < m_screen_lines.size(); i++) {
        Line *line = m_screen_lines.at(i);
        line->clear();
    }
}

void ScreenData::clearToBeginningOfScreen(int row)
{
    for (int i = row; i >= 0; i--) {
        Line *line = m_screen_lines.at(i);
        line->clear();
    }
}

void ScreenData::clearLine(int index)
{
    m_screen_lines.at(index)->clear();
}

void ScreenData::clear()
{
    for (int i = 0; i < m_screen_lines.size(); i++) {
        Line *line = m_screen_lines.at(i);
        line->clear();
    }
}

void ScreenData::clearCharacters(int line, int from, int to)
{
    Line *line_item = m_screen_lines.at(line);
    line_item->clearCharacters(from,to);
}

void ScreenData::deleteCharacters(int line, int from, int to)
{
    Line *line_item = m_screen_lines.at(line);
    line_item->deleteCharacters(from,to);
}

void ScreenData::setScrollArea(int from, int to)
{
    m_scroll_area_set = true;
    m_scroll_start = from;
    m_scroll_end = to;
}

void ScreenData::moveLine(int from, int to)
{
    if (from == to)
        return;

    if (from < to) {
        int lines_to_shift = to - from;
        Line *from_line = m_screen_lines.at(from);
        Line **from_line_ptr = m_screen_lines.data() + from;
        memmove(from_line_ptr, from_line_ptr+1, sizeof(from_line_ptr) * lines_to_shift);
        from_line->clear();
        m_screen_lines.replace(to,from_line);
    } else {
        int lines_to_shift = from - to;
        Line *from_line = m_screen_lines.at(from);
        Line **to_line_ptr = const_cast<Line **>(m_screen_lines.constData() + to);
        memmove(to_line_ptr + 1, to_line_ptr, sizeof(to_line_ptr) * lines_to_shift);
        from_line->clear();
        m_screen_lines.replace(to,from_line);
    }
}

void ScreenData::updateIndexes(int from, int to)
{
    if (to < 0) {
        to = m_screen_lines.size() -1;
    }
    for (int i = from; i <= to; i++) {
        m_screen_lines.at(i)->setIndex(i);
    }
}

void ScreenData::sendSelectionToClipboard(const QPointF &start, const QPointF &end, QClipboard::Mode clipboard)
{
    QString data;
    int start_line = qMax((int)start.y(), 0);
    int end_line = qMin((int)end.y(), m_screen_lines.size()-1);
    for (int i = start_line; i <= end_line; i++) {
        int char_start = 0;
        int char_end = m_width - 1;
        if (i == start_line)
            char_start = start.x();
        else
            data.append(QChar('\n'));
        if (i == end_line)
            char_end = end.x();
        data += m_screen_lines.at(i)->textLine()->mid(char_start, char_end - char_start).trimmed();
    }

    QGuiApplication::clipboard()->setText(data, clipboard);
}

void ScreenData::getDoubleClickSelectionArea(const QPointF &cliked, int *start_ret, int *end_ret) const
{
    static const QChar delimiter_list[] = {
        ' ',
        '<',
        '>',
        ')',
        '(',
        '{',
        '}',
        '[',
        ']'
    };
    static const int size_of_delimiter_list = sizeof delimiter_list / sizeof *delimiter_list;

    *start_ret = -1;
    *end_ret = -1;
    bool find_equals = false;

    QStringRef to_return(m_screen_lines.at(cliked.y())->textLine());

    QChar clicked_char = to_return.at(cliked.x());

    for (int i=0; i<size_of_delimiter_list; i++) {
        if (clicked_char == delimiter_list[i])
            find_equals = true;
    }

    for (int i = cliked.x() - 1; i >= 0; i--) {
        if (find_equals) {
            if (clicked_char != to_return.at(i)) {
                *start_ret = i + 1;
                break;
            }
        } else {
            for (int delimiter_i = 0; delimiter_i < size_of_delimiter_list; delimiter_i++) {
                if (to_return.at(i) == delimiter_list[delimiter_i]) {
                    *start_ret = i + 1;
                    i = -1;
                    break;
                }
            }
        }
    }
    if (*start_ret < 0)
        *start_ret = 0;

    for (int i = cliked.x() + 1; i < to_return.size(); i++) {
        if (find_equals) {
            if (clicked_char != to_return.at(i)) {
                *end_ret = i;
                break;
            }
        } else {
            for (int delimiter_i = 0; delimiter_i < size_of_delimiter_list; delimiter_i++) {
                if (to_return.at(i) == delimiter_list[delimiter_i]) {
                    *end_ret = i;
                    i = to_return.size();
                    break;
                }
            }
        }
    }
    if (*end_ret < 0)
        *end_ret = to_return.size();

}

void ScreenData::dispatchLineEvents()
{
    for (int i = 0; i < m_new_lines.size(); i++) {
        emit m_screen->lineCreated(m_new_lines.at(i));
    }
    m_new_lines.clear();

    for (int i = 0; i < m_screen_lines.size(); i++) {
        m_screen_lines.at(i)->dispatchEvents();
    }
}

void ScreenData::printScreen() const
{
    for (int line = 0; line < m_screen_lines.size(); line++) {
//        for (int i = 0; i < m_screen_lines.at(line)->size(); i++) {
//            fprintf(stderr, "%s", qPrintable(m_screen_lines.at(line)->at(i)->text()));
//        }
//        fprintf(stderr, "\n");
        fprintf(stderr, "%s\n", qPrintable(*m_screen_lines.at(line)->textLine()));
    }
}

void ScreenData::printStyleInformation() const
{
    for (int line_number = 0; line_number < m_screen_lines.size(); line_number++) {
        const Line *line = m_screen_lines.at(line_number);
        line->printStyleList();
    }
}
