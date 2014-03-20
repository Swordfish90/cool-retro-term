/*
    This source file is part of Konsole, a terminal emulator.

    Copyright 2007-2008 by Robert Knight <robertknight@gmail.com>

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

#ifndef KEYBOARDTRANSLATOR_H
#define KEYBOARDTRANSLATOR_H

// Qt
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtGui/QKeySequence>
#include <QtCore/QMetaType>
#include <QtCore/QVarLengthArray>

// Konsole
//#include "konsole_export.h"
#define KONSOLEPRIVATE_EXPORT

class QIODevice;
class QTextStream;


/** 
 * A convertor which maps between key sequences pressed by the user and the
 * character strings which should be sent to the terminal and commands
 * which should be invoked when those character sequences are pressed.
 *
 * Konsole supports multiple keyboard translators, allowing the user to
 * specify the character sequences which are sent to the terminal
 * when particular key sequences are pressed.
 *
 * A key sequence is defined as a key code, associated keyboard modifiers
 * (Shift,Ctrl,Alt,Meta etc.) and state flags which indicate the state
 * which the terminal must be in for the key sequence to apply.
 */
class KeyboardTranslator
{
public:
    /** 
     * The meaning of a particular key sequence may depend upon the state which
     * the terminal emulation is in.  Therefore findEntry() may return a different
     * Entry depending upon the state flags supplied.
     *
     * This enum describes the states which may be associated with with a particular
     * entry in the keyboard translation entry.
     */
    enum State
    {
        /** Indicates that no special state is active */
        NoState = 0,
        /**
         * TODO More documentation
         */
        NewLineState = 1,
        /** 
         * Indicates that the terminal is in 'Ansi' mode.
         * TODO: More documentation
         */
        AnsiState = 2,
        /**
         * TODO More documentation
         */
        CursorKeysState = 4,
        /**
         * Indicates that the alternate screen ( typically used by interactive programs
         * such as screen or vim ) is active 
         */
        AlternateScreenState = 8,
        /** Indicates that any of the modifier keys is active. */ 
        AnyModifierState = 16,
        /** Indicates that the numpad is in application mode. */
        ApplicationKeypadState = 32
    };
    Q_DECLARE_FLAGS(States,State)

    /**
     * This enum describes commands which are associated with particular key sequences.
     */
    enum Command
    {
        /** Indicates that no command is associated with this command sequence */
        NoCommand = 0,
        /** TODO Document me */
        SendCommand = 1,
        /** Scroll the terminal display up one page */
        ScrollPageUpCommand = 2,
        /** Scroll the terminal display down one page */
        ScrollPageDownCommand = 4,
        /** Scroll the terminal display up one line */
        ScrollLineUpCommand = 8,
        /** Scroll the terminal display down one line */
        ScrollLineDownCommand = 16,
        /** Toggles scroll lock mode */
        ScrollLockCommand = 32,
        /** Echos the operating system specific erase character. */
        EraseCommand = 64
    };
    Q_DECLARE_FLAGS(Commands,Command)

    /**
     * Represents an association between a key sequence pressed by the user
     * and the character sequence and commands associated with it for a particular
     * KeyboardTranslator.
     */
    class Entry
    {
    public:
        /** 
         * Constructs a new entry for a keyboard translator.
         */
        Entry();

        /** 
         * Returns true if this entry is null.
         * This is true for newly constructed entries which have no properties set. 
         */
        bool isNull() const;

        /** Returns the commands associated with this entry */
        Command command() const;
        /** Sets the command associated with this entry. */
        void setCommand(Command command);

        /** 
         * Returns the character sequence associated with this entry, optionally replacing 
         * wildcard '*' characters with numbers to indicate the keyboard modifiers being pressed.
         *
         * TODO: The numbers used to replace '*' characters are taken from the Konsole/KDE 3 code.
         * Document them. 
         *
         * @param expandWildCards Specifies whether wild cards (occurrences of the '*' character) in
         * the entry should be replaced with a number to indicate the modifier keys being pressed. 
         *
         * @param modifiers The keyboard modifiers being pressed.
         */
        QByteArray text(bool expandWildCards = false,
                        Qt::KeyboardModifiers modifiers = Qt::NoModifier) const;

        /** Sets the character sequence associated with this entry */
        void setText(const QByteArray& text);

