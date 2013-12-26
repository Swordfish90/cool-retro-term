#include "../../../backend/block.h"
#include <QtTest/QtTest>

#include <QtQml/QQmlEngine>
#include "../../../backend/screen.h"
#include "../../../backend/screen_data.h"

class BlockHandler
{
public:
    BlockHandler(bool fill) {
        screen.setHeight(5);
        int width = 100;
        screen.setWidth(width);
        (*screen.currentScreenData()->it_for_row(0))->clear();
        if (fill) {
            QString spaces(width, QChar(' '));
            block()->replaceAtPos(0, spaces, screen.defaultTextStyle());
        }
        QCOMPARE(block()->style_list().size(), 1);
        default_style = block()->style_list().at(0);
        default_text_style = default_style.style;
    }

    Block *block() const
    {
        return *screen.currentScreenData()->it_for_row(0);
    }

    void doneChanges()
    {
        screen.dispatchChanges();
    }

    TextStyle default_style;
    TextStyle::Styles default_text_style;
    Screen screen;
};

class tst_Block: public QObject
{
    Q_OBJECT

private slots:
    void replaceStart();
    void replaceEdgeOfStyle();
    void replaceCompatibleStyle();
    void replaceCompatiblePreviousStyle();
    void replaceCompatiblePreviousStyleShouldRemove();
    void replaceCompatibleCurrentStyleShouldRemove();
    void replaceIncompatibleStyle();
    void replaceIncompaitibleStylesCrossesBoundary();
    void replace3IncompatibleStyles();
    void replaceIncomaptibleStylesCrosses2Boundaries();
    void replaceIncompatibleColor();
    void replaceRemoveOverlappedStyles();
    void replaceSwapStyles();
    void replaceEndBlock();
    void clearBlock();
    void clearToEndOfBlock1Segment();
    void clearToEndOfBlock3Segment();
    void clearToEndOfBlockMiddle3Segment();
    void deleteCharacters1Segment();
    void deleteCharacters2Segments();
    void deleteCharacters3Segments();
    void deleteCharactersRemoveSegmentEnd();
    void deleteCharactersRemoveSegmentBeginning();
    void deleteCharactersRemoveMiddle();
    void insertCharacters();
    void insertCharacters2Segments();
    void insertCharacters3Segments();
};

void tst_Block::replaceStart()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QVector<TextStyleLine> old_style_list = block->style_list();
    QCOMPARE(old_style_list.size(), 1);

    QString replace_text("This is a test");
    TextStyle textStyle;
    textStyle.style = TextStyle::Overlined;
    block->replaceAtPos(0,replace_text, textStyle);

    QVector<TextStyleLine> new_style_list = block->style_list();
    TextStyleLine first_style = new_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);
    QCOMPARE(new_style_list.size(), 2);

}

void tst_Block::replaceEdgeOfStyle()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("This is the First");
    TextStyle textStyle;
    textStyle.style = TextStyle::Overlined;
    block->replaceAtPos(0,first_text, textStyle);

    QString second_text("This is the Second");
    textStyle.style = TextStyle::Bold;
    block->replaceAtPos(first_text.size(), second_text, textStyle);

    QVector<TextStyleLine> style_list = block->style_list();

    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.style, TextStyle::Overlined);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, first_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.style, TextStyle::Bold);
    QCOMPARE(second_style.start_index, first_text.size());
    QCOMPARE(second_style.end_index, first_text.size()+ second_text.size() - 1);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.style, TextStyle::Normal);
    QCOMPARE(third_style.start_index, first_text.size()+ second_text.size());
}

void tst_Block::replaceCompatibleStyle()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceed Text");
    block->replaceAtPos(10, replace_text, blockHandler.default_style);

    QVector<TextStyleLine> after_style_list = block->style_list();
    QCOMPARE(after_style_list.size(), 1);
    QCOMPARE(after_style_list.at(0).style, blockHandler.default_text_style);
}

