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

#include "screen.h"

#include "screen_data.h"
#include "block.h"
#include "cursor.h"
#include "text.h"
#include "scrollback.h"
#include "selection.h"

#include "controll_chars.h"
#include "character_sets.h"

#include <QtCore/QTimer>
#include <QtCore/QSocketNotifier>
#include <QtGui/QGuiApplication>

#include <QtCore/QDebug>

#include <float.h>

Screen::Screen(QObject *parent)
    : QObject(parent)
    , m_palette(new ColorPalette(this))
    , m_parser(this)
    , m_timer_event_id(0)
    , m_width(1)
    , m_height(0)
    , m_primary_data(new ScreenData(500, this))
    , m_alternate_data(new ScreenData(0, this))
    , m_current_data(m_primary_data)
    , m_old_current_data(m_primary_data)
    , m_selection(new Selection(this))
    , m_flash(false)
    , m_cursor_changed(false)
    , m_application_cursor_key_mode(false)
    , m_fast_scroll(true)
    , m_default_background(m_palette->normalColor(ColorPalette::DefaultBackground))
{
    Cursor *cursor = new Cursor(this);
    m_cursor_stack << cursor;
    m_new_cursors << cursor;

    connect(m_primary_data, SIGNAL(contentHeightChanged()), this, SIGNAL(contentHeightChanged()));
    connect(m_primary_data, &ScreenData::contentModified,
            this, &Screen::contentModified);
    connect(m_palette, SIGNAL(changed()), this, SLOT(paletteChanged()));

    setHeight(25);
    setWidth(80);

    connect(&m_pty, &YatPty::readyRead, this, &Screen::readData);
    connect(&m_pty, SIGNAL(hangupReceived()),qGuiApp, SLOT(quit()));

}

Screen::~Screen()
{

    for(int i = 0; i < m_to_delete.size(); i++) {
        delete m_to_delete.at(i);
    }
    //m_to_delete.clear();

    delete m_primary_data;
    delete m_alternate_data;
}


QColor Screen::defaultForgroundColor() const
{
    return m_palette->normalColor(ColorPalette::DefaultForground);
}

QColor Screen::defaultBackgroundColor() const
{
    return m_palette->normalColor(ColorPalette::DefaultBackground);
}

void Screen::emitRequestHeight(int newHeight)
{
    emit requestHeightChange(newHeight);
}

void Screen::setHeight(int height)
{
    if (height == m_height)
        return;

    emit heightAboutToChange(height, currentCursor()->new_y(), currentScreenData()->scrollback()->height());

    m_height = height;

    m_pty.setHeight(height, height * 10);

    emit heightChanged();
}

int Screen::height() const
{
    return m_height;
}

int Screen::contentHeight() const
{
    return currentScreenData()->contentHeight();
}

void Screen::emitRequestWidth(int newWidth)
{
    emit requestWidthChange(newWidth);
}

void Screen::setWidth(int width)
{
    if (width == m_width)
        return;

    emit widthAboutToChange(width);

    m_width = width;

    m_pty.setWidth(width, width * 10);

    emit widthChanged();
}

int Screen::width() const
{
    return m_width;
}

void Screen::useAlternateScreenBuffer()
{
    if (m_current_data == m_primary_data) {
        disconnect(m_primary_data, SIGNAL(contentHeightChanged()), this, SIGNAL(contentHeightChanged()));
        disconnect(m_primary_data, &ScreenData::contentModified, this, &Screen::contentModified);
        m_current_data = m_alternate_data;
        m_current_data->clear();
        connect(m_alternate_data, SIGNAL(contentHeightChanged()), this, SIGNAL(contentHeightChanged()));
        connect(m_primary_data, &ScreenData::contentModified, this, &Screen::contentModified);
        emit contentHeightChanged();
    }
}

void Screen::useNormalScreenBuffer()
{
    if (m_current_data == m_alternate_data) {
        disconnect(m_alternate_data, SIGNAL(contentHeightChanged()), this, SIGNAL(contentHeightChanged()));
        disconnect(m_alternate_data, &ScreenData::contentModified, this, &Screen::contentModified);
        m_current_data = m_primary_data;
        connect(m_primary_data, SIGNAL(contentHeightChanged()), this, SIGNAL(contentHeightChanged()));
        connect(m_alternate_data, &ScreenData::contentModified, this, &Screen::contentModified);
        emit contentHeightChanged();
    }
}

TextStyle Screen::defaultTextStyle() const
{
    TextStyle style;
    style.style = TextStyle::Normal;
    style.forground = ColorPalette::DefaultForground;
    style.background = ColorPalette::DefaultBackground;
    return style;
}

void Screen::saveCursor()
{
    Cursor *new_cursor = new Cursor(this);
    if (m_cursor_stack.size())
        m_cursor_stack.last()->setVisible(false);
    m_cursor_stack << new_cursor;
    m_new_cursors << new_cursor;
}

