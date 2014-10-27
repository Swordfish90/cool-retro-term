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

// Own
#include "ksession.h"

// Qt
#include <QTextCodec>

// Konsole
#include "KeyboardTranslator.h"
#include "TerminalDisplay.h"


KSession::KSession(QObject *parent) :
    QObject(parent), m_session(createSession("KSession"))
{
    connect(m_session, SIGNAL(finished()), this, SLOT(sessionFinished()));
    connect(m_session, SIGNAL(titleChanged()), this, SIGNAL(titleChanged()));
}

KSession::~KSession()
{
    if (m_session) {
        m_session->close();
        m_session->disconnect();
        delete m_session;
    }
}

void KSession::setTitle(QString name)
{
    m_session->setTitle(Session::NameRole, name);
}


Session *KSession::createSession(QString name)
{
    Session *session = new Session();

    session->setTitle(Session::NameRole, name);

    /* Thats a freaking bad idea!!!!
     * /bin/bash is not there on every system
     * better set it to the current $SHELL
     * Maybe you can also make a list available and then let the widget-owner decide what to use.
     * By setting it to $SHELL right away we actually make the first filecheck obsolete.
     * But as iam not sure if you want to do anything else ill just let both checks in and set this to $SHELL anyway.
     */

    //cool-old-term: There is another check in the code. Not sure if useful.

    QString envshell = getenv("SHELL");
    QString shellProg = envshell != NULL ? envshell : "/bin/bash";
    session->setProgram(shellProg);

    setenv("TERM", "xterm", 1);

    //session->setProgram();

    QStringList args("");
    session->setArguments(args);
    session->setAutoClose(true);

    session->setCodec(QTextCodec::codecForName("UTF-8"));

    session->setFlowControlEnabled(true);
    session->setHistoryType(HistoryTypeBuffer(1000));

    session->setDarkBackground(true);

    session->setKeyBindings("");

    return session;
}

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


int  KSession::getRandomSeed()
{
    return m_session->sessionId() * 31;
}

void  KSession::addView(KTerminalDisplay *displa)
{
    m_session->addView(displa);
}

void KSession::sessionFinished()
{
    emit finished();
}

void KSession::selectionChanged(bool textSelected)
{
    Q_UNUSED(textSelected)
}

void KSession::startShellProgram()
{
    if ( m_session->isRunning() ) {
        return;
    }

    m_session->run();
}

int KSession::getShellPID()
{
    return m_session->processId();
}

void KSession::changeDir(const QString &dir)
{
    /*
       this is a very hackish way of trying to determine if the shell is in
       the foreground before attempting to change the directory.  It may not
       be portable to anything other than Linux.
    */
    QString strCmd;
    strCmd.setNum(getShellPID());
    strCmd.prepend("ps -j ");
    strCmd.append(" | tail -1 | awk '{ print $5 }' | grep -q \\+");
    int retval = system(strCmd.toStdString().c_str());

    if (!retval) {
        QString cmd = "cd " + dir + "\n";
        sendText(cmd);
    }
}

void KSession::setEnvironment(const QStringList &environment)
{
    m_session->setEnvironment(environment);
}


void KSession::setShellProgram(const QString &progname)
{
    m_session->setProgram(progname);
}

void KSession::setInitialWorkingDirectory(const QString &dir)
{
    _initialWorkingDirectory = dir;
    m_session->setInitialWorkingDirectory(dir);
}

QString KSession::getInitialWorkingDirectory()
{
    return _initialWorkingDirectory;
}

void KSession::setArgs(QStringList &args)
{
    m_session->setArguments(args);
}

void KSession::setTextCodec(QTextCodec *codec)
{
    m_session->setCodec(codec);
}

void KSession::setHistorySize(int lines)
{
    if (lines < 0)
        m_session->setHistoryType(HistoryTypeFile());
    else
        m_session->setHistoryType(HistoryTypeBuffer(lines));
}

void KSession::sendText(QString text)
{
    m_session->sendText(text);
}

void KSession::sendKey(int rep, int key, int mod) const
{
    Qt::KeyboardModifier kbm = Qt::KeyboardModifier(mod);

    QKeyEvent qkey(QEvent::KeyPress, key, kbm);

    while (rep > 0){
        m_session->sendKey(&qkey);
        --rep;
    }
}

void KSession::setFlowControlEnabled(bool enabled)
{
    m_session->setFlowControlEnabled(enabled);
}

bool KSession::flowControlEnabled()
{
    return m_session->flowControlEnabled();
}

void KSession::setKeyBindings(const QString &kb)
{
    m_session->setKeyBindings(kb);
    emit changedKeyBindings(kb);
}

QString KSession::getKeyBindings()
{
   return m_session->keyBindings();
}


QStringList KSession::availableKeyBindings()
{
    return KeyboardTranslatorManager::instance()->allTranslators();
}

QString KSession::keyBindings()
{
    return m_session->keyBindings();
}

QString KSession::getTitle()
{
    return m_session->userTitle();
}
