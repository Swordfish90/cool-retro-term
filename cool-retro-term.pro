TEMPLATE = subdirs

CONFIG += ordered

SUBDIRS += qmltermwidget
SUBDIRS += app

# The Qt Quick test suite is opt-in: `qmake CONFIG+=build_tests` (the Node
# suite under tests/logic needs no build at all: `node --test`).
contains(CONFIG, build_tests) {
    SUBDIRS += tests
}

desktop.files += cool-retro-term.desktop
desktop.path += /usr/share/applications

INSTALLS += desktop
