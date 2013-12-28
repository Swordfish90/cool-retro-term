QT += widgets quick core-private gui-private qml-private quick quick-private
TARGET = cool-old-term

include(../backend/backend.pri)

INCLUDEPATH += $$PWD

SOURCES += $$PWD/terminal_screen.cpp \
    $$PWD/object_destruct_item.cpp \
    $$PWD/register_qml_types.cpp \
    $$PWD/mono_text.cpp \

HEADERS += \
    $$PWD/terminal_screen.h \
    $$PWD/object_destruct_item.h \
    $$PWD/register_qml_types.h \
    $$PWD/mono_text.h \

