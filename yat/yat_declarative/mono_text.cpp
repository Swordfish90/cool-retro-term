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

#include "mono_text.h"

#include <QtQuick/private/qsgadaptationlayer_p.h>
#include <QtQuick/private/qsgrenderer_p.h>
#include <QtQuick/private/qquickitem_p.h>
#include <QtQuick/private/qquicktextnode_p.h>
#include <QtGui/QTextLayout>

class MonoSGNode : public QSGTransformNode
{
public:
    MonoSGNode(QQuickItem *owner)
        : m_owner(owner)
    {
    }

    void deleteContent()
    {
        QSGNode *subnode = firstChild();
        while (subnode) {
            // We can't delete the node now as it might be in the preprocess list
            // It will be deleted in the next preprocess
            m_nodes_to_delete.append(subnode);
            subnode = subnode->nextSibling();
        }
        removeAllChildNodes();
    }

    void preprocess()
    {
        while (m_nodes_to_delete.count())
            delete m_nodes_to_delete.takeLast();
    }

    void setLatinText(const QString &text, const QFont &font, const QColor &color) {
        QRawFont raw_font = QRawFont::fromFont(font, QFontDatabase::Latin);

        if (raw_font != m_raw_font) {
            m_raw_font = raw_font;
            m_positions.clear();
        }

        if (m_positions.size() < text.size()) {
            qreal x_pos = 0;
            qreal max_char_width = raw_font.averageCharWidth();
            qreal ascent = raw_font.ascent();
            if (m_positions.size())
                x_pos = m_positions.last().x() + max_char_width;
            int to_add = text.size() - m_positions.size();
            for (int i = 0; i < to_add; i++) {
                m_positions << QPointF(x_pos, ascent);
                x_pos += max_char_width;
            }
        }

        deleteContent();
        QSGRenderContext *sgr = QQuickItemPrivate::get(m_owner)->sceneGraphRenderContext();
        QSGGlyphNode *node = sgr->sceneGraphContext()->createGlyphNode(sgr);
        node->setOwnerElement(m_owner);
        node->geometry()->setIndexDataPattern(QSGGeometry::StaticPattern);
        node->geometry()->setVertexDataPattern(QSGGeometry::StaticPattern);
        node->setStyle(QQuickText::Normal);

        node->setColor(color);
        QGlyphRun glyphrun;
        glyphrun.setRawFont(raw_font);
        glyphrun.setGlyphIndexes(raw_font.glyphIndexesForString(text));

        glyphrun.setPositions(m_positions);
        node->setGlyphs(QPointF(0, raw_font.ascent()), glyphrun);
        node->update();
        appendChildNode(node);
    }

    void setUnicodeText(const QString &text, const QFont &font, const QColor &color)
    {
        deleteContent();
        QRawFont raw_font = QRawFont::fromFont(font, QFontDatabase::Latin);
        qreal line_width = raw_font.averageCharWidth() * text.size();
        QSGRenderContext *sgr = QQuickItemPrivate::get(m_owner)->sceneGraphRenderContext();
        QTextLayout layout(text,font);
        layout.beginLayout();
        QTextLine line = layout.createLine();
        line.setLineWidth(line_width);
        //Q_ASSERT(!layout.createLine().isValid());
        layout.endLayout();
        QList<QGlyphRun> glyphRuns = line.glyphRuns();
        qreal xpos = 0;
        for (int i = 0; i < glyphRuns.size(); i++) {
            QSGGlyphNode *node = sgr->sceneGraphContext()->createGlyphNode(sgr);
            node->setOwnerElement(m_owner);
            node->geometry()->setIndexDataPattern(QSGGeometry::StaticPattern);
            node->geometry()->setVertexDataPattern(QSGGeometry::StaticPattern);
            node->setGlyphs(QPointF(xpos, raw_font.ascent()), glyphRuns.at(i));
            node->setStyle(QQuickText::Normal);
            node->setColor(color);
            xpos += raw_font.averageCharWidth() * glyphRuns.at(i).positions().size();
            node->update();
            appendChildNode(node);
        }
    }
private:
    QQuickItem *m_owner;
    QVector<QPointF> m_positions;
    QLinkedList<QSGNode *> m_nodes_to_delete;
    QRawFont m_raw_font;
};

MonoText::MonoText(QQuickItem *parent)
    : QQuickItem(parent)
    , m_color_changed(false)
    , m_latin(true)
    , m_old_latin(true)
{
    setFlag(ItemHasContents, true);
}

MonoText::~MonoText()
{

}

QString MonoText::text() const
{
    return m_text;
}

void MonoText::setText(const QString &text)
{
    if (m_text != text) {
        m_text = text;
        emit textChanged();
        polish();
    }
}

QFont MonoText::font() const
{
    return m_font;
}

void MonoText::setFont(const QFont &font)
{
    if (font != m_font) {
        m_font = font;
        emit fontChanged();
        polish();
    }
}

QColor MonoText::color() const
{
    return m_color;
}

void MonoText::setColor(const QColor &color)
{
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
        update();
    }
}

qreal MonoText::paintedWidth() const
{
    return implicitWidth();
}

qreal MonoText::paintedHeight() const
{
    return implicitHeight();
}

bool MonoText::latin() const
{
    return m_latin;
}

void MonoText::setLatin(bool latin)
{
    if (latin == m_latin)
        return;

    m_latin = latin;
    emit latinChanged();
}

QSGNode *MonoText::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    if (m_text.size() == 0 || m_text.trimmed().size() == 0) {
        delete old;
        return 0;
    }
    MonoSGNode *node = static_cast<MonoSGNode *>(old);
    if (!node) {
        node = new MonoSGNode(this);
    }

    if (m_latin) {
        node->setLatinText(m_text, m_font, m_color);
    } else {
        node->setUnicodeText(m_text, m_font, m_color);
    }

    return node;
}

void MonoText::updatePolish()
{
        QRawFont raw_font = QRawFont::fromFont(m_font, QFontDatabase::Latin);

        qreal height = raw_font.descent() + raw_font.ascent() + raw_font.lineThickness();
        qreal width = raw_font.averageCharWidth() * m_text.size();

        bool emit_text_width_changed = width != implicitWidth();
        bool emit_text_height_changed = height != implicitHeight();
        setImplicitSize(width, height);

        if (emit_text_width_changed)
            emit paintedWidthChanged();
        if (emit_text_height_changed)
            emit paintedHeightChanged();

        update();
}
