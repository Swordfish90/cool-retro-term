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

// Own
#include "ColorScheme.h"
#include "tools.h"

// Qt
#include <QtGui/QBrush>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtDebug>
#include <QSettings>
#include <QDir>


// KDE
//#include <KColorScheme>
//#include <KConfig>
//#include <KLocale>
//#include <KDebug>
//#include <KConfigGroup>
//#include <KStandardDirs>


const ColorEntry ColorScheme::defaultTable[TABLE_COLORS] =
 // The following are almost IBM standard color codes, with some slight
 // gamma correction for the dim colors to compensate for bright X screens.
 // It contains the 8 ansiterm/xterm colors in 2 intensities.
{
    ColorEntry( QColor(0x00,0x00,0x00), 0), ColorEntry(
QColor(0xFF,0xFF,0xFF), 1), // Dfore, Dback
    ColorEntry( QColor(0x00,0x00,0x00), 0), ColorEntry(
QColor(0xB2,0x18,0x18), 0), // Black, Red
    ColorEntry( QColor(0x18,0xB2,0x18), 0), ColorEntry(
QColor(0xB2,0x68,0x18), 0), // Green, Yellow
    ColorEntry( QColor(0x18,0x18,0xB2), 0), ColorEntry(
QColor(0xB2,0x18,0xB2), 0), // Blue, Magenta
    ColorEntry( QColor(0x18,0xB2,0xB2), 0), ColorEntry(
QColor(0xB2,0xB2,0xB2), 0), // Cyan, White
    // intensive
    ColorEntry( QColor(0x00,0x00,0x00), 0), ColorEntry(
QColor(0xFF,0xFF,0xFF), 1),
    ColorEntry( QColor(0x68,0x68,0x68), 0), ColorEntry(
QColor(0xFF,0x54,0x54), 0),
    ColorEntry( QColor(0x54,0xFF,0x54), 0), ColorEntry(
QColor(0xFF,0xFF,0x54), 0),
    ColorEntry( QColor(0x54,0x54,0xFF), 0), ColorEntry(
QColor(0xFF,0x54,0xFF), 0),
    ColorEntry( QColor(0x54,0xFF,0xFF), 0), ColorEntry(
QColor(0xFF,0xFF,0xFF), 0)
};

const char* const ColorScheme::colorNames[TABLE_COLORS] =
{
  "Foreground",
  "Background",
  "Color0",
  "Color1",
  "Color2",
  "Color3",
  "Color4",
  "Color5",
  "Color6",
  "Color7",
  "ForegroundIntense",
  "BackgroundIntense",
  "Color0Intense",
  "Color1Intense",
  "Color2Intense",
  "Color3Intense",
  "Color4Intense",
  "Color5Intense",
  "Color6Intense",
  "Color7Intense"
};
// dummy silently comment out the tr_NOOP
#define tr_NOOP
const char* const ColorScheme::translatedColorNames[TABLE_COLORS] =
{
    tr_NOOP("Foreground"),
    tr_NOOP("Background"),
    tr_NOOP("Color 1"),
    tr_NOOP("Color 2"),
    tr_NOOP("Color 3"),
    tr_NOOP("Color 4"),
    tr_NOOP("Color 5"),
    tr_NOOP("Color 6"),
    tr_NOOP("Color 7"),
    tr_NOOP("Color 8"),
    tr_NOOP("Foreground (Intense)"),
    tr_NOOP("Background (Intense)"),
    tr_NOOP("Color 1 (Intense)"),
    tr_NOOP("Color 2 (Intense)"),
    tr_NOOP("Color 3 (Intense)"),
    tr_NOOP("Color 4 (Intense)"),
    tr_NOOP("Color 5 (Intense)"),
    tr_NOOP("Color 6 (Intense)"),
    tr_NOOP("Color 7 (Intense)"),
    tr_NOOP("Color 8 (Intense)")
};

