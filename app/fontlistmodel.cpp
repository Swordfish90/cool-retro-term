#include "fontlistmodel.h"

FontListModel::FontListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FontListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_fonts.size();
}

QVariant FontListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_fonts.size()) {
        return QVariant();
    }

    const FontEntry &font = m_fonts.at(index.row());

    switch (role) {
    case NameRole:
        return font.name;
    case TextRole:
        return font.text;
    case SourceRole:
        return font.source;
    case BaseWidthRole:
        return font.baseWidth;
    case PixelSizeRole:
        return font.pixelSize;
    case LowResolutionRole:
        return font.lowResolutionFont;
    case IsSystemRole:
        return font.isSystemFont;
    case FamilyRole:
        return font.family;
    case FallbackNameRole:
        return font.fallbackName;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FontListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[TextRole] = "text";
    roles[SourceRole] = "source";
    roles[BaseWidthRole] = "baseWidth";
    roles[PixelSizeRole] = "pixelSize";
    roles[LowResolutionRole] = "lowResolutionFont";
    roles[IsSystemRole] = "isSystemFont";
    roles[FamilyRole] = "family";
    roles[FallbackNameRole] = "fallbackName";
    return roles;
}

void FontListModel::setFonts(const QVector<FontEntry> &fonts)
{
    beginResetModel();
    m_fonts = fonts;
    endResetModel();
    emit countChanged();
}

const QVector<FontEntry> &FontListModel::fonts() const
{
    return m_fonts;
}

QVariantMap FontListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_fonts.size()) {
        return map;
    }

    const FontEntry &font = m_fonts.at(index);
    map.insert("name", font.name);
    map.insert("text", font.text);
    map.insert("source", font.source);
    map.insert("baseWidth", font.baseWidth);
    map.insert("pixelSize", font.pixelSize);
    map.insert("lowResolutionFont", font.lowResolutionFont);
    map.insert("isSystemFont", font.isSystemFont);
    map.insert("family", font.family);
    map.insert("fallbackName", font.fallbackName);
    return map;
}
