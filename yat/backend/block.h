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

#ifndef BLOCK_H
#define BLOCK_H

#include <QtCore/QObject>

#include "text_style.h"

class Text;
class Screen;

class Block
{
public:
    Block(Screen *screen);
    ~Block();

    Q_INVOKABLE Screen *screen() const;

    void clear();
    void clearToEnd(int from);
    void clearCharacters(int from, int to);
    void deleteCharacters(int from, int to);
    void deleteToEnd(int from);
    void deleteLines(int from);

    void replaceAtPos(int i, const QString &text, const TextStyle &style, bool only_latin = true);
    void insertAtPos(int i, const QString &text, const TextStyle &style, bool only_latin = true);

    void setScreenIndex(int index) { m_screen_index = index; }
    int screenIndex() const { return m_screen_index; }
    size_t line() { return m_new_line; }
    void setLine(size_t line) {
        if (line != m_new_line) {
            m_changed = true;
            m_new_line = line;
        }
    }

    QString *textLine();
    int textSize() { return m_text_line.size(); }

    int width() const { return m_width; }
    void setWidth(int width) { m_changed = true; m_width = width; }
    int lineCount() const { return (std::max((m_text_line.size() - 1),0) / m_width) + 1; }
    int lineCountAfterModified(int from_char, int text_size, bool replace) {
        int new_size = replace ? std::max(from_char + text_size, m_text_line.size())
            : std::max(from_char, m_text_line.size()) + text_size;
        return ((new_size - 1) / m_width) + 1;
    }

    void setVisible(bool visible);
    bool visible() const;

    Block *split(int line);
    Block *takeLine(int line);
    void removeLine(int line);

    void moveLinesFromBlock(Block *block, int start_line, int count);

    void dispatchEvents();
    void releaseTextObjects();

    QVector<TextStyleLine> style_list();

    void printStyleList() const;
    void printStyleList(QDebug &debug) const;
    void printStyleListWidthText() const;

private:
    void mergeCompatibleStyles();
    void ensureStyleAlignWithLines(int i);
    Screen *m_screen;
    QString m_text_line;
    QVector<TextStyleLine> m_style_list;
    size_t m_line;
    size_t m_new_line;
    int m_screen_index;

    int m_width;

    bool m_visible;
    bool m_changed;
    bool m_only_latin;
};

#endif // BLOCK_H
