TEMPLATE = app
TARGET = tst_qml

QT += quick qml testlib
CONFIG += warn_on qmltestcase

SOURCES += tst_qml.cpp

# Import path for our QML files
IMPORTPATH += $$PWD/../../app/qml

OTHER_FILES += \
    tst_utils.qml
