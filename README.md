#cool-old-term

##Description
cool-old-term is a terminal emulator which tries to mimic the look and feel of the old cathode tube screens.
It has been designed to be eye-candy, customizable, and reasonably lightweight.

It now uses the konsole engine which is powerful and mature.

This terminal emulator requires Qt 5.2 or higher to run.

##Screenshots
![Image](<http://i.imgur.com/NUfvnlu.png>)
![Image](<http://i.imgur.com/4LpfLF8.png>)
![Image](<http://i.imgur.com/MMmM6Ht.png>)

##Build instructions

##Dependencies
Make sure to install these first.

---

**Ubuntu 14.04**

    sudo apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qtdeclarative5-controls-plugin qtdeclarative5-qtquick2-plugin libqt5qml-graphicaleffects qtdeclarative5-dialogs-plugin qtdeclarative5-localstorage-plugin qtdeclarative5-window-plugin

---

**Debian Jessie**

    sudo apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qml-module-qtquick-controls qml-module-qtgraphicaleffects qml-module-qtquick-dialogs qml-module-qtquick-localstorage qml-module-qtquick-window2

---

**Fedora**
This command should install the known fedora dependencies:
```
sudo yum -y install qt5-qtbase qt5-qtbase-devel qt5-qtdeclarative qt5-qtdeclarative-devel qt5-qtgraphicaleffects qt5-qtquickcontrols
```
or:
```
sudo dnf -y install qt5-qtbase qt5-qtbase-devel qt5-qtdeclarative qt5-qtdeclarative-devel qt5-qtgraphicaleffects qt5-qtquickcontrols
```

Compile using the following:
```
git clone https://github.com/Swordifish90/cool-old-term.git
cd cool-old-term/konsole-qml-plugin
qmake-qt5 && make && make install
cd ..
./cool-old-term
```

---

**Arch Linux**

    sudo pacman -S qt5-base qt5-declarative qt5-quickcontrols qt5-graphicaleffects
    
You can also install this [package](https://aur.archlinux.org/packages/cool-old-term-git/) directly via the [AUR](https://aur.archlinux.org):

    yaourt -S aur/cool-old-term-git

---

**openSUSE**

Add repository with latest Qt 5 (this is only needed on openSUSE 13.1, Factory already has it):

    sudo zypper ar http://download.opensuse.org/repositories/KDE:/Qt5/openSUSE_13.1/ KDE:Qt5

Install dependencies:

    sudo zypper install libqt5-qtbase-devel libqt5-qtdeclarative-devel libqt5-qtquickcontrols libqt5-qtgraphicaleffects

Compile:

```bash
git clone https://github.com/Swordifish90/cool-old-term.git
cd cool-old-term/konsole-qml-plugin
qmake-qt5 && make && make install
cd ..
./cool-old-term
```

---

**Anyone else**

Install Qt directly from here http://qt-project.org/downloads . Once done export them in you path (replace "_/opt/Qt5.3.1/5.3/gcc_64/bin_" with your correct folder):
    
    export PATH=/opt/Qt5.3.1/5.3/gcc_64/bin/:$PATH

###Compile
Once you installed all dependencies (Qt is installed and in your path) you need to compile and run the application: 

```bash
# Get it from GitHub
git clone https://github.com/Swordifish90/cool-old-term.git

# Build it
cd cool-old-term
cd konsole-qml-plugin
qmake && make && make install
cd ..

# Have fun!
./cool-old-term

# Application menu shortcut
cd
sudo mv cool-old-term /opt
wget https://www.dropbox.com/s/2ssvey53s7pfim5/coolterm.desktop
sudo mv coolterm.desktop /usr/share/applications
```