        /** 
         * Returns the character sequence associated with this entry,
         * with any non-printable characters replaced with escape sequences.
         *
         * eg. \\E for Escape, \\t for tab, \\n for new line.
         *
         * @param expandWildCards See text()
         * @param modifiers See text()
         */
        QByteArray escapedText(bool expandWildCards = false,
                               Qt::KeyboardModifiers modifiers = Qt::NoModifier) const;

        /** Returns the character code ( from the Qt::Key enum ) associated with this entry */
        int keyCode() const;
        /** Sets the character code associated with this entry */
        void setKeyCode(int keyCode);

        /** 
         * Returns a bitwise-OR of the enabled keyboard modifiers associated with this entry. 
         * If a modifier is set in modifierMask() but not in modifiers(), this means that the entry
         * only matches when that modifier is NOT pressed.
         *
         * If a modifier is not set in modifierMask() then the entry matches whether the modifier
         * is pressed or not. 
         */
        Qt::KeyboardModifiers modifiers() const;

        /** Returns the keyboard modifiers which are valid in this entry.  See modifiers() */
        Qt::KeyboardModifiers modifierMask() const;

        /** See modifiers() */
        void setModifiers( Qt::KeyboardModifiers modifiers );
        /** See modifierMask() and modifiers() */
        void setModifierMask( Qt::KeyboardModifiers modifiers );

        /** 
         * Returns a bitwise-OR of the enabled state flags associated with this entry. 
         * If flag is set in stateMask() but not in state(), this means that the entry only 
         * matches when the terminal is NOT in that state.
         *
         * If a state is not set in stateMask() then the entry matches whether the terminal
         * is in that state or not. 
         */
        States state() const;

        /** Returns the state flags which are valid in this entry.  See state() */
        States stateMask() const;

        /** See state() */
        void setState( States state );
        /** See stateMask() */
        void setStateMask( States mask );

        /** 
         * Returns the key code and modifiers associated with this entry 
         * as a QKeySequence
         */
        //QKeySequence keySequence() const;

        /** 
         * Returns this entry's conditions ( ie. its key code, modifier and state criteria )
         * as a string.
         */
        QString conditionToString() const;

        /**
         * Returns this entry's result ( ie. its command or character sequence )
         * as a string.
         *
         * @param expandWildCards See text()
         * @param modifiers See text()
         */
        QString resultToString(bool expandWildCards = false,
                               Qt::KeyboardModifiers modifiers = Qt::NoModifier) const;

        /** 
         * Returns true if this entry matches the given key sequence, specified
         * as a combination of @p keyCode , @p modifiers and @p state.
         */
        bool matches( int keyCode , 
                      Qt::KeyboardModifiers modifiers , 
                      States flags ) const;

        bool operator==(const Entry& rhs) const;
       
    private:
        void insertModifier( QString& item , int modifier ) const;
        void insertState( QString& item , int state ) const;
        QByteArray unescape(const QByteArray& text) const;

        int _keyCode;
        Qt::KeyboardModifiers _modifiers;
        Qt::KeyboardModifiers _modifierMask;
        States _state;
        States _stateMask;

        Command _command;
        QByteArray _text;
    };

    /** Constructs a new keyboard translator with the given @p name */
    KeyboardTranslator(const QString& name);
   
    //KeyboardTranslator(const KeyboardTranslator& other);

    /** Returns the name of this keyboard translator */
    QString name() const;

    /** Sets the name of this keyboard translator */
    void setName(const QString& name);

    /** Returns the descriptive name of this keyboard translator */
    QString description() const;

    /** Sets the descriptive name of this keyboard translator */
    void setDescription(const QString& description);

    /**
     * Looks for an entry in this keyboard translator which matches the given
     * key code, keyboard modifiers and state flags.
     * 
     * Returns the matching entry if found or a null Entry otherwise ( ie.
     * entry.isNull() will return true )
     *
     * @param keyCode A key code from the Qt::Key enum
     * @param modifiers A combination of modifiers
     * @param state Optional flags which specify the current state of the terminal
     */
    Entry findEntry(int keyCode , 
                    Qt::KeyboardModifiers modifiers , 
                    States state = NoState) const;

    /** 
     * Adds an entry to this keyboard translator's table.  Entries can be looked up according
     * to their key sequence using findEntry()
     */
    void addEntry(const Entry& entry);