ColorScheme::ColorScheme()
{
    _table = 0;
    _randomTable = 0;
    _opacity = 1.0;
}
ColorScheme::ColorScheme(const ColorScheme& other)
      : _opacity(other._opacity)
       ,_table(0)
       ,_randomTable(0)
{
    setName(other.name());
    setDescription(other.description());

    if ( other._table != 0 )
    {
        for ( int i = 0 ; i < TABLE_COLORS ; i++ )
            setColorTableEntry(i,other._table[i]);
    }

    if ( other._randomTable != 0 )
    {
        for ( int i = 0 ; i < TABLE_COLORS ; i++ )
        {
            const RandomizationRange& range = other._randomTable[i];
            setRandomizationRange(i,range.hue,range.saturation,range.value);
        }
    }
}
ColorScheme::~ColorScheme()
{
    delete[] _table;
    delete[] _randomTable;
}

void ColorScheme::setDescription(const QString& description) { _description = description; }
QString ColorScheme::description() const { return _description; }

void ColorScheme::setName(const QString& name) { _name = name; }
QString ColorScheme::name() const { return _name; }

void ColorScheme::setColorTableEntry(int index , const ColorEntry& entry)
{
    Q_ASSERT( index >= 0 && index < TABLE_COLORS );

    if ( !_table )
    {
        _table = new ColorEntry[TABLE_COLORS];

        for (int i=0;i<TABLE_COLORS;i++)
            _table[i] = defaultTable[i];
    }

    _table[index] = entry;
}
ColorEntry ColorScheme::colorEntry(int index , uint randomSeed) const
{
    Q_ASSERT( index >= 0 && index < TABLE_COLORS );

    if ( randomSeed != 0 )
        qsrand(randomSeed);

    ColorEntry entry = colorTable()[index];

    if ( randomSeed != 0 &&
        _randomTable != 0 &&
        !_randomTable[index].isNull() )
    {
        const RandomizationRange& range = _randomTable[index];


        int hueDifference = range.hue ? (qrand() % range.hue) - range.hue/2 : 0;
        int saturationDifference = range.saturation ? (qrand() % range.saturation) - range.saturation/2 : 0;
        int  valueDifference = range.value ? (qrand() % range.value) - range.value/2 : 0;

        QColor& color = entry.color;

        int newHue = qAbs( (color.hue() + hueDifference) % MAX_HUE );
        int newValue = qMin( qAbs(color.value() + valueDifference) , 255 );
        int newSaturation = qMin( qAbs(color.saturation() + saturationDifference) , 255 );

        color.setHsv(newHue,newSaturation,newValue);
    }

    return entry;
}
void ColorScheme::getColorTable(ColorEntry* table , uint randomSeed) const
{
    for ( int i = 0 ; i < TABLE_COLORS ; i++ )
        table[i] = colorEntry(i,randomSeed);
}
bool ColorScheme::randomizedBackgroundColor() const
{
    return _randomTable == 0 ? false : !_randomTable[1].isNull();
}
void ColorScheme::setRandomizedBackgroundColor(bool randomize)
{
    // the hue of the background colour is allowed to be randomly
    // adjusted as much as possible.
    //
    // the value and saturation are left alone to maintain read-ability
    if ( randomize )
    {
        setRandomizationRange( 1 /* background color index */ , MAX_HUE , 255 , 0 );
    }
    else
    {
        if ( _randomTable )
            setRandomizationRange( 1 /* background color index */ , 0 , 0 , 0 );
    }
}

void ColorScheme::setRandomizationRange( int index , quint16 hue , quint8 saturation ,
                                         quint8 value )
{
    Q_ASSERT( hue <= MAX_HUE );
    Q_ASSERT( index >= 0 && index < TABLE_COLORS );

    if ( _randomTable == 0 )
        _randomTable = new RandomizationRange[TABLE_COLORS];

    _randomTable[index].hue = hue;
    _randomTable[index].value = value;
    _randomTable[index].saturation = saturation;
}

