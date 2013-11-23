#include "text_style.h"

#include <QtCore/QDebug>

TextStyle::TextStyle()
    : style(Normal)
    , forground(ColorPalette::DefaultForground)
    , background(ColorPalette::DefaultBackground)
{

}
bool TextStyle::isCompatible(const TextStyle &other) const
{
    return forground == other.forground
            && background == other.background
            && style == other.style;
}
