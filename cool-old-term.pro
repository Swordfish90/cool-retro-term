QT += widgets quick

include(yat/yat_declarative/yat_declarative.pro)

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp

# Installation path
# target.path =

OTHER_FILES += \
        $$PWD/qml/cool-old-term/main.qml \
    $$PWD/qml/cool-old-term/TerminalLine.qml \
    $$PWD/qml/cool-old-term/TerminalScreen.qml \
    $$PWD/qml/cool-old-term/TerminalText.qml \
    $$PWD/qml/cool-old-term/HighlightArea.qml \
    qml/cool-old-term/ShaderSettings.qml