const ColorEntry* ColorScheme::colorTable() const
{
    if ( _table )
        return _table;
    else
        return defaultTable;
}
QColor ColorScheme::foregroundColor() const
{
    return colorTable()[0].color;
}
QColor ColorScheme::backgroundColor() const
{
    return colorTable()[1].color;
}
bool ColorScheme::hasDarkBackground() const
{
    // value can range from 0 - 255, with larger values indicating higher brightness.
    // so 127 is in the middle, anything less is deemed 'dark'
    return backgroundColor().value() < 127;
}
void ColorScheme::setOpacity(qreal opacity) { _opacity = opacity; }
qreal ColorScheme::opacity() const { return _opacity; }

void ColorScheme::read(const QString & fileName)
{
    QSettings s(fileName, QSettings::IniFormat);
    s.beginGroup("General");

    _description = s.value("Description", QObject::tr("Un-named Color Scheme")).toString();
    _opacity = s.value("Opacity",qreal(1.0)).toDouble();
    s.endGroup();

    for (int i=0 ; i < TABLE_COLORS ; i++)
    {
        readColorEntry(&s, i);
    }
}
#if 0
// implemented upstream - user apps
void ColorScheme::read(KConfig& config)
{
    KConfigGroup configGroup = config.group("General");

    QString description = configGroup.readEntry("Description", QObject::tr("Un-named Color Scheme"));

    _description = tr(description.toUtf8());
    _opacity = configGroup.readEntry("Opacity",qreal(1.0));

    for (int i=0 ; i < TABLE_COLORS ; i++)
    {
        readColorEntry(config,i);
    }
}
void ColorScheme::write(KConfig& config) const
{
    KConfigGroup configGroup = config.group("General");

    configGroup.writeEntry("Description",_description);
    configGroup.writeEntry("Opacity",_opacity);

    for (int i=0 ; i < TABLE_COLORS ; i++)
    {
        RandomizationRange random = _randomTable != 0 ? _randomTable[i] : RandomizationRange();
        writeColorEntry(config,colorNameForIndex(i),colorTable()[i],random);
    }
}
#endif

QString ColorScheme::colorNameForIndex(int index)
{
    Q_ASSERT( index >= 0 && index < TABLE_COLORS );

    return QString(colorNames[index]);
}
QString ColorScheme::translatedColorNameForIndex(int index)
{
    Q_ASSERT( index >= 0 && index < TABLE_COLORS );

    return translatedColorNames[index];
}

void ColorScheme::readColorEntry(QSettings * s , int index)
{
    s->beginGroup(colorNameForIndex(index));

    ColorEntry entry;

    QStringList rgbList = s->value("Color", QStringList()).toStringList();
    if (rgbList.count() != 3)
    {
        Q_ASSERT(0);
    }
    int r, g, b;
    r = rgbList[0].toInt();
    g = rgbList[1].toInt();
    b = rgbList[2].toInt();
    entry.color = QColor(r, g, b);

    entry.transparent = s->value("Transparent",false).toBool();

    // Deprecated key from KDE 4.0 which set 'Bold' to true to force
    // a color to be bold or false to use the current format
    //
    // TODO - Add a new tri-state key which allows for bold, normal or
    // current format
    if (s->contains("Bold"))
        entry.fontWeight = s->value("Bold",false).toBool() ? ColorEntry::Bold :
                                                                 ColorEntry::UseCurrentFormat;

    quint16 hue = s->value("MaxRandomHue",0).toInt();
    quint8 value = s->value("MaxRandomValue",0).toInt();
    quint8 saturation = s->value("MaxRandomSaturation",0).toInt();

    setColorTableEntry( index , entry );

    if ( hue != 0 || value != 0 || saturation != 0 )
       setRandomizationRange( index , hue , saturation , value );

    s->endGroup();
}
#if 0
// implemented upstream - user apps
void ColorScheme::writeColorEntry(KConfig& config , const QString& colorName, const ColorEntry& entry , const RandomizationRange& random) const
{
    KConfigGroup configGroup(&config,colorName);

    configGroup.writeEntry("Color",entry.color);
    configGroup.writeEntry("Transparency",(bool)entry.transparent);
    if (entry.fontWeight != ColorEntry::UseCurrentFormat)
    {
        configGroup.writeEntry("Bold",entry.fontWeight == ColorEntry::Bold);
    }

    // record randomization if this color has randomization or
    // if one of the keys already exists
    if ( !random.isNull() || configGroup.hasKey("MaxRandomHue") )
    {
        configGroup.writeEntry("MaxRandomHue",(int)random.hue);
        configGroup.writeEntry("MaxRandomValue",(int)random.value);
        configGroup.writeEntry("MaxRandomSaturation",(int)random.saturation);
    }
}
#endif

