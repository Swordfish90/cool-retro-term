DEPENDPATH += $$PWD
INCLUDEPATH += $$PWD

LIBS += -lutil -L/home/jlind/install/lib

MOC_DIR = .moc
OBJECTS_DIR = .obj

HEADERS += \
           $$PWD/yat_pty.h \
           $$PWD/text.h \
           $$PWD/controll_chars.h \
           $$PWD/parser.h \
           $$PWD/screen.h \
           $$PWD/line.h \
           $$PWD/color_palette.h \
           $$PWD/text_style.h \
           $$PWD/update_action.h \
           $$PWD/screen_data.h

SOURCES += \
           $$PWD/yat_pty.cpp \
           $$PWD/text.cpp \
           $$PWD/controll_chars.cpp \
           $$PWD/parser.cpp \
           $$PWD/screen.cpp \
           $$PWD/line.cpp \
           $$PWD/color_palette.cpp \
           $$PWD/text_style.cpp \
           $$PWD/update_action.cpp \
           $$PWD/screen_data.cpp
