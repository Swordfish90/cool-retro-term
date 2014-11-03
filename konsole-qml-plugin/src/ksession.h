/*
    This file is part of Konsole QML plugin,
    which is a terminal emulator from KDE.

    Copyright 2013      by Dmitry Zagnoyko <hiroshidi@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA.
*/

#ifndef KSESSION_H
#define KSESSION_H

#include <QObject>

// Konsole
#include "Session.h"

class KTerminalDisplay;

class KSession : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString  kbScheme  READ  getKeyBindings WRITE setKeyBindings NOTIFY changedKeyBindings)
    Q_PROPERTY(QString  initialWorkingDirectory READ getInitialWorkingDirectory WRITE setInitialWorkingDirectory)
    Q_PROPERTY(QString  title READ getTitle NOTIFY titleChanged)

public:
    KSession(QObject *parent = 0);
    ~KSession();
    
public:
    //bool setup();
    void addView(KTerminalDisplay *displa);

    int getRandomSeed();
    QString getKeyBindings();

    //look-n-feel, if you don`t like defaults

    //environment
    void setEnvironment(const QStringList & environment);

    //Initial working directory
    void setInitialWorkingDirectory(const QString & dir);
    QString getInitialWorkingDirectory();

    // Shell program args, default is none
    void setArgs(QStringList & args);

    //Text codec, default is UTF-8
    void setTextCodec(QTextCodec * codec);

    // History size for scrolling
    void setHistorySize(int lines); //infinite if lines < 0

    // Sets whether flow control is enabled
    void setFlowControlEnabled(bool enabled);

    // Returns whether flow control is enabled
    bool flowControlEnabled(void);

    /**
     * Sets whether the flow control warning box should be shown
     * when the flow control stop key (Ctrl+S) is pressed.
     */
    //void setFlowControlWarningEnabled(bool enabled);

    /*! Get all available keyboard bindings
     */
    static QStringList availableKeyBindings();

    //! Return current key bindings
    QString keyBindings();

    QString getTitle();

signals:
    void finished();
    void copyAvailable(bool);

    void termGetFocus();
    void termLostFocus();

    void termKeyPressed(QKeyEvent *);

    void changedKeyBindings(QString kb);

    void titleChanged();

public slots:
    /*! Set named key binding for given widget
     */
    void setKeyBindings(const QString & kb);
    void setTitle(QString name);

    void startShellProgram();

    //  Shell program, default is /bin/bash
    void setShellProgram(const QString & progname);

    int getShellPID();
    void changeDir(const QString & dir);

    // Send some text to terminal
    void sendText(QString text);
    // Send some text to terminal
    void sendKey(int rep, int key, int mod) const;


protected slots:
    void sessionFinished();
    void selectionChanged(bool textSelected);

private slots:
    Session* createSession(QString name);
    //Konsole::KTerminalDisplay* createTerminalDisplay(Konsole::Session *session, QQuickItem* parent);

private:
    //Konsole::KTerminalDisplay *m_terminalDisplay;
    QString _initialWorkingDirectory;
    Session *m_session;

};

#endif // KSESSION_H
