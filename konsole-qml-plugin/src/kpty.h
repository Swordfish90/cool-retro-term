/* This file is part of the KDE libraries

    Copyright (C) 2003,2007 Oswald Buddenhagen <ossi@kde.org>

    Rewritten for QT4 by e_k <e_k at users.sourceforge.net>, Copyright (C)2008

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef kpty_h
#define kpty_h

#include <QtCore>

struct KPtyPrivate;
struct termios;

/**
 * Provides primitives for opening & closing a pseudo TTY pair, assigning the
 * controlling TTY, utmp registration and setting various terminal attributes.
 */
class KPty {
    Q_DECLARE_PRIVATE(KPty)

public:

    /**
     * Constructor
     */
    KPty();

    /**
     * Destructor:
     *
     *  If the pty is still open, it will be closed. Note, however, that
     *  an utmp registration is @em not undone.
    */
    ~KPty();

    /**
     * Create a pty master/slave pair.
     *
     * @return true if a pty pair was successfully opened
     */
    bool open();

    bool open(int fd);

    /**
     * Close the pty master/slave pair.
     */
    void close();

    /**
     * Close the pty slave descriptor.
     *
     * When creating the pty, KPty also opens the slave and keeps it open.
     * Consequently the master will never receive an EOF notification.
     * Usually this is the desired behavior, as a closed pty slave can be
     * reopened any time - unlike a pipe or socket. However, in some cases
     * pipe-alike behavior might be desired.
     *
     * After this function was called, slaveFd() and setCTty() cannot be
     * used.
     */
    void closeSlave();
    bool openSlave();

    /**
     * Creates a new session and process group and makes this pty the
     * controlling tty.
     */
    void setCTty();

    /**
     * Creates an utmp entry for the tty.
     * This function must be called after calling setCTty and
     * making this pty the stdin.
     * @param user the user to be logged on
     * @param remotehost the host from which the login is coming. This is
     *  @em not the local host. For remote logins it should be the hostname
     *  of the client. For local logins from inside an X session it should
     *  be the name of the X display. Otherwise it should be empty.
     */
    void login(const char * user = 0, const char * remotehost = 0);

    /**
     * Removes the utmp entry for this tty.
     */
    void logout();

    /**
     * Wrapper around tcgetattr(3).
     *
     * This function can be used only while the PTY is open.
     * You will need an #include &lt;termios.h&gt; to do anything useful
     * with it.
     *
     * @param ttmode a pointer to a termios structure.
     *  Note: when declaring ttmode, @c struct @c ::termios must be used -
     *  without the '::' some version of HP-UX thinks, this declares
     *  the struct in your class, in your method.
     * @return @c true on success, false otherwise
     */
    bool tcGetAttr(struct ::termios * ttmode) const;

    /**
     * Wrapper around tcsetattr(3) with mode TCSANOW.
     *
     * This function can be used only while the PTY is open.
     *
     * @param ttmode a pointer to a termios structure.
     * @return @c true on success, false otherwise. Note that success means
     *  that @em at @em least @em one attribute could be set.
     */
    bool tcSetAttr(struct ::termios * ttmode);

    /**
     * Change the logical (screen) size of the pty.
     * The default is 24 lines by 80 columns.
     *
     * This function can be used only while the PTY is open.
     *
     * @param lines the number of rows
     * @param columns the number of columns
     * @return @c true on success, false otherwise
     */
    bool setWinSize(int lines, int columns);

    /**
     * Set whether the pty should echo input.
     *
     * Echo is on by default.
     * If the output of automatically fed (non-interactive) PTY clients
     * needs to be parsed, disabling echo often makes it much simpler.
     *
     * This function can be used only while the PTY is open.
     *
     * @param echo true if input should be echoed.
     * @return @c true on success, false otherwise
     */
    bool setEcho(bool echo);

    /**
     * @return the name of the slave pty device.
     *
     * This function should be called only while the pty is open.
     */
    const char * ttyName() const;

    /**
     * @return the file descriptor of the master pty
     *
     * This function should be called only while the pty is open.
     */
    int masterFd() const;

    /**
     * @return the file descriptor of the slave pty
     *
     * This function should be called only while the pty slave is open.
     */
    int slaveFd() const;

protected:
    /**
     * @internal
     */
    KPty(KPtyPrivate * d);

    /**
     * @internal
     */
    KPtyPrivate * const d_ptr;
};

#endif