void tst_Block::replaceCompatiblePreviousStyle()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    TextStyle first_style = blockHandler.default_style;
    first_style.style = TextStyle::Blinking;
    QString first_text("first");
    block->replaceAtPos(0,first_text, first_style);

    TextStyle second_style = blockHandler.default_style;
    second_style.style = TextStyle::Bold;
    QString second_text("this is the second text");
    block->replaceAtPos(first_text.size(), second_text, second_style);

    QString third_text("third");
    block->replaceAtPos(first_text.size(), third_text,first_style);

    blockHandler.doneChanges();

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_check_style = style_list.at(0);
    QCOMPARE(first_check_style.start_index, 0);
    QCOMPARE(first_check_style.end_index, (first_text.size() -1) + third_text.size());

    const TextStyleLine &second_check_style = style_list.at(1);
    QCOMPARE(second_check_style.start_index, first_text.size() + third_text.size());
    QCOMPARE(second_check_style.end_index, (first_text.size() -1) + second_text.size());

    const TextStyleLine &third_check_style = style_list.at(2);
    QCOMPARE(third_check_style.start_index, first_text.size() + second_text.size());
}

void tst_Block::replaceCompatiblePreviousStyleShouldRemove()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    TextStyle first_style = blockHandler.default_style;
    first_style.style = TextStyle::Blinking;
    QString first_text("first");
    block->replaceAtPos(0,first_text, first_style);

    TextStyle second_style = blockHandler.default_style;
    second_style.style = TextStyle::Bold;
    QString second_text("second");
    block->replaceAtPos(first_text.size(), second_text, second_style);

    QString third_text("this is the third");
    block->replaceAtPos(first_text.size(), third_text,first_style);

    blockHandler.doneChanges();

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_check_style = style_list.at(0);
    QCOMPARE(first_check_style.start_index, 0);
    QCOMPARE(first_check_style.end_index, (first_text.size() -1) + third_text.size());

    const TextStyleLine &second_check_style = style_list.at(1);
    QCOMPARE(second_check_style.start_index, first_text.size() + third_text.size());

}

void tst_Block::replaceCompatibleCurrentStyleShouldRemove()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    TextStyle first_style = blockHandler.default_style;
    first_style.style = TextStyle::Blinking;
    QString first_text("first");
    block->replaceAtPos(0,first_text, first_style);

    TextStyle second_style = blockHandler.default_style;
    second_style.style = TextStyle::Bold;
    QString second_text("second");
    block->replaceAtPos(first_text.size(), second_text, second_style);

    QString third_text("second");
    block->replaceAtPos(first_text.size(), third_text,first_style);

    blockHandler.doneChanges();

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_check_style = style_list.at(0);
    QCOMPARE(first_check_style.start_index, 0);
    QCOMPARE(first_check_style.end_index, (first_text.size() -1) + third_text.size());

    const TextStyleLine &second_check_style = style_list.at(1);
    QCOMPARE(second_check_style.start_index, first_text.size() + third_text.size());

}

void tst_Block::replaceIncompatibleStyle()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();


    QString replace_text("replaceed Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(10, replace_text, replace_style);

    QVector<TextStyleLine> after_style_list = block->style_list();
    QCOMPARE(after_style_list.size(), 3);

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 9);
    QCOMPARE(first_style.style, blockHandler.default_text_style);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.start_index, 10);
    QCOMPARE(second_style.end_index, 10 + replace_text.size() -1);
    QCOMPARE(second_style.style, TextStyle::Blinking);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.start_index, 10 + replace_text.size());
    QCOMPARE(third_style.style, blockHandler.default_text_style);
}

void tst_Block::replaceIncompaitibleStylesCrossesBoundary()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceed Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(0, replace_text, replace_style);

    QString crosses_boundary("New incompatible text");
    replace_style.style = TextStyle::Framed;
    int replace_pos = replace_text.size()/2;
    block->replaceAtPos(replace_pos, crosses_boundary, replace_style);

    QVector<TextStyleLine> after_style_list = block->style_list();
    QCOMPARE(after_style_list.size(), 3);

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_pos -1);
    QCOMPARE(first_style.style, TextStyle::Blinking);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.start_index, replace_pos);
    QCOMPARE(second_style.end_index, replace_pos + crosses_boundary.size() -1);
    QCOMPARE(second_style.style, TextStyle::Framed);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.start_index, replace_pos + crosses_boundary.size());
    QCOMPARE(third_style.style, blockHandler.default_text_style);
}

