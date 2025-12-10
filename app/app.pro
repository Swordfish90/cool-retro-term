QT += qml quick widgets sql quickcontrols2
TARGET = cool-retro-term 

DESTDIR = $$OUT_PWD/../

HEADERS += \
    fileio.h \
    monospacefontmanager.h

SOURCES = main.cpp \
    fileio.cpp \
    monospacefontmanager.cpp

macx:ICON = icons/crt.icns

RESOURCES += qml/resources.qrc

# Shader compilation (Qt Shader Baker)
QSB_BIN = $$[QT_HOST_BINS]/qsb
isEmpty(QSB_BIN): QSB_BIN = $$[QT_INSTALL_BINS]/qsb

SHADERS_DIR = $${_PRO_FILE_PWD_}/shaders
SHADERS += $$files($$SHADERS_DIR/*.frag) $$files($$SHADERS_DIR/*.vert)

qsb.input = SHADERS
qsb.output = ../../app/shaders/${QMAKE_FILE_NAME}.qsb
qsb.commands = $$QSB_BIN --glsl \"100 es,120,150\" --hlsl 50 --msl 12 --qt6 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_IN}
qsb.clean = $$qsb.output
qsb.name = qsb ${QMAKE_FILE_IN}
qsb.variable_out = QSB_FILES
QMAKE_EXTRA_COMPILERS += qsb
PRE_TARGETDEPS += $$QSB_FILES
OTHER_FILES += $$SHADERS $$QSB_FILES

#########################################
##              INTALLS
#########################################

target.path += /usr/bin/

INSTALLS += target

# Install icons
unix {
    icon32.files = icons/32x32/cool-retro-term.png
    icon32.path = /usr/share/icons/hicolor/32x32/apps
    icon64.files = icons/64x64/cool-retro-term.png
    icon64.path = /usr/share/icons/hicolor/64x64/apps
    icon128.files = icons/128x128/cool-retro-term.png
    icon128.path = /usr/share/icons/hicolor/128x128/apps
    icon256.files = icons/256x256/cool-retro-term.png
    icon256.path = /usr/share/icons/hicolor/256x256/apps

    INSTALLS += icon32 icon64 icon128 icon256
}
