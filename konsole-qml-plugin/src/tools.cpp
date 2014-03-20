#include "tools.h"

#include <QCoreApplication>
#include <QDir>
#include <QtDebug>


/*! Helper function to get possible location of layout files.
By default the KB_LAYOUT_DIR is used (linux/BSD/macports).
But in some cases (apple bundle) there can be more locations).
*/
QString get_kb_layout_dir()
{
//    qDebug() << __FILE__ << __FUNCTION__;

    QString rval = "";
    QString k(getenv("KB_LAYOUT_DIR"));
    QDir d(k);

//    qDebug() << "default KB_LAYOUT_DIR: " << k;

    if (d.exists())
        rval =  k.append("/");

    // subdir in the app location
    d.setPath(QCoreApplication::applicationDirPath() + "/kb-layouts/");
    //qDebug() << d.path();
    if (d.exists())
        rval = QCoreApplication::applicationDirPath() + "/kb-layouts/";
#ifdef Q_WS_MAC
    d.setPath(QCoreApplication::applicationDirPath() + "/../Resources/kb-layouts/");
    if (d.exists())
        rval = QCoreApplication::applicationDirPath() + "/../Resources/kb-layouts/";
#endif
#ifdef QT_DEBUG
    if(!rval.isEmpty()) {
        qDebug() << "Using kb-layouts: " << rval;
    } else {
        qDebug() << "Cannot find kb-layouts in any location!";
    }
#endif
    return rval;
}

/*! Helper function to get possible location of layout files.
By default the COLORSCHEMES_DIR is used (linux/BSD/macports).
But in some cases (apple bundle) there can be more locations).
*/
QString get_color_schemes_dir()
{
//    qDebug() << __FILE__ << __FUNCTION__;

    QString rval = "";
    QString k(getenv("COLORSCHEMES_DIR"));
    QDir d(k);

//    qDebug() << "default COLORSCHEMES_DIR: " << k;

    if (d.exists())
        rval =  k.append("/");

    // subdir in the app location
    d.setPath(QCoreApplication::applicationDirPath() + "/color-schemes/");
    //qDebug() << d.path();
    if (d.exists())
        rval = QCoreApplication::applicationDirPath() + "/color-schemes/";
#ifdef Q_WS_MAC
    d.setPath(QCoreApplication::applicationDirPath() + "/../Resources/color-schemes/");
    if (d.exists())
        rval = QCoreApplication::applicationDirPath() + "/../Resources/color-schemes/";
#endif
#ifdef QT_DEBUG
    if(!rval.isEmpty()) {
        qDebug() << "Using color-schemes: " << rval;
    } else {
        qDebug() << "Cannot find color-schemes in any location!";
    }
#endif
    return rval;
}
