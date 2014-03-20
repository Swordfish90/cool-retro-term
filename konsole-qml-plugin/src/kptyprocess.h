/*
 * This file is a part of QTerminal - http://gitorious.org/qterminal
 *
 * This file was un-linked from KDE and modified
 * by Maxim Bourmistrov <maxim@unixconn.com>
 *
 */

/*
    This file is part of the KDE libraries

    Copyright (C) 2007 Oswald Buddenhagen <ossi@kde.org>

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

#ifndef KPTYPROCESS_H
#define KPTYPROCESS_H

#include "kprocess.h"
#include "kptydevice.h"

#include <signal.h>

class KPtyDevice;

struct KPtyProcessPrivate;

/**
 * This class extends KProcess by support for PTYs (pseudo TTYs).
 *
 * The PTY is opened as soon as the class is instantiated. Verify that
 * it was opened successfully by checking that pty()->masterFd() is not -1.
 *
 * The PTY is always made the process' controlling TTY.
 * Utmp registration and connecting the stdio handles to the PTY are optional.
 *
 * No attempt to integrate with QProcess' waitFor*() functions was made,
 * for it is impossible. Note that execute() does not work with the PTY, too.
 * Use the PTY device's waitFor*() functions or use it asynchronously.
 *
 * @author Oswald Buddenhagen <ossi@kde.org>
 */
class KPtyProcess : public KProcess
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(KPtyProcess)

public:
    enum PtyChannelFlag {
        NoChannels = 0, /**< The PTY is not connected to any channel. */
        StdinChannel = 1, /**< Connect PTY to stdin. */
        StdoutChannel = 2, /**< Connect PTY to stdout. */
        StderrChannel = 4, /**< Connect PTY to stderr. */
        AllOutputChannels = 6, /**< Connect PTY to all output channels. */
        AllChannels = 7 /**< Connect PTY to all channels. */
    };

    Q_DECLARE_FLAGS(PtyChannels, PtyChannelFlag)

    /**
     * Constructor
     */
    explicit KPtyProcess(QObject *parent = 0);

    /**
     * Construct a process using an open pty master.
     *
     * @param ptyMasterFd an open pty master file descriptor.
     *   The process does not take ownership of the descriptor;
     *   it will not be automatically closed at any point.
     */
    KPtyProcess(int ptyMasterFd, QObject *parent = 0);

    /**
     * Destructor
     */
    virtual ~KPtyProcess();

    /**
     * Set to which channels the PTY should be assigned.
     *
     * This function must be called before starting the process.
     *
     * @param channels the output channel handling mode
     */
    void setPtyChannels(PtyChannels channels);

    bool isRunning() const
    {
        bool rval;
        (pid() > 0) ? rval= true : rval= false;
        return rval;

    }
    /**
     * Query to which channels the PTY is assigned.
     *
     * @return the output channel handling mode
     */
    PtyChannels ptyChannels() const;

    /**
     * Set whether to register the process as a TTY login in utmp.
     *
     * Utmp is disabled by default.
     * It should enabled for interactively fed processes, like terminal
     * emulations.
     *
     * This function must be called before starting the process.
     *
     * @param value whether to register in utmp.
     */
    void setUseUtmp(bool value);

    /**
     * Get whether to register the process as a TTY login in utmp.
     *
     * @return whether to register in utmp
     */
    bool isUseUtmp() const;

    /**
     * Get the PTY device of this process.
     *
     * @return the PTY device
     */
    KPtyDevice *pty() const;

protected:
    /**
     * @reimp
     */
    virtual void setupChildProcess();

private:
    Q_PRIVATE_SLOT(d_func(), void _k_onStateChanged(QProcess::ProcessState))
};


//////////////////
// private data //
//////////////////

struct KPtyProcessPrivate : KProcessPrivate {
    KPtyProcessPrivate() :
        ptyChannels(KPtyProcess::NoChannels),
        addUtmp(false)
    {
    }

    void _k_onStateChanged(QProcess::ProcessState newState)
    {
        if (newState == QProcess::NotRunning && addUtmp)
            pty->logout();
    }

    KPtyDevice *pty;
    KPtyProcess::PtyChannels ptyChannels;
    bool addUtmp : 1;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(KPtyProcess::PtyChannels)

#endif
