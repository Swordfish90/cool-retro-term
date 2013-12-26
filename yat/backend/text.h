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

#ifndef TEXT_SEGMENT_H
#define TEXT_SEGMENT_H

#include <QtCore/QString>
#include <QtGui/QColor>
#include <QtCore/QObject>
#include <QtCore/QSize>

#include "text_style.h"

class Screen;
class QQuickItem;

class Text : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int index READ index NOTIFY indexChanged)
    Q_PROPERTY(int line READ line NOTIFY lineChanged)
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged)
    Q_PROPERTY(QString text READ text NOTIFY textChanged)
    Q_PROPERTY(QColor foregroundColor READ foregroundColor NOTIFY forgroundColorChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor NOTIFY backgroundColorChanged)
    Q_PROPERTY(bool bold READ bold NOTIFY boldChanged)
    Q_PROPERTY(bool blinking READ blinking NOTIFY blinkingChanged)
    Q_PROPERTY(bool underline READ underline NOTIFY underlineChanged)
    Q_PROPERTY(bool latin READ latin NOTIFY latinChanged)
public:
    Text(Screen *screen);
    ~Text();

    int index() const;

    int line() const;
    void setLine(int line, int width, const QString *textLine);

    bool visible() const;
    void setVisible(bool visible);

    QString text() const;
    QColor foregroundColor() const;
    QColor backgroundColor() const;

    void setStringSegment(int start_index, int end_index, bool textChanged);
    void setTextStyle(const TextStyle &style);

    bool bold() const;
    bool blinking() const;
    bool underline() const;

    void setLatin(bool latin);
    bool latin() const;

    QObject *item() const;

public slots:
    void dispatchEvents();

signals:
    void indexChanged();
    void lineChanged();
    void visibleChanged();
    void textChanged();
    void forgroundColorChanged();
    void backgroundColorChanged();
    void boldChanged();
    void blinkingChanged();
    void underlineChanged();
    void latinChanged();

private slots:
    void paletteChanged();

private:
    void setBackgroundColor();
    void setForgroundColor();

    Screen *m_screen;
    QString m_text;
    const QString *m_text_line;
    int m_start_index;
    int m_old_start_index;
    int m_end_index;
    int m_line;
    int m_old_line;
    int m_width;

    TextStyle m_style;
    TextStyle m_new_style;

    bool m_style_dirty;
    bool m_text_dirty;
    bool m_visible;
    bool m_visible_old;
    bool m_latin;
    bool m_latin_old;

    QColor m_forgroundColor;
    QColor m_backgroundColor;
};

#endif // TEXT_SEGMENT_H
