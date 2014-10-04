# This is a simple shell script for installing the dependencies and compiling
# the source under Ubuntu 14.04.
# Note that it may also work with other versions of Ubuntu.

apt-get update

apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qtdeclarative5-controls-plugin qtdeclarative5-qtquick2-plugin libqt5qml-graphicaleffects qtdeclarative5-dialogs-plugin qtdeclarative5-localstorage-plugin qtdeclarative5-window-plugin

qmake && make
