#!/bin/sh#

# Install qt5 with homebrew
brew install qt5

# Set export paths 
export PATH=/usr/local/opt/qt5/bin:$PATH
export LDFLAGS="-L/usr/local/opt/qt5/lib"
export CPPFLAGS="-L/usr/local/opt/qt5/include"

# Install
cd konsole-qml-plugin
qmake && make && make install

# Add qt path to shell config file

shellCF=~/.${SHELL##*/}rc

echo PATH=/usr/local/opt/qt5/bin:$PATH >> $shellCF
source $shellCF

