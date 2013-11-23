QT += gui quick
TARGET = yat

include(../backend/backend.pri)

SOURCES += main.cpp \
    terminal_screen.cpp \
    object_destruct_item.cpp \
    register_qml_types.cpp \

HEADERS += \
    terminal_screen.h \
    object_destruct_item.h \
    register_qml_types.h \

QML_IMPORT_PATH =

OTHER_FILES += \
        qml/yat_declarative/main.qml \
    qml/yat_declarative/TerminalLine.qml \
    qml/yat_declarative/TerminalScreen.qml \
    qml/yat_declarative/TerminalText.qml \
    qml/yat_declarative/HighlightArea.qml

RESOURCES += \
        qml_sources.qrc

