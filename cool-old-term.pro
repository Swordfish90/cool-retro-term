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
    $$PWD/qml/cool-old-term/ShaderSettings.qml \
    $$PWD/qml/images/frame.png \
    $$PWD/qml/cool-old-term/SettingsWindow.qml \
    $$PWD/qml/cool-old-term/SettingComponent.qml \
    $$PWD/qml/cool-old-term/ColorButton.qml \
    $$PWD/qml/cool-old-term/TerminalFrame.qml \
    $$PWD/qml/cool-old-term/WhiteFrameShader.qml \
    $$PWD/qml/cool-old-term/NoFrameShader.qml \
    $$PWD/qml/cool-old-term/WhiteSimpleFrame.qml \
    qml/cool-old-term/BlackRoughFrame.qml \
    qml/cool-old-term/Frames/BlackRoughFrame.qml \
    qml/cool-old-term/Frames/NoFrameShader.qml \
    qml/cool-old-term/Frames/WhiteFrameShader.qml \
    qml/cool-old-term/Frames/WhiteSimpleFrame.qml \
    qml/cool-old-term/Frames/TerminalFrame.qml \
    qml/cool-old-term/Frames/utils/NoFrameShader.qml \
    qml/cool-old-term/Frames/utils/TerminalFrame.qml \
    qml/cool-old-term/Frames/utils/WhiteFrameShader.qml \
    qml/cool-old-term/frames/WhiteSimpleFrame.qml \
    qml/cool-old-term/frames/BlackRoughFrame.qml \
    qml/cool-old-term/frames/utils/NoFrameShader.qml \
    qml/cool-old-term/frames/utils/TerminalFrame.qml \
    qml/cool-old-term/frames/utils/WhiteFrameShader.qml \
    qml/cool-old-term/frames/images/screen-frame.png \
    qml/cool-old-term/frames/images/screen-frame-normals.png \
    qml/cool-old-term/frames/images/black-frame.png \
    qml/cool-old-term/frames/images/black-frame-normals.png
