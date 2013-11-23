#include "../../../backend/line.h"
#include <QtTest/QtTest>

#include <QtQml/QQmlEngine>
#include "../../../backend/screen.h"

class LineHandler
{
public:
    LineHandler() {
        screen.setHeight(50);
        screen.setWidth(100);
        screen.line_at_cursor()->clear();
        QCOMPARE(line()->style_list().size(), 1);
        default_style = line()->style_list().at(0);
        default_text_style = default_style.style;
    }

    Line *line() const
    {
        return screen.line_at_cursor();
    }

    TextStyle default_style;
    TextStyle::Styles default_text_style;
    Screen screen;
};

class tst_Line: public QObject
{
    Q_OBJECT

private slots:
    void replaceStart();
    void replaceEdgeOfStyle();
    void replaceCompatibleStyle();
    void replaceIncompatibleStyle();
    void replaceIncompaitibleStylesCrossesBoundary();
    void replace3IncompatibleStyles();
    void replaceIncomaptibleStylesCrosses2Boundaries();
    void replaceSwapStyles();
    void replaceEndLine();
    void clearLine();
    void clearToEndOfLine1Segment();
    void clearToEndOfLine3Segment();
    void clearToEndOfLineMiddle3Segment();
    void deleteCharacters1Segment();
    void deleteCharacters2Segments();
    void deleteCharacters3Segments();
    void deleteCharactersRemoveSegmentEnd();
    void deleteCharactersRemoveSegmentBeginning();
    void insertCharacters();
    void insertCharacters2Segments();
    void insertCharacters3Segments();
};

void tst_Line::replaceStart()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QVector<TextStyleLine> old_style_list = line->style_list();
    QCOMPARE(old_style_list.size(), 1);

    QString replace_text("This is a test");
    TextStyle textStyle;
    textStyle.style = TextStyle::Overlined;
    line->replaceAtPos(0,replace_text, textStyle);

    QVector<TextStyleLine> new_style_list = line->style_list();
    TextStyleLine first_style = new_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);
    QCOMPARE(new_style_list.size(), 2);

}

void tst_Line::replaceEdgeOfStyle()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString first_text("This is the First");
    TextStyle textStyle;
    textStyle.style = TextStyle::Overlined;
    line->replaceAtPos(0,first_text, textStyle);

    QString second_text("This is the Second");
    textStyle.style = TextStyle::Bold;
    line->replaceAtPos(first_text.size(), second_text, textStyle);

    QVector<TextStyleLine> style_list = line->style_list();

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

void tst_Line::replaceCompatibleStyle()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceed Text");
    line->replaceAtPos(10, replace_text, lineHandler.default_style);

    QVector<TextStyleLine> after_style_list = line->style_list();
    QCOMPARE(after_style_list.size(), 1);
    QCOMPARE(after_style_list.at(0).style, lineHandler.default_text_style);
}

void tst_Line::replaceIncompatibleStyle()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();


    QString replace_text("replaceed Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    line->replaceAtPos(10, replace_text, replace_style);

    QVector<TextStyleLine> after_style_list = line->style_list();
    QCOMPARE(after_style_list.size(), 3);

    const TextStyleLine &first_style = after_style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 9);
    QCOMPARE(first_style.style, lineHandler.default_text_style);

    const TextStyleLine &second_style = after_style_list.at(1);
    QCOMPARE(second_style.start_index, 10);
    QCOMPARE(second_style.end_index, 10 + replace_text.size() -1);
    QCOMPARE(second_style.style, TextStyle::Blinking);

    const TextStyleLine &third_style = after_style_list.at(2);
    QCOMPARE(third_style.start_index, 10 + replace_text.size());
    QCOMPARE(third_style.style, lineHandler.default_text_style);
}

void tst_Line::replaceIncompaitibleStylesCrossesBoundary()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceed Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    line->replaceAtPos(0, replace_text, replace_style);

    QString crosses_boundary("New incompatible text");
    replace_style.style = TextStyle::Framed;
    int replace_pos = replace_text.size()/2;
    line->replaceAtPos(replace_pos, crosses_boundary, replace_style);

    QVector<TextStyleLine> after_style_list = line->style_list();
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
    QCOMPARE(third_style.style, lineHandler.default_text_style);
}

