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

#include "terminal_screen.h"

TerminalScreen::TerminalScreen(QQuickItem *parent)
    : QQuickItem(parent)
    , m_screen(new Screen(this))
{
    setFlag(QQuickItem::ItemAcceptsInputMethod);
}

Screen *TerminalScreen::screen() const
{
    return m_screen;
}

QVariant TerminalScreen::inputMethodQuery(Qt::InputMethodQuery query) const
{
    switch (query) {
    case Qt::ImEnabled:
        return QVariant(true);
    case Qt::ImHints:
        return QVariant(Qt::ImhNoAutoUppercase | Qt::ImhNoPredictiveText);
    default:
        return QVariant();
    }
}

void TerminalScreen::inputMethodEvent(QInputMethodEvent *event)
{
    QString commitString = event->commitString();
    if (commitString.isEmpty()) {
        return;
    }

    Qt::Key key = Qt::Key_unknown;
    if (commitString == " ") {
        key = Qt::Key_Space; // screen requires
    }

    m_screen->sendKey(commitString, key, 0);
}

void TerminalScreen::keyPressEvent(QKeyEvent *event)
{
    m_screen->sendKey(event->text(), Qt::Key(event->key()), event->modifiers());
}