    /**
     * Replaces an entry in the translator.  If the @p existing entry is null,
     * then this is equivalent to calling addEntry(@p replacement)
     */
    void replaceEntry(const Entry& existing , const Entry& replacement);

    /**
     * Removes an entry from the table.
     */
    void removeEntry(const Entry& entry);

    /** Returns a list of all entries in the translator. */
    QList<Entry> entries() const;

private:

    QMultiHash<int,Entry> _entries; // entries in this keyboard translation,
                                                 // entries are indexed according to
                                                 // their keycode
    QString _name;
    QString _description;
};
Q_DECLARE_OPERATORS_FOR_FLAGS(KeyboardTranslator::States)
Q_DECLARE_OPERATORS_FOR_FLAGS(KeyboardTranslator::Commands)

/** 
 * Parses the contents of a Keyboard Translator (.keytab) file and 
 * returns the entries found in it.
 *
 * Usage example:
 *
 * @code
 *  QFile source( "/path/to/keytab" );
 *  source.open( QIODevice::ReadOnly );
 *
 *  KeyboardTranslator* translator = new KeyboardTranslator( "name-of-translator" );
 *
 *  KeyboardTranslatorReader reader(source);
 *  while ( reader.hasNextEntry() )
 *      translator->addEntry(reader.nextEntry());
 *
 *  source.close();
 *
 *  if ( !reader.parseError() )
 *  {
 *      // parsing succeeded, do something with the translator
 *  } 
 *  else
 *  {
 *      // parsing failed
 *  }
 * @endcode
 */
class KeyboardTranslatorReader
{
public:
    /** Constructs a new reader which parses the given @p source */
    KeyboardTranslatorReader( QIODevice* source );

    /** 
     * Returns the description text. 
     * TODO: More documentation 
     */
    QString description() const;

    /** Returns true if there is another entry in the source stream */
    bool hasNextEntry();
    /** Returns the next entry found in the source stream */
    KeyboardTranslator::Entry nextEntry(); 

    /** 
     * Returns true if an error occurred whilst parsing the input or
     * false if no error occurred.
     */
    bool parseError();

    /**
     * Parses a condition and result string for a translator entry
     * and produces a keyboard translator entry.
     *
     * The condition and result strings are in the same format as in  
     */
    static KeyboardTranslator::Entry createEntry( const QString& condition ,
                                                  const QString& result );
private:
    struct Token
    {
        enum Type
        {
            TitleKeyword,
            TitleText,
            KeyKeyword,
            KeySequence,
            Command,
            OutputText
        };
        Type type;
        QString text;
    };
    QList<Token> tokenize(const QString&);
    void readNext();
    bool decodeSequence(const QString& , 
                                int& keyCode,
                                Qt::KeyboardModifiers& modifiers,
                                Qt::KeyboardModifiers& modifierMask,
                                KeyboardTranslator::States& state,
                                KeyboardTranslator::States& stateFlags);

    static bool parseAsModifier(const QString& item , Qt::KeyboardModifier& modifier);
    static bool parseAsStateFlag(const QString& item , KeyboardTranslator::State& state);
    static bool parseAsKeyCode(const QString& item , int& keyCode);
       static bool parseAsCommand(const QString& text , KeyboardTranslator::Command& command);

    QIODevice* _source;
    QString _description;
    KeyboardTranslator::Entry _nextEntry;
    bool _hasNext;
};

/** Writes a keyboard translation to disk. */
class KeyboardTranslatorWriter
{
public:
    /** 
     * Constructs a new writer which saves data into @p destination.
     * The caller is responsible for closing the device when writing is complete.
     */
    KeyboardTranslatorWriter(QIODevice* destination);
    ~KeyboardTranslatorWriter();

    /** 
     * Writes the header for the keyboard translator. 
     * @param description Description of the keyboard translator. 
     */
    void writeHeader( const QString& description );
    /** Writes a translator entry. */
    void writeEntry( const KeyboardTranslator::Entry& entry ); 

private:
    QIODevice* _destination;  
    QTextStream* _writer;
};

/**
 * Manages the keyboard translations available for use by terminal sessions,
 * see KeyboardTranslator.
 */
class KONSOLEPRIVATE_EXPORT KeyboardTranslatorManager
{
public:
    /** 
     * Constructs a new KeyboardTranslatorManager and loads the list of
     * available keyboard translations.
     *
     * The keyboard translations themselves are not loaded until they are
     * first requested via a call to findTranslator()
     */
    KeyboardTranslatorManager();
    ~KeyboardTranslatorManager();

