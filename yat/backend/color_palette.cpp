#include "color_palette.h"

ColorPalette::ColorPalette()
    : m_normalColors(numberOfColors)
    , m_lightColors(numberOfColors)
    , m_intenseColors(numberOfColors)
{
    m_normalColors[0].setRgb(0,0,0);
    m_normalColors[1].setRgb(194,54,33);
    m_normalColors[2].setRgb(37,188,36);
    m_normalColors[3].setRgb(173,173,39);
    m_normalColors[4].setRgb(63,84,255);
    m_normalColors[5].setRgb(211,56,211);
    m_normalColors[6].setRgb(51,187,199);
    m_normalColors[7].setRgb(229,229,229);
    m_normalColors[8].setRgb(178,178,178);
    m_normalColors[9].setAlpha(0);

    m_lightColors[0].setRgb(129,131,131);
    m_lightColors[1].setRgb(252,57,31);
    m_lightColors[2].setRgb(49,231,34);
    m_lightColors[3].setRgb(234,236,35);
    m_lightColors[4].setRgb(88,51,255);
    m_lightColors[5].setRgb(249,53,248);
    m_lightColors[6].setRgb(20,240,240);
    m_lightColors[7].setRgb(233,233,233);
    m_lightColors[8].setRgb(220,220,220);
    m_lightColors[9].setRgb(50,50,50);

}

QColor ColorPalette::color(ColorPalette::Color color, bool bold) const
{
    if (bold)
        return m_lightColors.at(color);

    return m_normalColors.at(color);
}

QColor ColorPalette::normalColor(ColorPalette::Color color) const
{
    return m_normalColors.at(color);
}

QColor ColorPalette::lightColor(ColorPalette::Color color) const
{
    return m_lightColors.at(color);
}

