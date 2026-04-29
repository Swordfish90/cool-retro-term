#ifndef FONTLISTMODEL_H
#define FONTLISTMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QVariant>
#include <QVariantMap>
#include <QString>

struct FontEntry
{
    QString name;
    QString text;
    QString source;
    qreal baseWidth = 1.0;
    int pixelSize = 0;
    bool lowResolutionFont = false;
    bool isSystemFont = false;
    QString family;
    QString fallbackName;
};

class FontListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit FontListModel(QObject *parent = nullptr);

    enum Roles {
        NameRole = Qt::UserRole + 1,
        TextRole,
        SourceRole,
        BaseWidthRole,
        PixelSizeRole,
        LowResolutionRole,
        IsSystemRole,
        FamilyRole,
        FallbackNameRole
    };

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setFonts(const QVector<FontEntry> &fonts);
    const QVector<FontEntry> &fonts() const;

    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void countChanged();

private:
    QVector<FontEntry> m_fonts;
};

#endif // FONTLISTMODEL_H