    /**
     * Adds a new translator.  If a translator with the same name 
     * already exists, it will be replaced by the new translator.
     *
     * TODO: More documentation.
     */
    void addTranslator(KeyboardTranslator* translator);

    /**
     * Deletes a translator.  Returns true on successful deletion or false otherwise.
     *
     * TODO: More documentation
     */
    bool deleteTranslator(const QString& name);

    /** Returns the default translator for Konsole. */
    const KeyboardTranslator* defaultTranslator();

    /** 
     * Returns the keyboard translator with the given name or 0 if no translator
     * with that name exists.
     *
     * The first time that a translator with a particular name is requested,
     * the on-disk .keyboard file is loaded and parsed.  
     */
    const KeyboardTranslator* findTranslator(const QString& name);
    /**
     * Returns a list of the names of available keyboard translators.
     *
     * The first time this is called, a search for available 
     * translators is started.
     */
    QList<QString> allTranslators();

    /** Returns the global KeyboardTranslatorManager instance. */
   static KeyboardTranslatorManager* instance();

private:
    static const QByteArray defaultTranslatorText;
    
    void findTranslators(); // locate the available translators
    KeyboardTranslator* loadTranslator(const QString& name); // loads the translator 
                                                             // with the given name
    KeyboardTranslator* loadTranslator(QIODevice* device,const QString& name);

    bool saveTranslator(const KeyboardTranslator* translator);
    QString findTranslatorPath(const QString& name);
    
    QHash<QString,KeyboardTranslator*> _translators; // maps translator-name -> KeyboardTranslator
                                                     // instance
    bool _haveLoadedAll;

    static KeyboardTranslatorManager * theKeyboardTranslatorManager;
};

inline int KeyboardTranslator::Entry::keyCode() const { return _keyCode; }
inline void KeyboardTranslator::Entry::setKeyCode(int keyCode) { _keyCode = keyCode; }

inline void KeyboardTranslator::Entry::setModifiers( Qt::KeyboardModifiers modifier ) 
{ 
    _modifiers = modifier;
}
inline Qt::KeyboardModifiers KeyboardTranslator::Entry::modifiers() const { return _modifiers; }

inline void  KeyboardTranslator::Entry::setModifierMask( Qt::KeyboardModifiers mask ) 
{ 
   _modifierMask = mask; 
}
inline Qt::KeyboardModifiers KeyboardTranslator::Entry::modifierMask() const { return _modifierMask; }

inline bool KeyboardTranslator::Entry::isNull() const
{
    return ( *this == Entry() );
}

inline void KeyboardTranslator::Entry::setCommand( Command command )
{ 
    _command = command; 
}
inline KeyboardTranslator::Command KeyboardTranslator::Entry::command() const { return _command; }

inline void KeyboardTranslator::Entry::setText( const QByteArray& text )
{ 
    _text = unescape(text);
}
inline int oneOrZero(int value)
{
    return value ? 1 : 0;
}
inline QByteArray KeyboardTranslator::Entry::text(bool expandWildCards,Qt::KeyboardModifiers modifiers) const 
{
    QByteArray expandedText = _text;
    
    if (expandWildCards)
    {
        int modifierValue = 1;
        modifierValue += oneOrZero(modifiers & Qt::ShiftModifier);
        modifierValue += oneOrZero(modifiers & Qt::AltModifier)     << 1;
        modifierValue += oneOrZero(modifiers & Qt::ControlModifier) << 2;

        for (int i=0;i<_text.length();i++) 
        {
            if (expandedText[i] == '*')
                expandedText[i] = '0' + modifierValue;
        }
    }

    return expandedText; 
}

inline void KeyboardTranslator::Entry::setState( States state )
{ 
    _state = state; 
}
inline KeyboardTranslator::States KeyboardTranslator::Entry::state() const { return _state; }

inline void KeyboardTranslator::Entry::setStateMask( States stateMask )
{ 
    _stateMask = stateMask; 
}
inline KeyboardTranslator::States KeyboardTranslator::Entry::stateMask() const { return _stateMask; }


Q_DECLARE_METATYPE(KeyboardTranslator::Entry)
Q_DECLARE_METATYPE(const KeyboardTranslator*)

#endif // KEYBOARDTRANSLATOR_H

