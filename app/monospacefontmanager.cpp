#include "monospacefontmanager.h"

#include <QDebug>
#include <QFont>

MonospaceFontManager::MonospaceFontManager(QObject *parent) : QObject(parent)
{

}

QStringList MonospaceFontManager::retrieveMonospaceFonts() {
    QStringList result;

    QFontDatabase fontDatabase;
    QStringList fontFamilies = fontDatabase.families();

    for (int i = 0; i < fontFamilies.size(); i++) {
        QString fontFamily = fontFamilies[i];
        QFont font(fontFamily);
        if (fontDatabase.isFixedPitch(font.family())) {
            result.append(fontFamily);
        }
    }

    return result;
}

void MonospaceFontManager::setFontSubstitution(const QString &family, const QString &substitute)
{
    if (family.isEmpty() || substitute.isEmpty()) {
        return;
    }

    QFont::removeSubstitutions(family);
    QFont::insertSubstitution(family, substitute);
}

void MonospaceFontManager::removeFontSubstitution(const QString &family)
{
    if (family.isEmpty()) {
        return;
    }

    QFont::removeSubstitutions(family);
}