void tst_Block::replace3IncompatibleStyles()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    block->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    block->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QCOMPARE(block->style_list().size(), 4);

    QVector<TextStyleLine> after_style_list = block->style_list();

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, first_text.size() -1);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.start_index, first_text.size());
    QCOMPARE(second_style.end_index, first_text.size() + second_text.size() - 1);
    QCOMPARE(second_style.style, TextStyle::Italic);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.start_index, first_text.size() + second_text.size());
    QCOMPARE(third_style.end_index, first_text.size() + second_text.size() + third_text.size() - 1);
    QCOMPARE(third_style.style, TextStyle::Encircled);

    const TextStyleLine &fourth_style = after_style_list.at(3);
    QCOMPARE(fourth_style.start_index, first_text.size() + second_text.size() + third_text.size());
}
void tst_Block::replaceIncomaptibleStylesCrosses2Boundaries()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    block->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    block->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QCOMPARE(block->style_list().size(), 4);

    QVector<TextStyleLine> before_style_list = block->style_list();

    QString overlap_first_third;
    overlap_first_third.fill(QChar('A'), second_text.size() + 4);
    replace_style.style = TextStyle::DoubleUnderlined;
    block->replaceAtPos(first_text.size() -2, overlap_first_third, replace_style);

    QVector<TextStyleLine> after_style_list = block->style_list();
    QCOMPARE(block->style_list().size(), 4);

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, first_text.size() - 3);
    QCOMPARE(first_style.style, TextStyle::Blinking);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.style, TextStyle::DoubleUnderlined);
    QCOMPARE(second_style.start_index, first_text.size() - 2);
    QCOMPARE(second_style.end_index, first_text.size() - 2 + overlap_first_third.size() -1);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.style, TextStyle::Encircled);
    QCOMPARE(third_style.start_index, first_text.size() - 2 + overlap_first_third.size());
    QCOMPARE(third_style.end_index, first_text.size() - 2 + overlap_first_third.size() + third_text.size() - 1 - 2);

    const TextStyleLine &fourth_style = after_style_list.at(3);
    QCOMPARE(fourth_style.style, blockHandler.default_text_style);
    QCOMPARE(fourth_style.start_index, first_text.size() - 2 + overlap_first_third.size() + third_text.size() - 2);
}

void tst_Block::replaceIncompatibleColor()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("291 ");
    TextStyleLine replace_style;
    replace_style.forground = ColorPalette::Yellow;
    block->replaceAtPos(0,first_text, replace_style);

    QString second_text("QPointF Screen::selectionAreaStart() ");
    replace_style.forground = blockHandler.default_style.forground;
    block->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("const");
    replace_style.forground = ColorPalette::Green;
    block->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QString brackets("()");
    replace_style.forground = ColorPalette::Cyan;
    block->replaceAtPos(38, brackets, replace_style);

    QVector<TextStyleLine> after_style_list = block->style_list();

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.forground, ColorPalette::Yellow);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, first_text.size() - 1);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.forground, blockHandler.default_style.forground);
    QCOMPARE(second_style.start_index, first_text.size());
    QCOMPARE(second_style.end_index, 37);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.forground, ColorPalette::Cyan);
    QCOMPARE(third_style.start_index, 38);
    QCOMPARE(third_style.end_index, 38 + brackets.size() -1);

    const TextStyleLine &fourth_style = after_style_list.at(3);
    QCOMPARE(fourth_style.forground, blockHandler.default_style.forground);
    QCOMPARE(fourth_style.start_index, 38 + brackets.size());
    QCOMPARE(fourth_style.end_index, first_text.size() + second_text.size() -1);

}

void tst_Block::replaceRemoveOverlappedStyles()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    block->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    block->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QString fourth_text = third_text + second_text;
    fourth_text.chop(1);
    replace_style.style = TextStyle::Bold;
    block->replaceAtPos(first_text.size(), fourth_text, replace_style);

    QCOMPARE(block->style_list().size(), 4);
}
void tst_Block::replaceSwapStyles()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    block->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    block->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    block->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QString replace_second("Dnoces Text");
    replace_style.style = TextStyle::Bold;
    block->replaceAtPos(first_text.size(), replace_second, replace_style);

    QCOMPARE(block->style_list().size(), 4);
}

