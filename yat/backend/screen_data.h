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

#ifndef SCREENDATA_H
#define SCREENDATA_H

#include <QtCore/QVector>
#include <QtCore/QPoint>
#include <QtGui/QClipboard>

class Line;
class Screen;

class ScreenData
{
public:
    ScreenData(Screen *screen);
    ~ScreenData();

    int width() const;
    void setWidth(int width);
    int height() const;
    void setHeight(int height);

    int scrollAreaStart() const;
    int scrollAreaEnd() const;

    Line *at(int index) const;

    void clearToEndOfLine(int row, int from_char);
    void clearToEndOfScreen(int row);
    void clearToBeginningOfScreen(int row);
    void clearLine(int index);
    void clear();

    void clearCharacters(int line, int from, int to);
    void deleteCharacters(int line, int from, int to);

    void setScrollArea(int from, int to);

    void moveLine(int from, int to);

    void updateIndexes(int from = 0, int to = -1);

    void sendSelectionToClipboard(const QPointF &start, const QPointF &end, QClipboard::Mode clipboard);

    void getDoubleClickSelectionArea(const QPointF &cliked, int *start_ret, int *end_ret) const;

    void dispatchLineEvents();

    void printScreen() const;

    void printStyleInformation() const;
private:
    Screen *m_screen;
    int m_width;
    QVector<Line *> m_screen_lines;
    QVector<Line *> m_new_lines;
    int m_scroll_start;
    int m_scroll_end;
    bool m_scroll_area_set;
};

#endif // SCREENDATA_H
