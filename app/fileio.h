#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QFile>
#include <QImage>
#include <QTextStream>
#include <QUrl>
#include <QVariant>

class FileIO : public QObject
{
    Q_OBJECT

public:
    FileIO();

public slots:
    bool write(const QString& sourceUrl, const QString& data);
    QString read(const QString& sourceUrl);
    QString toLocalFile(const QString& sourceUrl);
    QString writableFolderUrl();
    QString suggestedSaveUrl(const QString& fileName);
    bool writePng(const QString& sourceUrl, const QVariant& image);
};

#endif // FILEIO_H