void Screen::restoreCursor()
{
    if (m_cursor_stack.size() <= 1)
        return;

    m_delete_cursors.append(m_cursor_stack.takeLast());
    m_cursor_stack.last()->setVisible(true);
}

void Screen::clearScreen()
{
    currentScreenData()->clear();
}


ColorPalette *Screen::colorPalette() const
{
    return m_palette;
}

void Screen::fill(const QChar character)
{
    currentScreenData()->fill(character);
}

void Screen::clear()
{
    fill(QChar(' '));
}

void Screen::setFastScroll(bool fast)
{
    m_fast_scroll = fast;
}

bool Screen::fastScroll() const
{
    return m_fast_scroll;
}

Selection *Screen::selection() const
{
    return m_selection;
}

void Screen::doubleClicked(const QPointF &clicked)
{
    Q_UNUSED(clicked);
    //int start, end;
    //currentScreenData()->getDoubleClickSelectionArea(clicked, &start, &end);
    //setSelectionAreaStart(QPointF(start,clicked.y()));
    //setSelectionAreaEnd(QPointF(end,clicked.y()));
}

void Screen::setTitle(const QString &title)
{
    m_title = title;
    emit screenTitleChanged();
}

QString Screen::title() const
{
    return m_title;
}

void Screen::scheduleFlash()
{
    m_flash = true;
}

void Screen::printScreen() const
{
    currentScreenData()->printStyleInformation();
    qDebug() << "Total height: " << currentScreenData()->contentHeight();
}

void Screen::scheduleEventDispatch()
{
    if (!m_timer_event_id) {
        m_timer_event_id = startTimer(1);
        m_time_since_initiated.restart();
    }

    m_time_since_parsed.restart();
}

void Screen::dispatchChanges()
{
    if (m_old_current_data != m_current_data) {
        m_old_current_data->releaseTextObjects();
        m_old_current_data = m_current_data;
    }

    currentScreenData()->dispatchLineEvents();
    emit dispatchTextSegmentChanges();

    static int max_to_delete_size = 0;
    if (max_to_delete_size < m_to_delete.size()) {
        max_to_delete_size = m_to_delete.size();
        qDebug() << "TO DELETE SIZE :" << max_to_delete_size;
    }

    if (m_flash) {
        m_flash = false;
        emit flash();
    }

    for (int i = 0; i < m_delete_cursors.size(); i++) {
        int new_index = m_new_cursors.indexOf(m_delete_cursors.at(i));
        if (new_index >= 0)
            m_new_cursors.remove(new_index);
        delete m_delete_cursors.at(i);
    }
    m_delete_cursors.clear();

    for (int i = 0; i < m_new_cursors.size(); i++) {
        emit cursorCreated(m_new_cursors.at(i));
    }
    m_new_cursors.clear();

    for (int i = 0; i < m_cursor_stack.size(); i++) {
        m_cursor_stack[i]->dispatchEvents();
    }

    m_selection->dispatchChanges();
}

void Screen::sendPrimaryDA()
{
    m_pty.write(QByteArrayLiteral("\033[?6c"));

}

void Screen::sendSecondaryDA()
{
    m_pty.write(QByteArrayLiteral("\033[>1;95;0c"));
}

void Screen::setApplicationCursorKeysMode(bool enable)
{
    m_application_cursor_key_mode = enable;
}

bool Screen::applicationCursorKeyMode() const
{
    return m_application_cursor_key_mode;
}

void Screen::ensureVisiblePages(int top_line)
{
    currentScreenData()->ensureVisiblePages(top_line);
}

static bool hasControll(Qt::KeyboardModifiers modifiers)
{
#ifdef Q_OS_MAC
    return modifiers & Qt::MetaModifier;
#else
    return modifiers & Qt::ControlModifier;
#endif
}

static bool hasMeta(Qt::KeyboardModifiers modifiers)
{
#ifdef Q_OS_MAC
    return modifiers & Qt::ControlModifier;
#else
    return modifiers & Qt::MetaModifier;
#endif
}

