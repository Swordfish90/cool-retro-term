#ifndef MONOSPACEFONTMANAGER_H
#define MONOSPACEFONTMANAGER_H

#include <QObject>
#include <QFontDatabase>
#include <QStringList>

class MonospaceFontManager : public QObject
{
    Q_OBJECT
public:
    explicit MonospaceFontManager(QObject *parent = nullptr);
    Q_INVOKABLE QStringList retrieveMonospaceFonts();

public slots:
    Q_INVOKABLE void setFontSubstitutions(const QString &family, const QStringList &substitutes);
    void removeFontSubstitution(const QString &family);
};

#endif // MONOSPACEFONTMANAGER_H
