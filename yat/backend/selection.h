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

#ifndef SELECTION_H
#define SELECTION_H

#include <QtCore/QObject>
#include <QtCore/QPoint>

class Screen;

class Selection : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int startX READ startX WRITE setStartX NOTIFY startXChanged)
    Q_PROPERTY(int startY READ startY WRITE setStartY NOTIFY startYChanged)
    Q_PROPERTY(int endX READ endX WRITE setEndX NOTIFY endXChanged)
    Q_PROPERTY(int endY READ endY WRITE setEndY NOTIFY endYChanged)
    Q_PROPERTY(bool enable READ enable WRITE setEnable NOTIFY enableChanged)

public:
    explicit Selection(Screen *screen);

    void setStartX(int x);
    int startX() const;

    void setStartY(int y);
    int startY() const;

    void setEndX(int x);
    int endX() const;

    void setEndY(int y);
    int endY() const;

    void setEnable(bool enabled);
    bool enable() const;

    Q_INVOKABLE void sendToClipboard() const;
    Q_INVOKABLE void sendToSelection() const;
    Q_INVOKABLE void pasteFromSelection();
    Q_INVOKABLE void pasteFromClipboard();

    void dispatchChanges();
signals:
    void startXChanged();
    void startYChanged();
    void endXChanged();
    void endYChanged();
    void enableChanged();

private slots:
    void screenContentModified(size_t lineModified, int lineDiff, int contentDiff);

private:
    void setValidity();
    QPoint start_new_point() const { return QPoint(m_new_start_x, m_new_start_y); }
    QPoint end_new_point() const { return QPoint(m_new_end_x, m_new_end_y); }

    Screen *m_screen;
    int m_new_start_x;
    int m_start_x;
    int m_new_start_y;
    int m_start_y;
    int m_new_end_x;
    int m_end_x;
    int m_new_end_y;
    int m_end_y;
    bool m_new_enable;
    bool m_enable;
};
#endif