void Screen::sendKey(const QString &text, Qt::Key key, Qt::KeyboardModifiers modifiers)
{

//    if (key == Qt::Key_Control)
//        printScreen();
    /// UGH, this function should be re-written
    char escape = '\0';
    char  control = '\0';
    char  code = '\0';
    QVector<ushort> parameters;
    bool found = true;

    switch(key) {
    case Qt::Key_Up:
        escape = C0::ESC;
        if (m_application_cursor_key_mode)
            control = C1_7bit::SS3;
        else
            control = C1_7bit::CSI;

        code = 'A';
        break;
    case Qt::Key_Right:
        escape = C0::ESC;
        if (m_application_cursor_key_mode)
            control = C1_7bit::SS3;
        else
            control = C1_7bit::CSI;

        code = 'C';
        break;
    case Qt::Key_Down:
        escape = C0::ESC;
        if (m_application_cursor_key_mode)
            control = C1_7bit::SS3;
        else
            control = C1_7bit::CSI;

            code = 'B';
        break;
    case Qt::Key_Left:
        escape = C0::ESC;
        if (m_application_cursor_key_mode)
            control = C1_7bit::SS3;
        else
            control = C1_7bit::CSI;

        code = 'D';
        break;
    case Qt::Key_Insert:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(2);
        code = '~';
        break;
    case Qt::Key_Delete:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(3);
        code = '~';
        break;
    case Qt::Key_Home:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(1);
        code = '~';
        break;
    case Qt::Key_End:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(4);
        code = '~';
        break;
    case Qt::Key_PageUp:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(5);
        code = '~';
        break;
    case Qt::Key_PageDown:
        escape = C0::ESC;
        control = C1_7bit::CSI;
        parameters.append(6);
        code = '~';
        break;
    case Qt::Key_F1:
    case Qt::Key_F2:
    case Qt::Key_F3:
    case Qt::Key_F4:
        if (m_application_cursor_key_mode) {
            parameters.append((key & 0xff) - 37);
            escape = C0::ESC;
            control = C1_7bit::CSI;
            code = '~';
        }
        break;
    case Qt::Key_F5:
    case Qt::Key_F6:
    case Qt::Key_F7:
    case Qt::Key_F8:
    case Qt::Key_F9:
    case Qt::Key_F10:
    case Qt::Key_F11:
    case Qt::Key_F12:
        if (m_application_cursor_key_mode) {
            parameters.append((key & 0xff) - 36);
            escape = C0::ESC;
            control = C1_7bit::CSI;
            code = '~';
        }
        break;
    case Qt::Key_Control:
    case Qt::Key_Shift:
    case Qt::Key_Alt:
    case Qt::Key_AltGr:
        return;
        break;
    default:
        found = false;
    }

    if (found) {
        int term_mods = 0;
        if (modifiers & Qt::ShiftModifier)
            term_mods |= 1;
        if (modifiers & Qt::AltModifier)
            term_mods |= 2;
        if (modifiers & Qt::ControlModifier)
            term_mods |= 4;

        QByteArray toPty;

        if (term_mods) {
            term_mods++;
            parameters.append(term_mods);
        }
        if (escape)
            toPty.append(escape);
        if (control)
            toPty.append(control);
        if (parameters.size()) {
            for (int i = 0; i < parameters.size(); i++) {
                if (i)
                    toPty.append(';');
                toPty.append(QByteArray::number(parameters.at(i)));
            }
        }
        if (code)
            toPty.append(code);
        m_pty.write(toPty);

    } else {
        QString verifiedText = text.simplified();
        if (verifiedText.isEmpty()) {
            switch (key) {
            case Qt::Key_Return:
            case Qt::Key_Enter:
                verifiedText = "\r";
                break;
            case Qt::Key_Backspace:
                verifiedText = "\010";
                break;
            case Qt::Key_Tab:
                verifiedText = "\t";
                break;
            case Qt::Key_Control:
            case Qt::Key_Meta:
            case Qt::Key_Alt:
            case Qt::Key_Shift:
                return;
            case Qt::Key_Space:
                verifiedText = " ";
                break;
            default:
                return;
            }
        }
        QByteArray to_pty;
        QByteArray key_text;
        if (hasControll(modifiers)) {
            char key_char = verifiedText.toLocal8Bit().at(0);
            key_text.append(key_char & 0x1F);
        } else {
            key_text = verifiedText.toUtf8();
        }

        if (modifiers &  Qt::AltModifier) {
            to_pty.append(C0::ESC);
        }

        if (hasMeta(modifiers)) {
            to_pty.append(C0::ESC);
            to_pty.append('@');
            to_pty.append(FinalBytesNoIntermediate::Reserved3);
        }

        to_pty.append(key_text);
        m_pty.write(to_pty);
    }
}

YatPty *Screen::pty()
{
    return &m_pty;
}

Text *Screen::createTextSegment(const TextStyleLine &style_line)
{
    Q_UNUSED(style_line);
    Text *to_return;
    if (m_to_delete.size()) {
        to_return = m_to_delete.takeLast();
        to_return->setVisible(true);
    } else {
        to_return = new Text(this);
        emit textCreated(to_return);
    }

    return to_return;
}

void Screen::releaseTextSegment(Text *text)
{
    m_to_delete.append(text);
}

void Screen::readData(const QByteArray &data)
{
    m_parser.addData(data);

    scheduleEventDispatch();
}

void Screen::paletteChanged()
{
    QColor new_default = m_palette->normalColor(ColorPalette::DefaultBackground);
    if (new_default != m_default_background) {
        m_default_background = new_default;
        emit defaultBackgroundColorChanged();
    }
}



void Screen::timerEvent(QTimerEvent *)
{
    if (m_timer_event_id && (m_time_since_parsed.elapsed() > 3 || m_time_since_initiated.elapsed() > 8)) {
        killTimer(m_timer_event_id);
        m_timer_event_id = 0;
        dispatchChanges();
    }
}
