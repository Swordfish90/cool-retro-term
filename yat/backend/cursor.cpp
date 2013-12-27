/******************************************************************************
* Copyright (c) 2013 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
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

#include "cursor.h"

#include "block.h"
#include "screen_data.h"

#include <QTextCodec>

Cursor::Cursor(Screen* screen)
    : QObject(screen)
    , m_screen(screen)
    , m_current_text_style(screen->defaultTextStyle())
    , m_position(0,0)
    , m_new_position(0,0)
    , m_document_width(screen->width())
    , m_document_height(screen->height())
    , m_top_margin(0)
    , m_bottom_margin(0)
    , m_scroll_margins_set(false)
    , m_origin_at_margin(false)
    , m_notified(false)
    , m_visible(true)
    , m_new_visibillity(true)
    , m_blinking(false)
    , m_new_blinking(false)
    , m_wrap_around(true)
    , m_content_height_changed(false)
    , m_insert_mode(Replace)
{
    connect(screen, SIGNAL(widthAboutToChange(int)), this, SLOT(setDocumentWidth(int)));
    connect(screen, SIGNAL(heightAboutToChange(int, int, int)), this, SLOT(setDocumentHeight(int, int, int)));
    connect(screen, SIGNAL(contentHeightChanged()), this, SLOT(contentHeightChanged()));

    m_gl_text_codec = QTextCodec::codecForName("utf-8")->makeDecoder();
    m_gr_text_codec = QTextCodec::codecForName("utf-8")->makeDecoder();

    for (int i = 0; i < m_document_width; i++) {
        if (i % 8 == 0) {
            m_tab_stops.append(i);
        }
    }
}

Cursor::~Cursor()
{

}

void Cursor::setDocumentWidth(int width)
{
    if (width > m_document_width) {
        for (int i = m_document_width -1; i < width; i++) {
            if (i % 8 == 0) {
                m_tab_stops.append(i);
            }
        }
    }

    m_document_width = width;
    if (new_x() >= width) {
        new_rx() = width - 1;
        notifyChanged();
    }
}

void Cursor::setDocumentHeight(int height, int currentCursorBlock, int currentScrollBackHeight)
{
    Q_UNUSED(currentCursorBlock);
    resetScrollArea();
    if (m_document_height > height) {
        const int to_remove = m_document_height - height;
        const int removeLinesBelowCursor =
            std::min(m_document_height - new_y(), to_remove);
        const int removeLinesAtTop = to_remove - removeLinesBelowCursor;
        if (!removeLinesAtTop) {
            new_ry() -= removeLinesAtTop;
            notifyChanged();
        }
    } else {
        int height_diff = height - m_document_height;
        if (currentScrollBackHeight >= height_diff) {
            new_ry() += height_diff;
        } else if (currentScrollBackHeight > 0) {
            const int move = height_diff - currentScrollBackHeight;
            new_ry() += move;
        }
    }

    m_document_height = height;

    if (new_y() >= height) {
        new_ry() = height - 1;
        notifyChanged();
    }
    if (new_y() <= 0) {
        new_ry() = 0;
    }
}

bool Cursor::visible() const
{
    return m_visible;
}
void Cursor::setVisible(bool visible)
{
    m_new_visibillity = visible;
}

bool Cursor::blinking() const
{
    return m_blinking;
}

void Cursor::setBlinking(bool blinking)
{
    m_new_blinking = blinking;
}

void Cursor::setTextStyle(TextStyle::Style style, bool add)
{
    if (add) {
        m_current_text_style.style |= style;
    } else {
        m_current_text_style.style &= !style;
    }
}

void Cursor::resetStyle()
{
    m_current_text_style.background = ColorPalette::DefaultBackground;
    m_current_text_style.forground = ColorPalette::DefaultForground;
    m_current_text_style.style = TextStyle::Normal;
}

void Cursor::scrollUp(int lines)
{
    if (new_y() < top() || new_y() > bottom())
            return;
    for (int i = 0; i < lines; i++) {
        screen_data()->moveLine(bottom(), top());
    }
}

void Cursor::scrollDown(int lines)
{
    if (new_y() < top() || new_y() > bottom())
        return;
    for (int i = 0; i < lines; i++) {
        screen_data()->moveLine(top(), bottom());
    }
}

void Cursor::setTextCodec(QTextCodec *codec)
{
    m_gl_text_codec = codec->makeDecoder();
}

void Cursor::setInsertMode(InsertMode mode)
{
    m_insert_mode = mode;
}

TextStyle Cursor::currentTextStyle() const
{
    return m_current_text_style;
}

void Cursor::setTextStyleColor(ushort color)
{
    Q_ASSERT(color >= 30 && color < 50);
    if (color < 38) {
        m_current_text_style.forground = ColorPalette::Color(color - 30);
    } else if (color == 39) {
        m_current_text_style.forground = ColorPalette::DefaultForground;
    } else if (color >= 40 && color < 48) {
        m_current_text_style.background = ColorPalette::Color(color - 40);
    } else if (color == 49) {
        m_current_text_style.background = ColorPalette::DefaultBackground;
    } else {
        qDebug() << "Failed to set color";
    }
}

ColorPalette *Cursor::colorPalette() const
{
    return m_screen->colorPalette();
}

QPoint Cursor::position() const
{
    return m_position;
}

int Cursor::x() const
{
    return m_position.x();
}

int Cursor::y() const
{
    return (m_screen->currentScreenData()->contentHeight() - m_screen->height()) + m_position.y();
}

void Cursor::moveOrigin()
{
    m_new_position = QPoint(0,adjusted_top());
    notifyChanged();
}

void Cursor::moveBeginningOfLine()
{
    new_rx() = 0;
    notifyChanged();
}

void Cursor::moveUp(int lines)
{
    int adjusted_new_y = this->adjusted_new_y();
    if (!adjusted_new_y || !lines)
        return;

    if (lines < adjusted_new_y) {
        new_ry() -= lines;
    } else {
        new_ry() = adjusted_top();
    }
    notifyChanged();
}

void Cursor::moveDown(int lines)
{
    int bottom = adjusted_bottom();
    if (new_y() == bottom || !lines)
        return;

    if (new_y() + lines <= bottom) {
        new_ry() += lines;
    } else {
        new_ry() = bottom;
    }
    notifyChanged();
}

void Cursor::moveLeft(int positions)
{
    if (!new_x() || !positions)
        return;
    if (positions < new_x()) {
        new_rx() -= positions;
    } else {
        new_rx() = 0;
    }
    notifyChanged();
}

void Cursor::moveRight(int positions)
{
    int width = m_screen->width();
    if (new_x() == width -1 || !positions)
        return;
    if (positions < width - new_x()) {
        new_rx() += positions;
    } else {
        new_rx() = width -1;
    }

    notifyChanged();
}

void Cursor::move(int new_x, int new_y)
{
    int width = m_screen->width();

    if (m_origin_at_margin) {
        new_y += m_top_margin;
    }

    if (new_x < 0) {
        new_x = 0;
    } else if (new_x >= width) {
        new_x = width - 1;
    }

    if (new_y < adjusted_top()) {
        new_y = adjusted_top();
    } else if (new_y > adjusted_bottom()) {
        new_y = adjusted_bottom();
    }

    if (this->new_y() != new_y || this->new_x() != new_x) {
        m_new_position = QPoint(new_x, new_y);
        notifyChanged();
    }
}

void Cursor::moveToLine(int line)
{
    const int height = m_screen->height();
    if (line < adjusted_top()) {
        line = 0;
    } else if (line > adjusted_bottom()) {
        line = height -1;
    }

    if (line != new_y()) {
        new_rx() = line;
        notifyChanged();
    }
}

void Cursor::moveToCharacter(int character)
{
    const int width = m_screen->width();
    if (character < 0) {
        character = 1;
    } else if (character > width) {
        character = width;
    }
    if (character != new_x()) {
        new_rx() = character;
        notifyChanged();
    }
}

void Cursor::moveToNextTab()
{
    for (int i = 0; i < m_tab_stops.size(); i++) {
        if (new_x() < m_tab_stops.at(i)) {
            moveToCharacter(std::min(m_tab_stops.at(i), m_document_width -1));
            return;
        }
    }
    moveToCharacter(m_document_width - 1);
}

void Cursor::setTabStop()
{
    int i;
    for (i = 0; i < m_tab_stops.size(); i++) {
        if (new_x() == m_tab_stops.at(i))
            return;
        if (new_x() > m_tab_stops.at(i)) {
            continue;
        } else {
            break;
        }
    }
    m_tab_stops.insert(i,new_x());
}

void Cursor::removeTabStop()
{
    for (int i = 0; i < m_tab_stops.size(); i++) {
        if (new_x() == m_tab_stops.at(i)) {
            m_tab_stops.remove(i);
            return;
        } else if (new_x() < m_tab_stops.at(i)) {
            return;
        }
    }
}

void Cursor::clearTabStops()
{
    m_tab_stops.clear();
}

void Cursor::clearToBeginningOfLine()
{
    screen_data()->clearToBeginningOfLine(m_new_position);
}

void Cursor::clearToEndOfLine()
{
    screen_data()->clearToEndOfLine(m_new_position);
}

void Cursor::clearToBeginningOfScreen()
{
    clearToBeginningOfLine();
    if (new_y() > 0)
        screen_data()->clearToBeginningOfScreen(m_new_position.y()-1);
}

void Cursor::clearToEndOfScreen()
{
    clearToEndOfLine();
    if (new_y() < m_screen->height() -1) {
        screen_data()->clearToEndOfScreen(m_new_position.y()+1);
    }
}

void Cursor::clearLine()
{
    screen_data()->clearLine(m_new_position);
}

void Cursor::deleteCharacters(int characters)
{
    screen_data()->deleteCharacters(m_new_position, new_x() + characters -1);
}

void Cursor::setWrapAround(bool wrap)
{
    m_wrap_around = wrap;
}

void Cursor::addAtCursor(const QByteArray &data, bool only_latin)
{
    if (m_insert_mode == Replace) {
        replaceAtCursor(data, only_latin);
    } else {
        insertAtCursor(data, only_latin);
    }
}

void Cursor::replaceAtCursor(const QByteArray &data, bool only_latin)
{
    const QString text = m_gl_text_codec->toUnicode(data);

    if (!m_wrap_around && new_x() + text.size() > m_screen->width()) {
        const int size = m_document_width - new_x();
        QString toBlock = text.mid(0,size);
        toBlock.replace(toBlock.size() - 1, 1, text.at(text.size()-1));
        screen_data()->replace(m_new_position, toBlock, m_current_text_style, only_latin);
        new_rx() += toBlock.size();
    } else {
        auto diff = screen_data()->replace(m_new_position, text, m_current_text_style, only_latin);
        new_rx() += diff.character;
        new_ry() += diff.line;
    }

    if (new_y() >= m_document_height)
        new_ry() = m_document_height - 1;

    notifyChanged();
}

void Cursor::insertAtCursor(const QByteArray &data, bool only_latin)
{
    const QString text = m_gl_text_codec->toUnicode(data);
    auto diff = screen_data()->insert(m_new_position, text, m_current_text_style, only_latin);
    new_rx() += diff.character;
    new_ry() += diff.line;
    if (new_y() >= m_document_height)
        new_ry() = m_document_height - 1;
    if (new_x() >= m_document_width)
        new_rx() = m_document_width - 1;
}

void Cursor::lineFeed()
{
    if(new_y() >= bottom()) {
        screen_data()->insertLine(bottom(), top());
    } else {
        new_ry()++;
        notifyChanged();
    }
}

void Cursor::reverseLineFeed()
{
    if (new_y() == top()) {
        scrollUp(1);
    } else {
        new_ry()--;
        notifyChanged();
    }
}

void Cursor::setOriginAtMargin(bool atMargin)
{
    m_origin_at_margin = atMargin;
    m_new_position = QPoint(0, adjusted_top());
    notifyChanged();
}

void Cursor::setScrollArea(int from, int to)
{
    m_top_margin = from;
    m_bottom_margin = std::min(to,m_document_height -1);
    m_scroll_margins_set = true;
}

void Cursor::resetScrollArea()
{
    m_top_margin = 0;
    m_bottom_margin = 0;
    m_scroll_margins_set = false;
}

void Cursor::dispatchEvents()
{
    if (m_new_position != m_position|| m_content_height_changed) {
        bool emit_x_changed = m_new_position.x() != m_position.x();
        bool emit_y_changed = m_new_position.y() != m_position.y();
        m_position = m_new_position;
        if (emit_x_changed)
            emit xChanged();
        if (emit_y_changed || m_content_height_changed)
            emit yChanged();
    }

    if (m_new_visibillity != m_visible) {
        m_visible = m_new_visibillity;
        emit visibilityChanged();
    }

    if (m_new_blinking != m_blinking) {
        m_blinking = m_new_blinking;
        emit blinkingChanged();
    }
}

void Cursor::contentHeightChanged()
{
    m_content_height_changed = true;
}

