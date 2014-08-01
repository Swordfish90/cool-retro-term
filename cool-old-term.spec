#
# spec file for package cool-old-term
#
# Copyright © 2014 Markus S. <kamikazow@web.de>
#
# Contains snippets from https://aur.archlinux.org/packages/cool-old-term-git
# by Glen Oakley <goakley123@gmail.com>
# and Doug Newgard <scimmia at archlinux dot info>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

Name:       cool-old-term
Summary:    Cool Old Terminal
Version:    0.9
Release:    0%{?dist}
Group:      System/GUI/Other
License:    GPLv3
URL:        http://swordfishslabs.wordpress.com/

# For this spec file to work, the ympd sources must be located in a directory
# named cool-old-term-0.9 (with "0.9" being the version number defined above).
# If the sources are compressed in another format than ZIP, change the
# file extension accordingly.
Source0:    %{name}-%{version}.zip

# Package names only verified with Fedora and openSUSE.
# Should the packages in your distro be named dirrerently,
# see http://en.opensuse.org/openSUSE:Build_Service_cross_distribution_howto
%if 0%{?fedora}
BuildRequires: qt5-qtbase-devel
BuildRequires: qt5-qtdeclarative-devel
BuildRequires: unzip
Requires:      qt5-qtbase
Requires:      qt5-qtbase-gui
Requires:      qt5-qtdeclarative
Requires:      qt5-qtgraphicaleffects
Requires:      qt5-qtquickcontrols
%endif

%if 0%{?suse_version}
BuildRequires: libqt5-qtbase-devel
BuildRequires: libqt5-qtdeclarative-devel
BuildRequires: unzip
Requires:      libqt5-qtquickcontrols
Requires:      libqt5-qtbase
Requires:      libQt5Gui5
Requires:      libqt5-qtdeclarative
Requires:      libqt5-qtgraphicaleffects
%endif

%description
cool-old-term is a terminal emulator which tries to mimic the look and feel
of the old cathode tube screens. It has been designed to be eye-candy,
customizable, and reasonably lightweight.

%prep
%setup -q

%build
pushd konsole-qml-plugin
qmake-qt5 -o Makefile konsole-qml-plugin.pro
make %{?_smp_mflags}
popd

%install
pushd konsole-qml-plugin
%{make_install}
popd

install -d "%{buildroot}/%{_datadir}/%{name}/" "%{buildroot}/%{_bindir}"
cp -a app imports "%{buildroot}/%{_datadir}/%{name}/"
echo -e '#!/bin/bash\nqmlscene -I /usr/share/cool-old-term/{imports,app/main.qml}' > "%{buildroot}/%{_bindir}/%{name}"
chmod 755 "%{buildroot}/%{_bindir}/%{name}"

%files
%doc gpl-2.0.txt gpl-3.0.txt README.md
%{_bindir}/%{name}
%{_datadir}/%{name}
# FIXME: Icon and Desktop files
# %{_datadir}/applications/%{name}.desktop
# %{_datadir}/pixmaps/%{name}.png
# %{_datadir}/icons/hicolor/*/*/*

%clean
rm -rf %{buildroot}
