#ifndef COLOR_PALETTE_H
#define COLOR_PALETTE_H

#include <QtCore/QVector>

#include <QtGui/QColor>

class ColorPalette : public QObject
{
Q_OBJECT
public:
    ColorPalette(QObject *parent = 0);

    enum Color {
        Black,
        Red,
        Green,
        Yellow,
        Blue,
        Magenta,
        Cyan,
        White,
        DefaultForground,
        DefaultBackground,
        numberOfColors
    };

    QColor color(Color color, bool bold) const;
    QColor normalColor(Color color) const;
    QColor lightColor(Color color) const;

    void setInverseDefaultColors(bool inverse);
signals:
    void changed();
private:
    QVector<QColor> m_normalColors;
    QVector<QColor> m_lightColors;
    QVector<QColor> m_intenseColors;

    bool m_inverse_default;
};

#endif // COLOR_PALETTE_H
