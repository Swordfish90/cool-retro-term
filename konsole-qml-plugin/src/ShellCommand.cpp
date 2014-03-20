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

// Own
#include "ShellCommand.h"

//some versions of gcc(4.3) require explicit include
#include <cstdlib>


// expands environment variables in 'text'
// function copied from kdelibs/kio/kio/kurlcompletion.cpp
static bool expandEnv(QString & text);

ShellCommand::ShellCommand(const QString & fullCommand)
{
    bool inQuotes = false;

    QString builder;

    for ( int i = 0 ; i < fullCommand.count() ; i++ ) {
        QChar ch = fullCommand[i];

        const bool isLastChar = ( i == fullCommand.count() - 1 );
        const bool isQuote = ( ch == '\'' || ch == '\"' );

        if ( !isLastChar && isQuote ) {
            inQuotes = !inQuotes;
        } else {
            if ( (!ch.isSpace() || inQuotes) && !isQuote ) {
                builder.append(ch);
            }

            if ( (ch.isSpace() && !inQuotes) || ( i == fullCommand.count()-1 ) ) {
                _arguments << builder;
                builder.clear();
            }
        }
    }
}
ShellCommand::ShellCommand(const QString & command , const QStringList & arguments)
{
    _arguments = arguments;

    if ( !_arguments.isEmpty() ) {
        _arguments[0] == command;
    }
}
QString ShellCommand::fullCommand() const
{
    return _arguments.join(QChar(' '));
}
QString ShellCommand::command() const
{
    if ( !_arguments.isEmpty() ) {
        return _arguments[0];
    } else {
        return QString();
    }
}
QStringList ShellCommand::arguments() const
{
    return _arguments;
}
bool ShellCommand::isRootCommand() const
{
    Q_ASSERT(0); // not implemented yet
    return false;
}
bool ShellCommand::isAvailable() const
{
    Q_ASSERT(0); // not implemented yet
    return false;
}
QStringList ShellCommand::expand(const QStringList & items)
{
    QStringList result;

    foreach( QString item , items )
    result << expand(item);

    return result;
}
QString ShellCommand::expand(const QString & text)
{
    QString result = text;
    expandEnv(result);
    return result;
}

/*
 * expandEnv
 *
 * Expand environment variables in text. Escaped '$' characters are ignored.
 * Return true if any variables were expanded
 */
static bool expandEnv( QString & text )
{
    // Find all environment variables beginning with '$'
    //
    int pos = 0;

    bool expanded = false;

    while ( (pos = text.indexOf(QLatin1Char('$'), pos)) != -1 ) {

        // Skip escaped '$'
        //
        if ( pos > 0 && text.at(pos-1) == QLatin1Char('\\') ) {
            pos++;
        }
        // Variable found => expand
        //
        else {
            // Find the end of the variable = next '/' or ' '
            //
            int pos2 = text.indexOf( QLatin1Char(' '), pos+1 );
            int pos_tmp = text.indexOf( QLatin1Char('/'), pos+1 );

            if ( pos2 == -1 || (pos_tmp != -1 && pos_tmp < pos2) ) {
                pos2 = pos_tmp;
            }

            if ( pos2 == -1 ) {
                pos2 = text.length();
            }

            // Replace if the variable is terminated by '/' or ' '
            // and defined
            //
            if ( pos2 >= 0 ) {
                int len = pos2 - pos;
                QString key = text.mid( pos+1, len-1);
                QString value =
                    QString::fromLocal8Bit( ::getenv(key.toLocal8Bit()) );

                if ( !value.isEmpty() ) {
                    expanded = true;
                    text.replace( pos, len, value );
                    pos = pos + value.length();
                } else {
                    pos = pos2;
                }
            }
        }
    }

    return expanded;
}
