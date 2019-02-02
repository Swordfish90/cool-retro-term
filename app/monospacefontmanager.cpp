#include "monospacefontmanager.h"

#include <QDebug>

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