//
// Work In Progress - A color scheme for use on KDE setups for users
// with visual disabilities which means that they may have trouble
// reading text with the supplied color schemes.
//
// This color scheme uses only the 'safe' colors defined by the
// KColorScheme class.
//
// A complication this introduces is that each color provided by
// KColorScheme is defined as a 'background' or 'foreground' color.
// Only foreground colors are allowed to be used to render text and
// only background colors are allowed to be used for backgrounds.
//
// The ColorEntry and TerminalDisplay classes do not currently
// support this restriction.
//
// Requirements:
//  - A color scheme which uses only colors from the KColorScheme class
//  - Ability to restrict which colors the TerminalDisplay widget
//    uses as foreground and background color
//  - Make use of KGlobalSettings::allowDefaultBackgroundImages() as
//    a hint to determine whether this accessible color scheme should
//    be used by default.
//
//
// -- Robert Knight <robertknight@gmail.com> 21/07/2007
//
AccessibleColorScheme::AccessibleColorScheme()
    : ColorScheme()
{
#if 0
// It's not finished in konsole and it breaks Qt4 compilation as well
    // basic attributes
    setName("accessible");
    setDescription(QObject::tr("Accessible Color Scheme"));

    // setup colors
    const int ColorRoleCount = 8;

    const KColorScheme colorScheme(QPalette::Active);

    QBrush colors[ColorRoleCount] =
    {
        colorScheme.foreground( colorScheme.NormalText ),
        colorScheme.background( colorScheme.NormalBackground ),

        colorScheme.foreground( colorScheme.InactiveText ),
        colorScheme.foreground( colorScheme.ActiveText ),
        colorScheme.foreground( colorScheme.LinkText ),
        colorScheme.foreground( colorScheme.VisitedText ),
        colorScheme.foreground( colorScheme.NegativeText ),
        colorScheme.foreground( colorScheme.NeutralText )
    };

    for ( int i = 0 ; i < TABLE_COLORS ; i++ )
    {
        ColorEntry entry;
        entry.color = colors[ i % ColorRoleCount ].color();

        setColorTableEntry( i , entry );
    }
#endif
}

