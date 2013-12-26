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

#ifndef YAT_PTY_H
#define YAT_PTY_H

#include <unistd.h>

#include <QtCore/QObject>
#include <QtCore/QLinkedList>
#include <QtCore/QMutex>

class YatPty : public QObject
{
    Q_OBJECT
public:
    YatPty();
    ~YatPty();

    void write(const QByteArray &data);

    void setWidth(int width, int pixelWidth = 0);
    void setHeight(int height, int pixelHeight = 0);
    QSize size() const;

    int masterDevice() const;

signals:
    void hangupReceived();
    void readyRead(const QByteArray &data);

private:
    void readData();

    pid_t m_terminal_pid;
    int m_master_fd;
    char m_slave_file_name[PATH_MAX];
    struct winsize *m_winsize;
    char m_data_buffer[1024];
};

#endif //YAT_PTY_H