void tst_Block::replaceEndBlock()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    QString replace_text("at the end of the string");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Bold;
    block->replaceAtPos(block_size - replace_text.size(), replace_text, style);

    QCOMPARE(block->textLine()->size(), block_size);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, block_size - replace_text.size() -1);
    QCOMPARE(first_style.style, blockHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, block_size - replace_text.size());
    QCOMPARE(second_style.end_index, block_size - 1);
    QCOMPARE(second_style.style, TextStyle::Bold);
}

void tst_Block::clearBlock()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QVERIFY(block->textLine()->size() > 0);
    QCOMPARE(block->textLine()->trimmed().size(), 0);
}

void tst_Block::clearToEndOfBlock1Segment()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("To be replaceed");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    int before_clear_size = block->textLine()->size();

    block->clearCharacters(5, blockHandler.screen.width() -1);

    blockHandler.doneChanges();

    int after_clear_size = block->textLine()->size();
    QCOMPARE(after_clear_size, before_clear_size);
    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);

    QString cleared("To be");
    QCOMPARE(block->textLine()->trimmed(), cleared);
}

void tst_Block::clearToEndOfBlock3Segment()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("To be");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString replace_text2(" or not to be");
    style.style = TextStyle::Bold;
    block ->replaceAtPos(replace_text.size(), replace_text2, style);

    block->clearCharacters(replace_text.size(), blockHandler.screen.width() - 1);

    blockHandler.doneChanges();

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.style, blockHandler.default_text_style);
}

void tst_Block::clearToEndOfBlockMiddle3Segment()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("To be");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString replace_text2(" or not to be");
    style.style = TextStyle::Bold;
    block ->replaceAtPos(replace_text.size(), replace_text2, style);

    block->clearCharacters(replace_text.size() + 3, blockHandler.screen.width() - 1);

    blockHandler.doneChanges();

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.end_index, replace_text.size() + 2);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, replace_text.size() + 3);
    QCOMPARE(third_style.style, blockHandler.default_text_style);
}

void tst_Block::deleteCharacters1Segment()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceing some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    block->deleteCharacters(10,14);

    QCOMPARE(block->textLine()->size(), block_size - 5);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 14);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 15);
    QCOMPARE(second_style.style, blockHandler.default_text_style);
}

void tst_Block::deleteCharacters2Segments()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceing some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    block->deleteCharacters(15,25);

    QCOMPARE(block->textLine()->size(), block_size - 11);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 14);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 15);
    QCOMPARE(second_style.style, blockHandler.default_text_style);

}

void tst_Block::deleteCharacters3Segments()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceing some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    block->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    block->deleteCharacters(10,15);

    QCOMPARE(block->textLine()->size(), block_size - 6);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 13);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 14);
    QCOMPARE(second_style.end_index, 14 + replace_more_text.size() -1);
    QCOMPARE(second_style.style, TextStyle::Bold);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 14 + replace_more_text.size());
    QCOMPARE(third_style.style, blockHandler.default_text_style);
}

void tst_Block::deleteCharactersRemoveSegmentEnd()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceing some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    block->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    block->deleteCharacters(16,33);

    QCOMPARE(block->textLine()->size(), block_size - ((33 - 16) + 1));

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 15);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 16);
    QCOMPARE(second_style.style, blockHandler.default_text_style);

}

void tst_Block::deleteCharactersRemoveSegmentBeginning()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString replace_text("replaceing some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    block->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    block->deleteCharacters(replace_text.size(),replace_text.size() + replace_more_text.size() + 3);

    int expected_size = block_size -1 - ((replace_text.size() + replace_more_text.size() + 3 ) - replace_text.size());
    QCOMPARE(block->textLine()->size(), expected_size);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.style, blockHandler.default_text_style);
}

void tst_Block::deleteCharactersRemoveMiddle()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString insert_text('A');
    int old_width = blockHandler.screen.width();
    QString empty(old_width - 2, ' ');
    insert_text += empty + 'B';
    block->replaceAtPos(0, insert_text, blockHandler.default_style);

    Q_ASSERT(old_width == blockHandler.screen.width());
    Q_ASSERT(insert_text == *block->textLine());

    block->deleteCharacters(1, old_width - 2);

    Q_ASSERT(QString("AB") == block->textLine()->trimmed());
}