void tst_Line::replace3IncompatibleStyles()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    line->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    line->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    line->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QCOMPARE(line->style_list().size(), 4);

    QVector<TextStyleLine> after_style_list = line->style_list();

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
void tst_Line::replaceIncomaptibleStylesCrosses2Boundaries()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    line->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    line->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    line->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QCOMPARE(line->style_list().size(), 4);

    QVector<TextStyleLine> before_style_list = line->style_list();

    QString overlap_first_third;
    overlap_first_third.fill(QChar('A'), second_text.size() + 4);
    replace_style.style = TextStyle::DoubleUnderlined;
    line->replaceAtPos(first_text.size() -2, overlap_first_third, replace_style);

    QVector<TextStyleLine> after_style_list = line->style_list();
    QCOMPARE(line->style_list().size(), 4);

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
    QCOMPARE(fourth_style.style, lineHandler.default_text_style);
    QCOMPARE(fourth_style.start_index, first_text.size() - 2 + overlap_first_third.size() + third_text.size() - 2);
}

void tst_Line::replaceSwapStyles()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString first_text("First Text");
    TextStyle replace_style;
    replace_style.style = TextStyle::Blinking;
    line->replaceAtPos(0, first_text, replace_style);

    QString second_text("Second Text");
    replace_style.style = TextStyle::Italic;
    line->replaceAtPos(first_text.size(), second_text, replace_style);

    QString third_text("Third Text");
    replace_style.style = TextStyle::Encircled;
    line->replaceAtPos(first_text.size() + second_text.size(), third_text, replace_style);

    QString replace_second("Dnoces Text");
    replace_style.style = TextStyle::Bold;
    line->replaceAtPos(first_text.size(), replace_second, replace_style);

    QCOMPARE(line->style_list().size(), 4);
}

void tst_Line::replaceEndLine()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    QString replace_text("at the end of the string");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Bold;
    line->replaceAtPos(line_size - replace_text.size(), replace_text, style);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, line_size - replace_text.size() -1);
    QCOMPARE(first_style.style, lineHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, line_size - replace_text.size());
    QCOMPARE(second_style.end_index, line_size - 1);
    QCOMPARE(second_style.style, TextStyle::Bold);
}

void tst_Line::clearLine()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QVERIFY(line->textLine()->size() > 0);
    QCOMPARE(line->textLine()->trimmed().size(), 0);
}

void tst_Line::clearToEndOfLine1Segment()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("To be replaceed");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    int before_clear_size = line->textLine()->size();
    line->clearToEndOfLine(5);

    int after_clear_size = line->textLine()->size();
    QCOMPARE(after_clear_size, before_clear_size);
    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);

    QString cleared("To be");
    QCOMPARE(line->textLine()->trimmed(), cleared);
}

void tst_Line::clearToEndOfLine3Segment()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("To be");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString replace_text2(" or not to be");
    style.style = TextStyle::Bold;
    line ->replaceAtPos(replace_text.size(), replace_text2, style);

    line->clearToEndOfLine(replace_text.size());

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.style, lineHandler.default_text_style);
}

void tst_Line::clearToEndOfLineMiddle3Segment()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("To be");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString replace_text2(" or not to be");
    style.style = TextStyle::Bold;
    line ->replaceAtPos(replace_text.size(), replace_text2, style);

    line->clearToEndOfLine(replace_text.size() + 3);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.end_index, replace_text.size() + 2);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, replace_text.size() + 3);
    QCOMPARE(third_style.style, lineHandler.default_text_style);
}

void tst_Line::deleteCharacters1Segment()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceing some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    line->deleteCharacters(10,14);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 14);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 15);
    QCOMPARE(second_style.style, lineHandler.default_text_style);
}

void tst_Line::deleteCharacters2Segments()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceing some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    line->deleteCharacters(15,25);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 14);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 15);
    QCOMPARE(second_style.style, lineHandler.default_text_style);

}

void tst_Line::deleteCharacters3Segments()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceing some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    line->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    line->deleteCharacters(10,15);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
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
    QCOMPARE(third_style.style, lineHandler.default_text_style);
}

void tst_Line::deleteCharactersRemoveSegmentEnd()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceing some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    line->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    line->deleteCharacters(16,33);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 15);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 16);
    QCOMPARE(second_style.style, lineHandler.default_text_style);

}

