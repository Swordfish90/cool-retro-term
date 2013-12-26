/******************************************************************************
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

#ifndef MONO_TEXT_H
#define MONO_TEXT_H

#include <QtQuick/QQuickItem>
#include <QtGui/QRawFont>

class MonoText : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(qreal paintedWidth READ paintedWidth NOTIFY paintedWidthChanged)
    Q_PROPERTY(qreal paintedHeight READ paintedHeight NOTIFY paintedHeightChanged)
    Q_PROPERTY(bool latin READ latin WRITE setLatin NOTIFY latinChanged);
public:
    MonoText(QQuickItem *parent=0);
    ~MonoText();

    QString text() const;
    void setText(const QString &text);

    QFont font() const;
    void setFont(const QFont &font);

    QColor color() const;
    void setColor(const QColor &color);

    qreal paintedWidth() const;
    qreal paintedHeight() const;

    bool latin() const;
    void setLatin(bool latin);

signals:
    void textChanged();
    void fontChanged();
    void colorChanged();
    void paintedWidthChanged();
    void paintedHeightChanged();
    void latinChanged();
protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *data) Q_DECL_OVERRIDE;
    void updatePolish() Q_DECL_OVERRIDE;
private:
    Q_DISABLE_COPY(MonoText);
    void updateSize();

    QString m_text;
    QFont m_font;
    QColor m_color;
    bool m_color_changed;
    bool m_latin;
    bool m_old_latin;
    QSizeF m_text_size;
};

#endif
