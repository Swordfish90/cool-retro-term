QT += testlib
QT -= gui

CONFIG += qt console warn_on depend_includepath testcase
CONFIG -= app_bundle

TEMPLATE = app

SOURCES += tst_smoke.cpp

# Path to the built app (relative to build directory)
DEFINES += APP_PATH=\\\"$$PWD/../../cool-retro-term.app/Contents/MacOS/cool-retro-term\\\"
