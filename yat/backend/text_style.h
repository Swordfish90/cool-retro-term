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

class Text;
class TextStyleLine : public TextStyle {
public:
    TextStyleLine(const TextStyle &style, int start_index, int end_index)
        : TextStyle(style)
        , start_index(start_index)
        , end_index(end_index)
        , old_index(-1)
        , text_segment(0)
        , style_dirty(true)
        , index_dirty(true)
        , text_dirty(true)
    {
    }

    TextStyleLine()
        : start_index(0)
        , end_index(0)
        , old_index(-1)
        , text_segment(0)
        , style_dirty(false)
        , index_dirty(false)
        , text_dirty(false)
    {

    }

    void releaseTextSegment(Screen *screen);

    int start_index;
    int end_index;

    int old_index;
    Text *text_segment;
    bool style_dirty;
    bool index_dirty;
    bool text_dirty;

    void setStyle(const TextStyle &style) {
        forground = style.forground;
        background = style.background;
        this->style = style.style;
    }
};
QDebug operator<<(QDebug debug, TextStyleLine line);


#endif // TEXT_STYLE_H