void tst_Line::deleteCharactersRemoveSegmentBeginning()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString replace_text("replaceing some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->replaceAtPos(0, replace_text, style);

    QString replace_more_text("Some more text");
    style.style = TextStyle::Bold;
    line->replaceAtPos(replace_text.size(), replace_more_text, style);

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    line->deleteCharacters(replace_text.size(),replace_text.size() + replace_more_text.size() + 3);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 2);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, replace_text.size() - 1);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, replace_text.size());
    QCOMPARE(second_style.style, lineHandler.default_text_style);
}

void tst_Line::insertCharacters()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    QString insert_text("inserting some text");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Encircled;
    line->insertAtPos(5, insert_text, style);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 3);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);
    QCOMPARE(first_style.style, lineHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);
    QCOMPARE(second_style.end_index, 5 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Encircled);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 5 + insert_text.size());
    QCOMPARE(third_style.end_index, line_size - 1);
    QCOMPARE(third_style.style, lineHandler.default_text_style);
}

void tst_Line::insertCharacters2Segments()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    QString replace_text("at the end of the string");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Bold;
    line->replaceAtPos(line_size - replace_text.size(), replace_text, style);

    QString insert_text("inserting some text");
    style.style = TextStyle::Encircled;
    line->insertAtPos(5, insert_text, style);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 4);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 4);
    QCOMPARE(first_style.style, lineHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 5);
    QCOMPARE(second_style.end_index, 5 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Encircled);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 5 + insert_text.size());
    QCOMPARE(third_style.end_index, line_size -1 - replace_text.size() + insert_text.size());
    QCOMPARE(third_style.style, lineHandler.default_text_style);

    const TextStyleLine &fourth_style = style_list.at(3);
    QCOMPARE(fourth_style.start_index, line_size - replace_text.size() + insert_text.size());
    QCOMPARE(fourth_style.end_index, line_size -1 );
    QCOMPARE(fourth_style.style, TextStyle::Bold);
}

void tst_Line::insertCharacters3Segments()
{
    LineHandler lineHandler;
    Line *line = lineHandler.line();

    QString *full_line = line->textLine();
    int line_size = full_line->size();

    QString replace_text("at the end of the string");
    TextStyle style = lineHandler.default_style;
    style.style = TextStyle::Bold;
    line->replaceAtPos(line_size - replace_text.size(), replace_text, style);

    QString replace_text2("somewhere in the string");
    style.style = TextStyle::Encircled;
    line->replaceAtPos(20,replace_text2, style);

    QVector<TextStyleLine> tmp_style_list = line->style_list();
    QCOMPARE(tmp_style_list.size(), 4);

    QString insert_text("this text is longer than last segment");
    style.style = TextStyle::Italic;
    line->insertAtPos(10, insert_text, style);

    QCOMPARE(line->textLine()->size(), line_size);

    QVector<TextStyleLine> style_list = line->style_list();
    QCOMPARE(style_list.size(), 5);

    const TextStyleLine &first_style = style_list.at(0);
    QCOMPARE(first_style.start_index, 0);
    QCOMPARE(first_style.end_index, 9);
    QCOMPARE(first_style.style, lineHandler.default_text_style);

    const TextStyleLine &second_style = style_list.at(1);
    QCOMPARE(second_style.start_index, 10);
    QCOMPARE(second_style.end_index, 10 + insert_text.size()  -1);
    QCOMPARE(second_style.style, TextStyle::Italic);

    const TextStyleLine &third_style = style_list.at(2);
    QCOMPARE(third_style.start_index, 10 + insert_text.size());
    QCOMPARE(third_style.end_index, 20 + insert_text.size() - 1);
    QCOMPARE(third_style.style, lineHandler.default_text_style);

    const TextStyleLine &fourth_style = style_list.at(3);
    QCOMPARE(fourth_style.start_index, 20 + insert_text.size());
    QCOMPARE(fourth_style.end_index, 20 + insert_text.size() + replace_text2.size() - 1);
    QCOMPARE(fourth_style.style, TextStyle::Encircled);

    const TextStyleLine &fith_style = style_list.at(4);
    QCOMPARE(fith_style.start_index, 20 + insert_text.size() + replace_text2.size());
    QCOMPARE(fith_style.end_index, line_size - 1);
    QCOMPARE(fith_style.style, lineHandler.default_text_style);
}

#include <tst_line.moc>
QTEST_MAIN(tst_Line);
