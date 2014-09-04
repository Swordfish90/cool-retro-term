TEMPLATE = subdirs

SUBDIRS += app
SUBDIRS += konsole-qml-plugin

desktop.files += cool-retro-term.desktop
desktop.path += /usr/share/applications

INSTALLS += desktop
