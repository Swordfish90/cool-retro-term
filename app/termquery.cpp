#include "termquery.h"

#include <QGuiApplication>
#include <QQuickItem>
#include <QVariant>

namespace {

bool isSelfOrAncestor(QObject *candidate, QObject *focus)
{
    if (!candidate || !focus)
        return false;

    for (QObject *current = focus; current; current = current->parent()) {
        if (current == candidate)
            return true;
    }
    return false;
}

} // namespace

TermQuery::TermQuery(QObject *parent)
    : QObject(parent)
{
}

bool TermQuery::ownsFocus(QObject *item) const
{
    return isSelfOrAncestor(item, QGuiApplication::focusObject());
}

QRectF TermQuery::cursorRectangle(QObject *item) const
{
    if (!ownsFocus(item))
        return QRectF();

    QQuickItem *quickItem = qobject_cast<QQuickItem *>(item);
    if (!quickItem)
        return QRectF();

#if QT_CONFIG(im)
    // Konsole::TerminalDisplay answers ImCursorRectangle with the cursor cell
    // mapped into widget coordinates.
    const QVariant value = quickItem->inputMethodQuery(Qt::ImCursorRectangle);
    if (!value.isValid())
        return QRectF();

    if (value.canConvert<QRect>())
        return QRectF(value.toRect());
    if (value.canConvert<QRectF>())
        return value.toRectF();
#endif

    return QRectF();
}
