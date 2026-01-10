QT += testlib gui

CONFIG += qt console warn_on depend_includepath testcase
CONFIG -= app_bundle

TEMPLATE = app

# Include paths to the source code we're testing
INCLUDEPATH += $$PWD/../../qmltermwidget/lib
INCLUDEPATH += $$PWD/../../app

SOURCES += \
    tst_main.cpp \
    tst_konsole_wcwidth.cpp \
    tst_fileio.cpp \
    tst_character.cpp

HEADERS += \
    tst_konsole_wcwidth.h \
    tst_fileio.h \
    tst_character.h

# Include the source files we're testing
SOURCES += \
    $$PWD/../../qmltermwidget/lib/konsole_wcwidth.cpp \
    $$PWD/../../app/fileio.cpp

HEADERS += \
    $$PWD/../../qmltermwidget/lib/konsole_wcwidth.h \
    $$PWD/../../qmltermwidget/lib/Character.h \
    $$PWD/../../qmltermwidget/lib/CharacterColor.h \
    $$PWD/../../app/fileio.h
