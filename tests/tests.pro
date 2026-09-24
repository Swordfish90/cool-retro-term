TEMPLATE = app
TARGET = tst_retroterm

QT += qml quick testlib
CONFIG += qmltestcase console
CONFIG -= app_bundle

SOURCES += tst_quick.cpp

# Bundled key click and bell, under the same URLs SoundBackend asks for, so
# the suite can assert they really decode.
RESOURCES += testdata.qrc

# CONFIG += qmltestcase (see mkspecs/features/qmltestcase.prf) already defines
# QUICK_TEST_SOURCE_DIR as this directory, so every tst_*.qml placed here is
# discovered and run by the binary.  The QML tests drive the very sources the
# application ships: they import them straight out of ../app/qml.
