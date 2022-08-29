TEMPLATE = subdirs

CONFIG += ordered

SUBDIRS += qmltermwidget
SUBDIRS += app

#########################################
##              INSTALLS
#########################################

PREFIX = $$(PREFIX) # Pass the make install PREFIX via environment variable. E.g. "PREFIX=/path/to/my/dir qmake".
isEmpty(PREFIX) {
    message(No prefix given. Using /usr.)
    PREFIX=/usr
}

desktop.files += cool-retro-term.desktop
desktop.path += $$PREFIX/share/applications

INSTALLS += desktop
