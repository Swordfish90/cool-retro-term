/*
    Copyright (C) 2007 by Robert Knight <robertknight@gmail.com>

    Rewritten for QT4 by e_k <e_k at users.sourceforge.net>, Copyright (C)2008

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

#ifndef SHELLCOMMAND_H
#define SHELLCOMMAND_H

// Qt
#include <QtCore/QStringList>


/**
 * A class to parse and extract information about shell commands.
 *
 * ShellCommand can be used to:
 *
 * <ul>
 *      <li>Take a command-line (eg "/bin/sh -c /path/to/my/script") and split it
 *          into its component parts (eg. the command "/bin/sh" and the arguments
 *          "-c","/path/to/my/script")
 *      </li>
 *      <li>Take a command and a list of arguments and combine them to
 *          form a complete command line.
 *      </li>
 *      <li>Determine whether the binary specified by a command exists in the
 *          user's PATH.
 *      </li>
 *      <li>Determine whether a command-line specifies the execution of
 *          another command as the root user using su/sudo etc.
 *      </li>
 * </ul>
 */
class ShellCommand {
public:
    /**
     * Constructs a ShellCommand from a command line.
     *
     * @param fullCommand The command line to parse.
     */
    ShellCommand(const QString & fullCommand);
    /**
     * Constructs a ShellCommand with the specified @p command and @p arguments.
     */
    ShellCommand(const QString & command , const QStringList & arguments);

    /** Returns the command. */
    QString command() const;
    /** Returns the arguments. */
    QStringList arguments() const;

    /**
     * Returns the full command line.
     */
    QString fullCommand() const;

    /** Returns true if this is a root command. */
    bool isRootCommand() const;
    /** Returns true if the program specified by @p command() exists. */
    bool isAvailable() const;

    /** Expands environment variables in @p text .*/
    static QString expand(const QString & text);

    /** Expands environment variables in each string in @p list. */
    static QStringList expand(const QStringList & items);

private:
    QStringList _arguments;
};


#endif // SHELLCOMMAND_H

