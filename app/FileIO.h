#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QUrl>

class FileIO : public QObject
{
    Q_OBJECT

public:
    FileIO() {}

public slots:
    bool write(const QString& sourceUrl, const QString& data) {
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

    QString read(const QString& sourceUrl) {
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
};

#endif // FILEIO_H
