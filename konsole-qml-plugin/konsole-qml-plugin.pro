#########################################
##              CONFIGS
#########################################

TEMPLATE = lib
CONFIG += qt plugin hide_symbols
QT += qml quick widgets

DEFINES += HAVE_POSIX_OPENPT HAVE_SYS_TIME_H HAVE_UPDWTMPX

#MANUALY DEFINED PLATFORM
DEFINES += Q_WS_UBUNTU

TARGET = kdekonsole
PLUGIN_IMPORT_PATH = org/kde/konsole
PLUGIN_ASSETS = $$PWD/assets/*

INSTALL_DIR = ../imports

#########################################
##              SOURCES
#########################################

SOURCES += \
        $$PWD/src/plugin.cpp \
        $$PWD/src/Pty.cpp \
        $$PWD/src/kptyprocess.cpp \
        $$PWD/src/kptydevice.cpp \
        $$PWD/src/kpty.cpp \
        $$PWD/src/kprocess.cpp \
        $$PWD/src/ShellCommand.cpp \
        $$PWD/src/Vt102Emulation.cpp \
        $$PWD/src/tools.cpp \
        $$PWD/src/Session.cpp \
        $$PWD/src/Screen.cpp \
        $$PWD/src/KeyboardTranslator.cpp \
        $$PWD/src/Emulation.cpp \
        $$PWD/src/History.cpp \
        $$PWD/src/BlockArray.cpp \
        $$PWD/src/TerminalCharacterDecoder.cpp \
        $$PWD/src/konsole_wcwidth.cpp \
        $$PWD/src/ScreenWindow.cpp \
        $$PWD/src/Filter.cpp \
        $$PWD/src/ColorScheme.cpp \
        $$PWD/src/TerminalDisplay.cpp \
        $$PWD/src/ksession.cpp

HEADERS += \
        $$PWD/src/plugin.h \
        $$PWD/src/Pty.h \
        $$PWD/src/kptyprocess.h \
        $$PWD/src/kptydevice.h \
        $$PWD/src/kpty.h \
        $$PWD/src/kpty_p.h \
        $$PWD/src/kprocess.h \
        $$PWD/src/ShellCommand.h \
        $$PWD/src/Vt102Emulation.h \
        $$PWD/src/tools.h \
        $$PWD/src/Session.h \
        $$PWD/src/Screen.h \
        $$PWD/src/KeyboardTranslator.h \
        $$PWD/src/Emulation.h \
        $$PWD/src/Character.h \
        $$PWD/src/History.h \
        $$PWD/src/CharacterColor.h \
        $$PWD/src/BlockArray.h \
        $$PWD/src/TerminalCharacterDecoder.h \
        $$PWD/src/konsole_wcwidth.h \
        $$PWD/src/ScreenWindow.h \
        $$PWD/src/DefaultTranslatorText.h \
        $$PWD/src/LineFont.h \
        $$PWD/src/Filter.h \
        $$PWD/src/ExtendedDefaultTranslator.h \
        $$PWD/src/ColorTables.h \
        $$PWD/src/ColorScheme.h \
        $$PWD/src/TerminalDisplay.h \
        $$PWD/src/ksession.h

OTHER_FILES += \
    $$PWD/src/qmldir \
    $$PWD/src/plugins.qmltypes

MOC_DIR = $$PWD/.moc
OBJECTS_DIR = $$PWD/.obj

#########################################
##              INTALLS
#########################################

target.path = $$INSTALL_DIR/$$PLUGIN_IMPORT_PATH

assets.files += $$PLUGIN_ASSETS
assets.path  += $$INSTALL_DIR/$$PLUGIN_IMPORT_PATH

qmldir.files += $$PWD/src/qmldir \
                $$PWD/src/plugins.qmltypes
qmldir.path  += $$INSTALL_DIR/$$PLUGIN_IMPORT_PATH

INSTALLS     += target qmldir assets
