/*******************************************************************************
* Small read-only bridge that lets QML ask the terminal widget where its
* cursor is.
*
* Why this exists: the line-highlight feature has to know which row of the
* screen the cursor sits on.  QMLTermWidget (a thin registration of
* Konsole::TerminalDisplay) exposes no such property, but QQuickItem's
* inputMethodQuery() is a *public virtual*, so an item in our own process can
* simply ask it.  That keeps the change entirely inside this application: the
* qmltermwidget submodule stays byte-for-byte identical to upstream.
*
* The query is refused unless the item actually owns the keyboard focus, so a
* settings dialog in the foreground can never make a background terminal
* highlight some arbitrary row.
*******************************************************************************/
#ifndef TERMQUERY_H
#define TERMQUERY_H

#include <QObject>
#include <QRectF>

class TermQuery : public QObject
{
    Q_OBJECT

public:
    explicit TermQuery(QObject *parent = nullptr);

    /**
     * True when \p item owns the keyboard focus, directly or through one of
     * its children.
     */
    Q_INVOKABLE bool ownsFocus(QObject *item) const;

    /**
     * Rectangle of the cursor cell in \p item's own coordinate system.
     * An empty rectangle is returned when the widget does not report a cursor,
     * when input methods are unavailable, or when \p item is not focused.
     */
    Q_INVOKABLE QRectF cursorRectangle(QObject *item) const;
};

#endif // TERMQUERY_H
