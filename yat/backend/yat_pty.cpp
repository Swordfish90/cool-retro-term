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

#include "yat_pty.h"

#include <fcntl.h>
#include <poll.h>

#ifdef LINUX
#include <sys/epoll.h>
#endif

#include <sys/ioctl.h>
#ifdef Q_OS_MAC
#include <util.h>
#else
#include <pty.h>
#endif
#include <utmp.h>

#include <QtCore/QSize>
#include <QtCore/QString>
#include <QtCore/QThread>
#include <QtCore/QSocketNotifier>
#include <QtCore/QDebug>

static char env_variables[][255] = {
    "TERM=xterm",
    "COLORTERM=xterm",
    "COLORFGBG=15;0",
    "LINES",
    "COLUMNS",
    "TERMCAP"
};
static int env_variables_size = sizeof(env_variables) / sizeof(env_variables[0]);

YatPty::YatPty()
    : m_winsize(0)
{
    m_terminal_pid = forkpty(&m_master_fd,
                             NULL,
                             NULL,
                             NULL);

    if (m_terminal_pid == 0) {
        for (int i = 0; i < env_variables_size; i++) {
            ::putenv(env_variables[i]);
        }
        ::execl("/bin/bash", "/bin/bash", "--login", (const char *) 0);
        exit(0);
    }

    QSocketNotifier *reader = new QSocketNotifier(m_master_fd,QSocketNotifier::Read,this);
    connect(reader, &QSocketNotifier::activated, this, &YatPty::readData);
}

YatPty::~YatPty()
{
}

void YatPty::write(const QByteArray &data)
{
    if (::write(m_master_fd, data.constData(), data.size()) < 0) {
        qDebug() << "Something whent wrong when writing to m_master_fd";
    }
}

void YatPty::setWidth(int width, int pixelWidth)
{
    if (!m_winsize) {
        m_winsize = new struct winsize;
        m_winsize->ws_row = 25;
        m_winsize->ws_ypixel = 0;
    }

    m_winsize->ws_col = width;
    m_winsize->ws_xpixel = pixelWidth;
    ioctl(m_master_fd, TIOCSWINSZ, m_winsize);
}

void YatPty::setHeight(int height, int pixelHeight)
{
    if (!m_winsize) {
        m_winsize = new struct winsize;
        m_winsize->ws_col = 80;
        m_winsize->ws_xpixel = 0;
    }
    m_winsize->ws_row = height;
    m_winsize->ws_ypixel = pixelHeight;
    ioctl(m_master_fd, TIOCSWINSZ, m_winsize);

}

QSize YatPty::size() const
{
    if (!m_winsize) {
        YatPty *that = const_cast<YatPty *>(this);
        that->m_winsize = new struct winsize;
        ioctl(m_master_fd, TIOCGWINSZ, m_winsize);
    }
    return QSize(m_winsize->ws_col, m_winsize->ws_row);
}

int YatPty::masterDevice() const
{
    return m_master_fd;
}


void YatPty::readData()
{
    int size_of_buffer = sizeof m_data_buffer / sizeof *m_data_buffer;
    ssize_t read_size = ::read(m_master_fd,m_data_buffer,size_of_buffer);
    if (read_size > 0) {
        QByteArray to_return = QByteArray::fromRawData(m_data_buffer,read_size);
        emit readyRead(to_return);
    } else if (read_size < 0) {
        emit hangupReceived();
    } else {
        emit hangupReceived();
    }
}
