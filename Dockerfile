FROM ubuntu:18.04 as builder

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


#running: docker run -it --privileged --rm -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/run/user/1000 -e XAUTHORITY=$XAUTHORITY -v /run/user/1000:/run/user/1000 -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/dri:/dev/dri retro-term:5
