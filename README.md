# Cool-Retro-Term

## Description

Cool-Retro-Term is a terminal emulator which mimics the look and feel of the
old cathode tube screens. It has been designed to be eye-candy, customizable,
and reasonably lightweight.

It uses the QML port of qtermwidget (Konsole) developed by me:
<https://github.com/Swordfish90/qmltermwidget>.

This terminal emulator works on Linux and OSX and requires Qt 5.2 or higher.

### Contents

* [Screenshots](#screenshots)
* [Install](#install-cool-retro-term)
  * [From package manager or PPA](#install-cool-retro-term)
  * [From source (Linux)](#build-from-source-on-linux)
    * [Dependencies](#install-dependencies-first)
    * [Compile](#then-compile)
  * [From source (OSX)](#build-from-source-on-osx)
* [Donate](#donations)

---

## Screenshots

![cool-retro-term preview](<http://i.imgur.com/I6wq1cC.png>)

![preview of a man page (for gcc)](<http://i.imgur.com/12EqlpL.png>)

![preview of midnight commander](<http://i.imgur.com/Lx0acQz.jpg>)

---

## Install Cool-Retro-Term

#### Arch

Install [this package](https://aur.archlinux.org/packages/cool-retro-term-git/) directly via the [AUR](https://aur.archlinux.org):

```
yaourt -S aur/cool-retro-term-git
```

or install the precompiled package:

```
pacman -S cool-retro-term
```

#### Fedora and openSUSE

Grab the package from [Open Build Service](http://software.opensuse.org/package/cool-retro-term).

#### Gentoo

Gentoo users can now install the first release "1.0" from a 3rd-party
repository preferably via layman:

```
USE="subversion git" emerge app-portage/layman
wget https://www.gerczei.eu/files/gerczei.xml -O /etc/layman/overlays/gerczei.xml
layman -f -a qt -a gerczei # those who've added the repo already should sync instead via 'layman -s gerczei'
ACCEPT_KEYWORDS="~*" emerge =x11-terms/cool-retro-term-1.0.0-r1::gerczei
```

The live ebuild (version 9999-r1) tracking the bleeding-edge WIP codebase also
remains available.

A word of warning: USE flags and keywords are to be added to portage's
configuration files and every emerge operation should be executed with `-p`
(short option for `--pretend`) appended to the command line first as per best
practice!

#### Ubuntu 14.04 LTS (Trusty) through 15.10 (Wily)

Use [this PPA](https://launchpad.net/~bugs-launchpad-net-falkensweb)

#### OSX

Get the latest dmg from the release page: <https://github.com/Swordfish90/cool-retro-term/releases>

---

## Build from source on Linux

### Install dependencies first

---

#### Ubuntu 14.04

```
sudo apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qtdeclarative5-controls-plugin qtdeclarative5-qtquick2-plugin libqt5qml-graphicaleffects qtdeclarative5-dialogs-plugin qtdeclarative5-localstorage-plugin qtdeclarative5-window-plugin
```

---

#### Ubuntu 16.10

```
sudo apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qml-module-qtquick-controls qtdeclarative5-qtquick2-plugin libqt5qml-graphicaleffects qml-module-qtquick-dialogs qtdeclarative5-localstorage-plugin qtdeclarative5-window-plugin
```

---

#### Debian Jessie

```
sudo apt-get install build-essential qmlscene qt5-qmake qt5-default qtdeclarative5-dev qml-module-qtquick-controls qml-module-qtgraphicaleffects qml-module-qtquick-dialogs qml-module-qtquick-localstorage qml-module-qtquick-window2
```

---

#### Fedora

```
sudo yum -y install qt5-qtbase qt5-qtbase-devel qt5-qtdeclarative qt5-qtdeclarative-devel qt5-qtgraphicaleffects qt5-qtquickcontrols redhat-rpm-config
```

or:

```
sudo dnf -y install qt5-qtbase qt5-qtbase-devel qt5-qtdeclarative qt5-qtdeclarative-devel qt5-qtgraphicaleffects qt5-qtquickcontrols redhat-rpm-config
```

---

#### Arch

```
sudo pacman -S qt5-base qt5-declarative qt5-quickcontrols qt5-graphicaleffects
```

---

#### openSUSE

Add repository with latest Qt 5 (this is only needed on openSUSE 13.1, Factory
already has it):

```
sudo zypper ar http://download.opensuse.org/repositories/KDE:/Qt5/openSUSE_13.1/ KDE:Qt5
```

Install dependencies:

```
sudo zypper install libqt5-qtbase-devel libqt5-qtdeclarative-devel libqt5-qtquickcontrols libqt5-qtgraphicaleffects
```

---

#### Anyone else

Install Qt directly from <http://qt-project.org/downloads>, then add it to your
path (replace `_/opt/Qt5.3.1/5.3/gcc_64/bin_` with your correct folder):

```
export PATH=/opt/Qt5.3.1/5.3/gcc_64/bin/:$PATH
```

---

### Then compile

Once you installed all dependencies (Qt is installed and in your path) you need
to compile and run the application:

```sh
# Get it from GitHub
git clone --recursive https://github.com/Swordfish90/cool-retro-term.git

cd cool-retro-term

# Compile (Fedora and OpenSUSE user should use qmake-qt5 instead of qmake)
qmake && make

# Have fun!
./cool-retro-term
```

---

## Build from source on OSX

1. Install [Xcode](https://developer.apple.com/xcode/) and agree to the licence agreement
2. Install using Brew or MacPorts:

#### Brew

```sh
brew install qt5

git clone --recursive https://github.com/Swordfish90/cool-retro-term.git

export CPPFLAGS="-I/usr/local/opt/qt5/include"
export LDFLAGS="-L/usr/local/opt/qt5/lib"
export PATH=/usr/local/opt/qt5/bin:$PATH

cd cool-retro-term

qmake && make

mkdir cool-retro-term.app/Contents/PlugIns

cp -r qmltermwidget/QMLTermWidget cool-retro-term.app/Contents/PlugIns

open cool-retro-term.app
```

#### MacPorts

```sh
sudo port install qt5

git clone --recursive https://github.com/Swordfish90/cool-retro-term.git

cd cool-retro-term

/opt/local/libexec/qt5/bin/qmake && make

mkdir cool-retro-term.app/Contents/PlugIns

cp -r qmltermwidget/QMLTermWidget cool-retro-term.app/Contents/PlugIns

open cool-retro-term.app
```

## Donations
I made this project in my spare time because I love what I'm doing. If you are
enjoying it, why not [buy me a beer](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=flscogna%40gmail%2ecom&lc=IT&item_name=Filippo%20Scognamiglio&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted) .

You can also add "bounties" on your favourite issues. More information on the
[Bountysource](https://www.bountysource.com/teams/crt/issues) page.
