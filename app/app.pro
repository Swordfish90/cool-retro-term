QT += qml quick widgets sql
TARGET = cool-retro-term 

DESTDIR = $$OUT_PWD/../

HEADERS += \
    fileio.h

SOURCES = main.cpp \
    fileio.cpp

macx:ICON = icons/crt.icns

RESOURCES += qml/resources.qrc

#########################################
##              INTALLS
#########################################

target.path += /usr/bin/

INSTALLS += target
