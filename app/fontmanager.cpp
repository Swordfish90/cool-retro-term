#include "fontmanager.h"

#include <QFont>
#include <QFontDatabase>
#include <QFontMetricsF>
#include <QtGlobal>
#include <QtMath>

namespace {
constexpr int kModernRasterization = 4;
constexpr int kBaseFontPixelHeight = 32;
constexpr int kSystemFontPixelSize = 32;
}

FontManager::FontManager(QObject *parent)
    : QObject(parent)
    , m_fontListModel(this)
    , m_filteredFontListModel(this)
{
    populateBundledFonts();
    populateSystemFonts();
    m_fontListModel.setFonts(m_allFonts);
    updateFilteredFonts();
    updateComputedFont();
}

QStringList FontManager::retrieveMonospaceFonts()
{
    QStringList result;

    QFontDatabase fontDatabase;
    const QStringList fontFamilies = fontDatabase.families();

    for (const QString &fontFamily : fontFamilies) {
        QFont font(fontFamily);
        if (fontDatabase.isFixedPitch(font.family())) {
            result.append(fontFamily);
        }
    }

    return result;
}

void FontManager::refresh()
{
    updateFilteredFonts();
    updateComputedFont();
}

FontListModel *FontManager::fontList()
{
    return &m_fontListModel;
}

FontListModel *FontManager::filteredFontList()
{
    return &m_filteredFontListModel;
}

int FontManager::fontSource() const
{
    return m_fontSource;
}

void FontManager::setFontSource(int fontSource)
{
    if (m_fontSource == fontSource) {
        return;
    }
    m_fontSource = fontSource;
    emit fontSourceChanged();
    updateFilteredFonts();
    updateComputedFont();
}

int FontManager::rasterization() const
{
    return m_rasterization;
}

void FontManager::setRasterization(int rasterization)
{
    if (m_rasterization == rasterization) {
        return;
    }
    m_rasterization = rasterization;
    emit rasterizationChanged();
    updateFilteredFonts();
    updateComputedFont();
}

QString FontManager::fontName() const
{
    return m_fontName;
}

void FontManager::setFontName(const QString &fontName)
{
    if (m_fontName == fontName) {
        return;
    }
    m_fontName = fontName;
    emit fontNameChanged();
    updateFilteredFonts();
    updateComputedFont();
}

qreal FontManager::fontScaling() const
{
    return m_fontScaling;
}

void FontManager::setFontScaling(qreal fontScaling)
{
    if (qFuzzyCompare(m_fontScaling, fontScaling)) {
        return;
    }
    m_fontScaling = fontScaling;
    emit fontScalingChanged();
    updateComputedFont();
}

qreal FontManager::fontWidth() const
{
    return m_fontWidth;
}

void FontManager::setFontWidth(qreal fontWidth)
{
    if (qFuzzyCompare(m_fontWidth, fontWidth)) {
        return;
    }
    m_fontWidth = fontWidth;
    emit fontWidthChanged();
    updateComputedFont();
}

qreal FontManager::lineSpacing() const
{
    return m_lineSpacing;
}

void FontManager::setLineSpacing(qreal lineSpacing)
{
    if (qFuzzyCompare(m_lineSpacing, lineSpacing)) {
        return;
    }
    m_lineSpacing = lineSpacing;
    emit lineSpacingChanged();
    updateComputedFont();
}

qreal FontManager::baseFontScaling() const
{
    return m_baseFontScaling;
}

void FontManager::setBaseFontScaling(qreal baseFontScaling)
{
    if (qFuzzyCompare(m_baseFontScaling, baseFontScaling)) {
        return;
    }
    m_baseFontScaling = baseFontScaling;
    emit baseFontScalingChanged();
    updateComputedFont();
}

bool FontManager::lowResolutionFont() const
{
    return m_lowResolutionFont;
}

void FontManager::setFontSubstitutions(const QString &family, const QStringList &substitutes)
{
    if (family.isEmpty()) {
        return;
    }

    QFont::removeSubstitutions(family);

    if (substitutes.isEmpty()) {
        return;
    }

    QFont::insertSubstitutions(family, substitutes);
}

void FontManager::removeFontSubstitution(const QString &family)
{
    if (family.isEmpty()) {
        return;
    }

    QFont::removeSubstitutions(family);
}

