#ifndef TEXT_STYLE_H
#define TEXT_STYLE_H

#include <QtGui/QColor>

#include "color_palette.h"
class Screen;

class TextStyle
{
public:
    enum Style {
        Normal            = 0x0000,
        Italic            = 0x0001,
        Bold              = 0x0002,
        Underlined        = 0x0004,
        Blinking          = 0x0008,
        FastBlinking      = 0x0010,
        Gothic            = 0x0020,
        DoubleUnderlined  = 0x0040,
        Framed            = 0x0080,
        Overlined         = 0x0100,
        Encircled         = 0x0200,
        Inverse           = 0x0400
    };
    Q_DECLARE_FLAGS(Styles, Style)

    TextStyle();

    Styles style;
    ColorPalette::Color forground;
    ColorPalette::Color background;

    bool isCompatible(const TextStyle &other) const;
};

#endif // TEXT_STYLE_H