void tst_Block::insertCharacters()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    QString insert_text("inserting some text");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Encircled;
    block->insertAtPos(5, insert_text, style);

    int expected_size = block_size + insert_text.size();

    QCOMPARE(block->textLine()->size(), expected_size);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);
    QCOMPARE(first_style.style, blockHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);
    QCOMPARE(second_style.end_index, 5 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Encircled);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 5 + insert_text.size());
    QCOMPARE(third_style.end_index, expected_size - 1);
    QCOMPARE(third_style.style, blockHandler.default_text_style);
}

void tst_Block::insertCharacters2Segments()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    QString replace_text("at the end of the string");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Bold;
    block->replaceAtPos(block_size - replace_text.size(), replace_text, style);

    QString insert_text("inserting some text");
    style.style = TextStyle::Encircled;
    block->insertAtPos(5, insert_text, style);

    int expected_size = block_size + insert_text.size();
    QCOMPARE(block->textLine()->size(), expected_size);

    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 4);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);
    QCOMPARE(first_style.style, blockHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);
    QCOMPARE(second_style.end_index, 5 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Encircled);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 5 + insert_text.size());
    QCOMPARE(third_style.end_index, block_size -1 - replace_text.size() + insert_text.size());
    QCOMPARE(third_style.style, blockHandler.default_text_style);

    const TextStyleLine &fourth_style = style_list.at(3);
    QCOMPARE(fourth_style.start_index, block_size - replace_text.size() + insert_text.size());
    QCOMPARE(fourth_style.end_index, expected_size - 1 );
    QCOMPARE(fourth_style.style, TextStyle::Bold);
}

void tst_Block::insertCharacters3Segments()
{
    BlockHandler blockHandler(true);
    Block *block = blockHandler.block();

    QString *full_block = block->textLine();
    int block_size = full_block->size();

    QString replace_text("at the end of the string");
    TextStyle style = blockHandler.default_style;
    style.style = TextStyle::Bold;
    block->replaceAtPos(block_size - replace_text.size(), replace_text, style);

    QString replace_text2("somewhere in the string");
    style.style = TextStyle::Encircled;
    block->replaceAtPos(20,replace_text2, style);

    QVector<TextStyleLine> tmp_style_list = block->style_list();
    QCOMPARE(tmp_style_list.size(), 4);

    QString insert_text("this text is longer than last segment");
    style.style = TextStyle::Italic;
    block->insertAtPos(10, insert_text, style);

    blockHandler.doneChanges();

    int expected_size = block_size + insert_text.size();
    QCOMPARE(block->textLine()->size(), expected_size);

    block->printStyleList();
    QVector<TextStyleLine> style_list = block->style_list();
    QCOMPARE(style_list.size(), 6);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 9);
    QCOMPARE(first_style.style, blockHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 10);
    QCOMPARE(second_style.end_index, 10 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Italic);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 10 + insert_text.size());
    QCOMPARE(third_style.end_index, 20 + insert_text.size() - 1);
    QCOMPARE(third_style.style, blockHandler.default_text_style);

    const TextStyleLine &fourth_style = style_list.at(3);
    QCOMPARE(fourth_style.start_index, 20 + insert_text.size());
    QCOMPARE(fourth_style.end_index, 20 + insert_text.size() + replace_text2.size() - 1);
    QCOMPARE(fourth_style.style, TextStyle::Encircled);

    const TextStyleLine &fith_style = style_list.at(4);
    QCOMPARE(fith_style.start_index, 20 + insert_text.size() + replace_text2.size());
    QCOMPARE(fith_style.end_index, block_size - replace_text.size() + insert_text.size() - 1);
    QCOMPARE(fith_style.style, blockHandler.default_text_style);

    const TextStyleLine &sixth_style = style_list.at(5);
    QCOMPARE(sixth_style.start_index, block_size - replace_text.size() + insert_text.size());
    QCOMPARE(sixth_style.end_index, block_size + insert_text.size() - 1);
    QCOMPARE(sixth_style.style, TextStyle::Bold);
}

#include <tst_block.moc>
QTEST_MAIN(tst_Block);
