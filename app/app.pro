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

#########################################
##              INSTALLS
#########################################

PREFIX = $$(PREFIX) # Pass the make install PREFIX via environment variable. E.g. "PREFIX=/path/to/my/dir qmake".
isEmpty(PREFIX) {
    message(No prefix given. Using /usr.)
    PREFIX=/usr
}

target.path = $$PREFIX/bin

INSTALLS += target

# Install icons
unix {
    icon32.files = icons/32x32/cool-retro-term.png
    icon32.path = $$PREFIX/share/icons/hicolor/32x32/apps
    icon64.files = icons/64x64/cool-retro-term.png
    icon64.path = $$PREFIX/share/icons/hicolor/64x64/apps
    icon128.files = icons/128x128/cool-retro-term.png
    icon128.path = $$PREFIX/share/icons/hicolor/128x128/apps
    icon256.files = icons/256x256/cool-retro-term.png
    icon256.path = $$PREFIX/share/icons/hicolor/256x256/apps

    INSTALLS += icon32 icon64 icon128 icon256
}
