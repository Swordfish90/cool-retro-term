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

#include "selection.h"

#include "screen.h"
#include "screen_data.h"

#include <QtGui/QGuiApplication>

Selection::Selection(Screen *screen)
    : QObject(screen)
    , m_screen(screen)
    , m_new_start_x(0)
    , m_start_x(0)
    , m_new_start_y(0)
    , m_start_y(0)
    , m_new_end_x(0)
    , m_end_x(0)
    , m_new_end_y(0)
    , m_end_y(0)
    , m_new_enable(false)
{
    connect(screen, &Screen::contentModified, this, &Selection::screenContentModified);

}

void Selection::setStartX(int x)
{
    if (x != m_new_start_x) {
        m_new_start_x = x;
        setValidity();
        m_screen->scheduleEventDispatch();
    }
}

int Selection::startX() const
{
    return m_start_x;
}

void Selection::setStartY(int y)
{
    if (y != m_new_start_y) {
        m_new_start_y = y;
        setValidity();
        m_screen->scheduleEventDispatch();
    }
}

int Selection::startY() const
{
    return m_start_y;
}

void Selection::setEndX(int x)
{
    if (m_new_end_x != x) {
        m_new_end_x = x;
        setValidity();
        m_screen->scheduleEventDispatch();
    }
}

int Selection::endX() const
{
    return m_end_x;
}

void Selection::setEndY(int y)
{
    if (m_new_end_y != y) {
        m_new_end_y = y;
        setValidity();
        m_screen->scheduleEventDispatch();
    }
}

int Selection::endY() const
{
    return m_end_y;
}

void Selection::setEnable(bool enable)
{
    if (m_new_enable != enable) {
        m_new_enable = enable;
        m_screen->scheduleEventDispatch();
    }
}

void Selection::screenContentModified(size_t lineModified, int lineDiff, int contentDiff)
{
    if (!m_new_enable)
        return;

    if (lineModified >= size_t(m_new_start_y) && lineModified <= size_t(m_new_end_y)) {
        setEnable(false);
        return;
    }

    if (size_t(m_new_end_y) < lineModified && lineModified != contentDiff) {
        m_new_end_y -= lineDiff - contentDiff;
        m_new_start_y -= lineDiff - contentDiff;
        if (m_new_end_y < 0) {
            setEnable(false);
            return;
        }
        if (m_new_start_y < 0) {
            m_new_start_y = 0;
        }
        m_screen->scheduleEventDispatch();
    }
}

void Selection::setValidity()
{
    if (m_new_end_y > m_new_start_y ||
            (m_new_end_y == m_new_start_y &&
             m_new_end_x > m_new_start_x)) {
        setEnable(true);
    } else {
        setEnable(false);
    }
}

void Selection::sendToClipboard() const
{
    m_screen->currentScreenData()->sendSelectionToClipboard(start_new_point(), end_new_point(), QClipboard::Clipboard);
}

void Selection::sendToSelection() const
{
    m_screen->currentScreenData()->sendSelectionToClipboard(start_new_point(), end_new_point(), QClipboard::Selection);
}

void Selection::pasteFromSelection()
{
    m_screen->pty()->write(QGuiApplication::clipboard()->text(QClipboard::Selection).toUtf8());
}

void Selection::pasteFromClipboard()
{
    m_screen->pty()->write(QGuiApplication::clipboard()->text(QClipboard::Clipboard).toUtf8());
}

void Selection::dispatchChanges()
{
    if (!m_new_enable && !m_enable)
        return;

    if (m_new_start_y != m_start_y) {
        m_start_y = m_new_start_y;
        emit startYChanged();
    }
    if (m_new_start_x != m_start_x) {
        m_start_x = m_new_start_x;
        emit startXChanged();
    }
    if (m_new_end_y != m_end_y) {
        m_end_y = m_new_end_y;
        emit endYChanged();
    }
    if (m_new_end_x != m_end_x) {
        m_end_x = m_new_end_x;
        emit endXChanged();
    }
    if (m_new_enable != m_enable) {
        m_enable = m_new_enable;
        emit enableChanged();
    }
}

bool Selection::enable() const
{
    return m_enable;
}
