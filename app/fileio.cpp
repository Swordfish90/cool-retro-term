#include "fileio.h"

#include <QDir>
#include <QStandardPaths>

FileIO::FileIO()
{
}

bool FileIO::write(const QString& sourceUrl, const QString& data) {
    if (sourceUrl.isEmpty())
        return false;

    QUrl url(sourceUrl);
    QFile file(url.toLocalFile());
    if (!file.open(QFile::WriteOnly | QFile::Truncate))
        return false;

    QTextStream out(&file);
    out << data;
    file.close();
    return true;
}

QString FileIO::read(const QString& sourceUrl) {
    if (sourceUrl.isEmpty())
        return "";

    QUrl url(sourceUrl);
    QFile file(url.toLocalFile());
    if (!file.open(QFile::ReadOnly))
        return "";

    QTextStream in(&file);
    QString result = in.readAll();

    file.close();

    return result;
}

QString FileIO::toLocalFile(const QString& sourceUrl) {
    if (sourceUrl.isEmpty())
        return QString();

    const QUrl url(sourceUrl);
    QString path = url.isLocalFile() ? url.toLocalFile() : QString();
    if (path.isEmpty() && sourceUrl.startsWith(QLatin1Char('/')))
        path = sourceUrl;
    if (path.isEmpty())
        path = url.toLocalFile();
    if (path.isEmpty())
        path = sourceUrl;

    // Qt Quick FileDialog may prefix currentFolder when the typed name is
    // already absolute, producing "/cwd//abs/path.png".
    const int dbl = path.indexOf(QLatin1String("//"), 1);
    if (dbl > 0) {
        const QString embedded = path.mid(dbl + 1);
        if (embedded.startsWith(QLatin1Char('/')))
            path = embedded;
    }
    return path;
}

QString FileIO::writableFolderUrl() {
    QString dir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (dir.isEmpty())
        dir = QDir::homePath();
    QDir().mkpath(dir);
    return QUrl::fromLocalFile(dir).toString();
}

QString FileIO::suggestedSaveUrl(const QString& fileName) {
    const QUrl folder(writableFolderUrl());
    const QString name = fileName.isEmpty() ? QStringLiteral("crt-frame.png") : fileName;
    return QUrl::fromLocalFile(QDir(folder.toLocalFile()).filePath(name)).toString();
}

bool FileIO::writePng(const QString& sourceUrl, const QVariant& image) {
    const QString path = toLocalFile(sourceUrl);
    const QImage png = image.value<QImage>();
    if (path.isEmpty() || png.isNull())
        return false;

    return png.save(path, "PNG");
}