void FontManager::populateBundledFonts()
{
    m_allFonts.clear();

    addBundledFont(
        "TERMINESS_SCALED",
        "Terminess",
        ":/fonts/terminus/TerminessNerdFontMono-Regular.ttf",
        1.0,
        12,
        true);
    addBundledFont(
        "BIGBLUE_TERMINAL_SCALED",
        "BigBlue Terminal",
        ":/fonts/bigblue-terminal/BigBlueTerm437NerdFontMono-Regular.ttf",
        1.0,
        12,
        true);
    addBundledFont(
        "EXCELSIOR_SCALED",
        "Fixedsys Excelsior",
        ":/fonts/fixedsys-excelsior/FSEX301-L2.ttf",
        1.0,
        16,
        true,
        "UNSCII_16_SCALED");
    addBundledFont(
        "GREYBEARD_SCALED",
        "Greybeard",
        ":/fonts/greybeard/Greybeard-16px.ttf",
        1.0,
        16,
        true,
        "UNSCII_16_SCALED");
    addBundledFont(
        "COMMODORE_PET_SCALED",
        "Commodore PET",
        ":/fonts/pet-me/PetMe.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "GOHU_11_SCALED",
        "Gohu 11",
        ":/fonts/gohu/GohuFont11NerdFontMono-Regular.ttf",
        1.0,
        11,
        true);
    addBundledFont(
        "COZETTE_SCALED",
        "Cozette",
        ":/fonts/cozette/CozetteVector.ttf",
        1.0,
        13,
        true);
    addBundledFont(
        "UNSCII_8_SCALED",
        "Unscii 8",
        ":/fonts/unscii/unscii-8.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "UNSCII_8_THIN_SCALED",
        "Unscii 8 Thin",
        ":/fonts/unscii/unscii-8-thin.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "UNSCII_16_SCALED",
        "Unscii 16",
        ":/fonts/unscii/unscii-16-full.ttf",
        1.0,
        16,
        true,
        "UNSCII_16_SCALED");
    addBundledFont(
        "APPLE_II_SCALED",
        "Apple ][",
        ":/fonts/apple2/PrintChar21.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "ATARI_400_SCALED",
        "Atari 400-800",
        ":/fonts/atari-400-800/AtariClassic-Regular.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "COMMODORE_64_SCALED",
        "Commodore 64",
        ":/fonts/pet-me/PetMe64.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "IBM_EGA_8x8",
        "IBM EGA 8x8",
        ":/fonts/oldschool-pc-fonts/PxPlus_IBM_EGA_8x8.ttf",
        0.5,
        8,
        true,
        "UNSCII_8_SCALED");
    addBundledFont(
        "IBM_VGA_8x16",
        "IBM VGA 8x16",
        ":/fonts/oldschool-pc-fonts/PxPlus_IBM_VGA_8x16.ttf",
        1.0,
        16,
        true,
        "UNSCII_16_SCALED");

    addBundledFont(
        "TERMINESS",
        "Terminess",
        ":/fonts/terminus/TerminessNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "HACK",
        "Hack",
        ":/fonts/hack/HackNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "FIRA_CODE",
        "Fira Code",
        ":/fonts/fira-code/FiraCodeNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "IOSEVKA",
        "Iosevka",
        ":/fonts/iosevka/IosevkaTermNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "JETBRAINS_MONO",
        "JetBrains Mono",
        ":/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "IBM_3278",
        "IBM 3278",
        ":/fonts/ibm-3278/3270NerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "SOURCE_CODE_PRO",
        "Source Code Pro",
        ":/fonts/source-code-pro/SauceCodeProNerdFontMono-Regular.ttf",
        1.0,
        32,
        false);
    addBundledFont(
        "DEPARTURE_MONO_SCALED",
        "Departure Mono",
        ":/fonts/departure-mono/DepartureMonoNerdFontMono-Regular.otf",
        1.0,
        11,
        true);
    addBundledFont(
        "OPENDYSLEXIC",
        "OpenDyslexic",
        ":/fonts/opendyslexic/OpenDyslexicMNerdFontMono-Regular.otf",
        1.0,
        32,
        false);
}

void FontManager::addBundledFont(const QString &name,
                                 const QString &text,
                                 const QString &source,
                                 qreal baseWidth,
                                 int pixelSize,
                                 bool lowResolutionFont,
                                 const QString &fallbackName)
{
    FontEntry entry;
    entry.name = name;
    entry.text = text;
    entry.source = source;
    entry.pixelSize = pixelSize;
    entry.lowResolutionFont = lowResolutionFont;
    entry.isSystemFont = false;
    entry.fallbackName = fallbackName;
    entry.family = resolveFontFamily(source);
    entry.baseWidth = lowResolutionFont
        ? computeBaseWidth(entry.family, pixelSize, baseWidth)
        : baseWidth;
    m_allFonts.append(entry);
}

void FontManager::populateSystemFonts()
{
    const QStringList families = retrieveMonospaceFonts();
    for (const QString &family : families) {
        if (m_bundledFamilies.contains(family)) {
            continue;
        }
        FontEntry entry;
        entry.name = family;
        entry.text = family;
        entry.source = QString();
        entry.baseWidth = 1.0;
        entry.pixelSize = kSystemFontPixelSize;
        entry.lowResolutionFont = false;
        entry.isSystemFont = true;
        entry.family = family;
        m_allFonts.append(entry);
    }
}

