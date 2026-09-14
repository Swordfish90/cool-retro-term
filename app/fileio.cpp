#include "fileio.h"

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
    if (url.isLocalFile())
        return url.toLocalFile();

    if (sourceUrl.startsWith(QLatin1Char('/')))
        return sourceUrl;

    const QString local = url.toLocalFile();
    return local.isEmpty() ? sourceUrl : local;
}

bool FileIO::writePng(const QString& sourceUrl, const QVariant& image) {
    const QString path = toLocalFile(sourceUrl);
    const QImage png = image.value<QImage>();
    if (path.isEmpty() || png.isNull())
        return false;

    return png.save(path, "PNG");
}