KDE3ColorSchemeReader::KDE3ColorSchemeReader( QIODevice* device ) :
    _device(device)
{
}
ColorScheme* KDE3ColorSchemeReader::read()
{
    Q_ASSERT( _device->openMode() == QIODevice::ReadOnly ||
              _device->openMode() == QIODevice::ReadWrite  );

    ColorScheme* scheme = new ColorScheme();

    QRegExp comment("#.*$");
    while ( !_device->atEnd() )
    {
        QString line(_device->readLine());
        line.remove(comment);
        line = line.simplified();

        if ( line.isEmpty() )
            continue;

        if ( line.startsWith(QLatin1String("color")) )
        {
            if (!readColorLine(line,scheme))
                qDebug() << "Failed to read KDE 3 color scheme line" << line;
        }
        else if ( line.startsWith(QLatin1String("title")) )
        {
            if (!readTitleLine(line,scheme))
                qDebug() << "Failed to read KDE 3 color scheme title line" << line;
        }
        else
        {
            qDebug() << "KDE 3 color scheme contains an unsupported feature, '" <<
                line << "'";
        }
    }

    return scheme;
}
bool KDE3ColorSchemeReader::readColorLine(const QString& line,ColorScheme* scheme)
{
    QStringList list = line.split(QChar(' '));

    if (list.count() != 7)
        return false;
    if (list.first() != "color")
        return false;

    int index = list[1].toInt();
    int red = list[2].toInt();
    int green = list[3].toInt();
    int blue = list[4].toInt();
    int transparent = list[5].toInt();
    int bold = list[6].toInt();

    const int MAX_COLOR_VALUE = 255;

    if(     (index < 0 || index >= TABLE_COLORS )
        ||  (red < 0 || red > MAX_COLOR_VALUE )
        ||  (blue < 0 || blue > MAX_COLOR_VALUE )
        ||  (green < 0 || green > MAX_COLOR_VALUE )
        ||  (transparent != 0 && transparent != 1 )
        ||  (bold != 0 && bold != 1)    )
        return false;

    ColorEntry entry;
    entry.color = QColor(red,green,blue);
    entry.transparent = ( transparent != 0 );
    entry.fontWeight = ( bold != 0 ) ? ColorEntry::Bold : ColorEntry::UseCurrentFormat;

    scheme->setColorTableEntry(index,entry);
    return true;
}
bool KDE3ColorSchemeReader::readTitleLine(const QString& line,ColorScheme* scheme)
{
    if( !line.startsWith(QLatin1String("title")) )
        return false;

    int spacePos = line.indexOf(' ');
    if( spacePos == -1 )
        return false;

    QString description = line.mid(spacePos+1);

    scheme->setDescription(description.toUtf8());
    return true;
}
ColorSchemeManager::ColorSchemeManager()
    : _haveLoadedAll(false)
{
}
ColorSchemeManager::~ColorSchemeManager()
{
    QHashIterator<QString,const ColorScheme*> iter(_colorSchemes);
    while (iter.hasNext())
    {
        iter.next();
        delete iter.value();
    }
}
void ColorSchemeManager::loadAllColorSchemes()
{
    qDebug() << "loadAllColorSchemes";
    int success = 0;
    int failed = 0;

    QList<QString> nativeColorSchemes = listColorSchemes();

    QListIterator<QString> nativeIter(nativeColorSchemes);
    while ( nativeIter.hasNext() )
    {
        if ( loadColorScheme( nativeIter.next() ) )
            success++;
        else
            failed++;
    }

    QList<QString> kde3ColorSchemes = listKDE3ColorSchemes();
    QListIterator<QString> kde3Iter(kde3ColorSchemes);
    while ( kde3Iter.hasNext() )
    {
        if ( loadKDE3ColorScheme( kde3Iter.next() ) )
            success++;
        else
            failed++;
    }

    if ( failed > 0 )
        qDebug() << "failed to load " << failed << " color schemes.";

    _haveLoadedAll = true;
}
QList<const ColorScheme*> ColorSchemeManager::allColorSchemes()
{
    if ( !_haveLoadedAll )
    {
        loadAllColorSchemes();
    }

    return _colorSchemes.values();
}
bool ColorSchemeManager::loadKDE3ColorScheme(const QString& filePath)
{
    QFile file(filePath);
    if (!filePath.endsWith(QLatin1String(".schema")) || !file.open(QIODevice::ReadOnly))
        return false;

    KDE3ColorSchemeReader reader(&file);
    ColorScheme* scheme = reader.read();
    scheme->setName(QFileInfo(file).baseName());
    file.close();

    if (scheme->name().isEmpty())
    {
        qDebug() << "color scheme name is not valid.";
        delete scheme;
        return false;
    }

    QFileInfo info(filePath);

    if ( !_colorSchemes.contains(info.baseName()) )
        _colorSchemes.insert(scheme->name(),scheme);
    else
    {
        qDebug() << "color scheme with name" << scheme->name() << "has already been" <<
            "found, ignoring.";
        delete scheme;
    }

    return true;
}
#if 0
void ColorSchemeManager::addColorScheme(ColorScheme* scheme)
{
    _colorSchemes.insert(scheme->name(),scheme);

    // save changes to disk
    QString path = KGlobal::dirs()->saveLocation("data","konsole/") + scheme->name() + ".colorscheme";
    KConfig config(path , KConfig::NoGlobals);

    scheme->write(config);
}
#endif
bool ColorSchemeManager::loadColorScheme(const QString& filePath)
{
    if ( !filePath.endsWith(QLatin1String(".colorscheme")) || !QFile::exists(filePath) )
        return false;

    QFileInfo info(filePath);

    ColorScheme* scheme = new ColorScheme();
    scheme->setName(info.baseName());
    scheme->read(filePath);

    if (scheme->name().isEmpty())
    {
        qDebug() << "Color scheme in" << filePath << "does not have a valid name and was not loaded.";
        delete scheme;
        return false;
    }

    if ( !_colorSchemes.contains(info.baseName()) )
    {
        _colorSchemes.insert(scheme->name(),scheme);
    }
    else
    {
        qDebug() << "color scheme with name" << scheme->name() << "has already been" <<
            "found, ignoring.";

        delete scheme;
    }

    return true;
}
QList<QString> ColorSchemeManager::listKDE3ColorSchemes()
{
    QString dname(get_color_schemes_dir());
    QDir dir(dname);
    QStringList filters;
    filters << "*.schema";
    dir.setNameFilters(filters);
    QStringList list = dir.entryList(filters);
    QStringList ret;
    foreach(QString i, list)
        ret << dname + "/" + i;
    return ret;
    //return KGlobal::dirs()->findAllResources("data",
    //                                         "konsole/*.schema",
    //                                          KStandardDirs::NoDuplicates);
    //
}
QList<QString> ColorSchemeManager::listColorSchemes()
{
    QString dname(get_color_schemes_dir());
    QDir dir(dname);
    QStringList filters;
    filters << "*.colorscheme";
    dir.setNameFilters(filters);
    QStringList list = dir.entryList(filters);
    QStringList ret;
    foreach(QString i, list)
        ret << dname + "/" + i;
    return ret;
//    return KGlobal::dirs()->findAllResources("data",
//                                             "konsole/*.colorscheme",
//                                             KStandardDirs::NoDuplicates);
}
const ColorScheme ColorSchemeManager::_defaultColorScheme;
const ColorScheme* ColorSchemeManager::defaultColorScheme() const
{
    return &_defaultColorScheme;
}
bool ColorSchemeManager::deleteColorScheme(const QString& name)
{
    Q_ASSERT( _colorSchemes.contains(name) );

    // lookup the path and delete
    QString path = findColorSchemePath(name);
    if ( QFile::remove(path) )
    {
        _colorSchemes.remove(name);
        return true;
    }
    else
    {
        qDebug() << "Failed to remove color scheme -" << path;
        return false;
    }
}
QString ColorSchemeManager::findColorSchemePath(const QString& name) const
{
//    QString path = KStandardDirs::locate("data","konsole/"+name+".colorscheme");
    QString path(get_color_schemes_dir() + "/"+ name + ".colorscheme");
    if ( !path.isEmpty() )
       return path;

    //path = KStandardDirs::locate("data","konsole/"+name+".schema");
    path = get_color_schemes_dir() + "/"+ name + ".schema";

    return path;
}
const ColorScheme* ColorSchemeManager::findColorScheme(const QString& name)
{
    if ( name.isEmpty() )
        return defaultColorScheme();

    if ( _colorSchemes.contains(name) )
        return _colorSchemes[name];
    else
    {
        // look for this color scheme
        QString path = findColorSchemePath(name);
        if ( !path.isEmpty() && loadColorScheme(path) )
        {
            return findColorScheme(name);
        }
        else
        {
            if (!path.isEmpty() && loadKDE3ColorScheme(path))
                return findColorScheme(name);
        }

        qDebug() << "Could not find color scheme - " << name;

        return 0;
    }
}

ColorSchemeManager* ColorSchemeManager::theColorSchemeManager = 0;
//K_GLOBAL_STATIC( ColorSchemeManager , theColorSchemeManager )
ColorSchemeManager* ColorSchemeManager::instance()
{
    if (! theColorSchemeManager)
        theColorSchemeManager = new ColorSchemeManager();
    return theColorSchemeManager;
}
