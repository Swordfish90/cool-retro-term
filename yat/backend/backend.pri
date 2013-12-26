DEPENDPATH += $$PWD
INCLUDEPATH += $$PWD

LIBS += -lutil

CONFIG += c++11

MOC_DIR = .moc
OBJECTS_DIR = .obj

HEADERS += \
           $$PWD/yat_pty.h \
           $$PWD/text.h \
           $$PWD/controll_chars.h \
           $$PWD/parser.h \
           $$PWD/screen.h \
           $$PWD/block.h \
           $$PWD/color_palette.h \
           $$PWD/text_style.h \
           $$PWD/screen_data.h \
           $$PWD/cursor.h \
           $$PWD/nrc_text_codec.h \
           $$PWD/scrollback.h \
           $$PWD/utf8_decoder.h \
           $$PWD/selection.h

SOURCES += \
           $$PWD/yat_pty.cpp \
           $$PWD/text.cpp \
           $$PWD/controll_chars.cpp \
           $$PWD/parser.cpp \
           $$PWD/screen.cpp \
           $$PWD/block.cpp \
           $$PWD/color_palette.cpp \
           $$PWD/text_style.cpp \
           $$PWD/screen_data.cpp \
           $$PWD/cursor.cpp \
           $$PWD/nrc_text_codec.cpp \
           $$PWD/scrollback.cpp \
           $$PWD/selection.cpp

