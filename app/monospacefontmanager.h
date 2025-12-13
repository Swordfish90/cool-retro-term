#ifndef MONOSPACEFONTMANAGER_H
#define MONOSPACEFONTMANAGER_H

#include <QObject>
#include <QFontDatabase>

class MonospaceFontManager : public QObject
{
    Q_OBJECT
public:
    explicit MonospaceFontManager(QObject *parent = nullptr);
    Q_INVOKABLE QStringList retrieveMonospaceFonts();

public slots:
    void setFontSubstitution(const QString &family, const QString &substitute);
    void removeFontSubstitution(const QString &family);
};

#endif // MONOSPACEFONTMANAGER_H