void FontManager::updateFilteredFonts()
{
    QVector<FontEntry> filtered;
    bool fontNameFound = false;
    const bool modernMode = (m_rasterization == kModernRasterization);

    for (const FontEntry &font : m_allFonts) {
        const bool isBundled = !font.isSystemFont;
        const bool matchesSource = (m_fontSource == 0 && isBundled)
            || (m_fontSource == 1 && font.isSystemFont);

        if (!matchesSource) {
            continue;
        }

        const bool matchesRasterization = font.isSystemFont
            || (modernMode == !font.lowResolutionFont);

        if (!matchesRasterization) {
            continue;
        }

        filtered.append(font);
        if (font.name == m_fontName) {
            fontNameFound = true;
        }
    }

    if (!fontNameFound && !filtered.isEmpty()) {
        if (m_fontName != filtered.first().name) {
            m_fontName = filtered.first().name;
            emit fontNameChanged();
        }
    }

    m_filteredFontListModel.setFonts(filtered);
    emit filteredFontListChanged();
}

void FontManager::updateComputedFont()
{
    const FontEntry *font = findFontByName(m_fontName);
    if (!font) {
        const QVector<FontEntry> &filteredFonts = m_filteredFontListModel.fonts();
        if (!filteredFonts.isEmpty()) {
            font = &filteredFonts.first();
        }
    }

    if (!font) {
        return;
    }

    const qreal totalFontScaling = m_baseFontScaling * m_fontScaling;
    const qreal targetPixelHeight = kBaseFontPixelHeight * totalFontScaling;
    const qreal lineSpacingFactor = m_lineSpacing;

    const int lineSpacing = qRound(targetPixelHeight * lineSpacingFactor);
    const int pixelSize = font->lowResolutionFont
        ? font->pixelSize
        : static_cast<int>(targetPixelHeight);

    const qreal nativeLineHeight = font->pixelSize + qRound(font->pixelSize * lineSpacingFactor);
    const qreal targetLineHeight = targetPixelHeight + lineSpacing;
    const qreal screenScaling = font->lowResolutionFont
        ? (nativeLineHeight > 0 ? targetLineHeight / nativeLineHeight : 1.0)
        : 1.0;

    const qreal fontWidth = font->baseWidth * m_fontWidth;

    QString fontFamily = font->family.isEmpty() ? font->name : font->family;
    QString fallbackFontFamily;

    if (!font->fallbackName.isEmpty() && font->fallbackName != font->name) {
        const FontEntry *fallback = findFontByName(font->fallbackName);
        if (fallback) {
            fallbackFontFamily = fallback->family.isEmpty() ? fallback->name : fallback->family;
        }
    }

    QStringList fallbackChain;
    if (!fallbackFontFamily.isEmpty()) {
        fallbackChain.append(fallbackFontFamily);
    }
#if defined(Q_OS_MAC)
    fallbackChain.append(QStringLiteral("Menlo"));
#else
    fallbackChain.append(QStringLiteral("Monospace"));
#endif
    setFontSubstitutions(fontFamily, fallbackChain);

    if (m_lowResolutionFont != font->lowResolutionFont) {
        m_lowResolutionFont = font->lowResolutionFont;
        emit lowResolutionFontChanged();
    }

    emit terminalFontChanged(fontFamily,
                             pixelSize,
                             lineSpacing,
                             screenScaling,
                             fontWidth,
                             fallbackFontFamily,
                             font->lowResolutionFont);
}

const FontEntry *FontManager::findFontByName(const QString &name) const
{
    for (const FontEntry &font : m_allFonts) {
        if (font.name == name) {
            return &font;
        }
    }
    return nullptr;
}

QString FontManager::resolveFontFamily(const QString &sourcePath)
{
    const auto cached = m_loadedFamilies.constFind(sourcePath);
    if (cached != m_loadedFamilies.constEnd()) {
        return cached.value();
    }

    const int fontId = QFontDatabase::addApplicationFont(sourcePath);
    QString family;
    if (fontId != -1) {
        const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) {
            family = families.first();
        }
    }

    if (!family.isEmpty()) {
        m_bundledFamilies.insert(family);
    }

    m_loadedFamilies.insert(sourcePath, family);
    return family;
}

qreal FontManager::computeBaseWidth(const QString &family, int pixelSize, qreal fallbackWidth) const
{
    if (family.isEmpty()) {
        return fallbackWidth;
    }

    QFont font(family);
    font.setPixelSize(pixelSize);
    QFontMetricsF metrics(font);

    const qreal glyphWidth = metrics.horizontalAdvance(QLatin1String("M"));
    const qreal glyphHeight = metrics.height();
    if (glyphWidth <= 0.0 || glyphHeight <= 0.0) {
        return fallbackWidth;
    }

    const qreal targetRatio = 0.5;
    qreal computedWidth = (targetRatio * glyphHeight) / glyphWidth;
    return qBound(0.25, computedWidth, 2.0);
}
