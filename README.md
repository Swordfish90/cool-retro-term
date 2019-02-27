# cool-cyber-term
## Description
this is a modified version of cool-retro-term, which enables you to add background images to crt.
You will have to specify a folder with all your background images you want to use, aswell as a opacity factor if you want to still see your desktop, and a scaling factor, in case you want the pictures to be pixellated. all this has to be done in the file background_selection.py.

The used image will then be chosen randomly, each time you start a new terminal.

You may want to add a shortcut, which can be done as followed:
1. go to settings -> devices -> keyboard
2. change the "launch terminal" shortcut to anything but ctrl-alt-t
3. add a new shortcut and use as shortcut ctrl-alt-t and use as command '/opt/cool-cyber-term/start.sh' 

## Screenshot
![Imgur](https://i.imgur.com/q47kwHt.jpg)

## Install
This was tested on ubuntu 18.04.

### Install Dependencies

    sudo apt-get install build-essential qml-module-qtgraphicaleffects qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qtquick-controls qml-module-qtquick-dialogs qmlscene qt5-default qt5-qmake qtdeclarative5-dev qtdeclarative5-localstorage-plugin qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin imagemagick python3
    
### Compile 

```bash
# Get it!
git clone --recursive https://github.com/neurudan/cool-cyber-term.git

# Move it!
sudo mv cool-cyber-term /opt/
sudo chmod -R a=rwx /opt/cool-cyber-term
cd /opt/cool-cyber-term
sudo cp cool-cyber-term.desktop /usr/share/applications

# Build it!
qmake && make

# Use it!
```
