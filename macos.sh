#!/bin/bash

export CPPFLAGS="-I/usr/local/opt/qt5/include"
export LDFLAGS="-L/usr/local/opt/qt5/lib"
export PATH=/usr/local/opt/qt5/bin:$PATH

rm -rf cool-retro-term.app

qmake && make
mkdir cool-retro-term.app/Contents/PlugIns
cp -r qmltermwidget/QMLTermWidget cool-retro-term.app/Contents/PlugIns
