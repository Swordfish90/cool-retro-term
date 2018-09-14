FROM ubuntu:18.04

#TODO: Clean up after installation and building
RUN apt-get update && apt-get install -y  build-essential qml-module-qtgraphicaleffects qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qtquick-controls qml-module-qtquick-dialogs qmlscene qt5-default qt5-qmake qtdeclarative5-dev qtdeclarative5-localstorage-plugin qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin

COPY . /app
WORKDIR /app
RUN qmake && make

RUN adduser user --home /home/user
WORKDIR /app
RUN chmod +x /app/cool-retro-term
USER user
ENTRYPOINT ["./cool-retro-term"]
