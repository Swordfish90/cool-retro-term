#
# spec file for package cool-retro-term
#
# Copyright © 2014 Markus S. <kamikazow@web.de>
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

Name:       cool-retro-term
Summary:    Cool Retro Terminal
Version:    0.9
Release:    0%{?dist}
Group:      System/X11/Terminals
License:    GPLv3
URL:        https://github.com/Swordfish90/cool-retro-term

# For this spec file to work, the cool-retro-term sources must be located
# in a directory named cool-retro-term-0.9 (with "0.9" being the version
# number defined above).
# If the sources are compressed in another format than .tar.xz, change the
# file extension accordingly.
Source0:    %{name}-%{version}.tar.xz

BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Declarative)
BuildRequires: pkgconfig(Qt5Gui)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: desktop-file-utils

# Package names only verified with Fedora and openSUSE.
# Should the packages in your distro be named dirrerently,
# see http://en.opensuse.org/openSUSE:Build_Service_cross_distribution_howto
%if 0%{?fedora}
Requires:      qt5-qtbase
Requires:      qt5-qtbase-gui
Requires:      qt5-qtdeclarative
Requires:      qt5-qtgraphicaleffects
Requires:      qt5-qtquickcontrols
%endif

%if 0%{?suse_version}
Requires:      libqt5-qtquickcontrols
Requires:      libqt5-qtbase
Requires:      libQt5Gui5
Requires:      libqt5-qtdeclarative
Requires:      libqt5-qtgraphicaleffects
%endif

%description
cool-retro-term is a terminal emulator which tries to mimic the look and feel
of the old cathode tube screens. It has been designed to be eye-candy,
customizable, and reasonably lightweight.

%prep
%setup -q

%build
qmake-qt5
make %{?_smp_mflags}

%install
# Work around weird qmake behaviour: http://davmac.wordpress.com/2007/02/21/qts-qmake/
make INSTALL_ROOT=%{buildroot} install

desktop-file-install                            \
--dir=${RPM_BUILD_ROOT}%{_datadir}/applications \
%{name}.desktop

%files
%defattr(-,root,root,-)
%doc gpl-2.0.txt gpl-3.0.txt README.md
%{_bindir}/%{name}
%{_libdir}/qt5/qml/
%{_datadir}/applications/%{name}.desktop
# FIXME: Icon
# %{_datadir}/pixmaps/%{name}.png
# %{_datadir}/icons/hicolor/*/*/*

%clean
rm -rf %{buildroot}

%changelog
* Sun Sep  7 14:03:35 UTC 2014 - kamikazow@web.de
- cool-old-term has been renamed to cool-retro-term
- Ported the spec file to CRT's new, way nicer build system <https://github.com/Swordfish90/cool-retro-term/pull/105>

* Fri Aug 29 20:56:20 UTC 2014 - kamikazow@web.de
- Fixed: QtDeclarative-devel is required for "qmlscene" binary

* Fri Aug  1 14:09:35 UTC 2014 - kamikazow@web.de
- First build
- cool-old-term 0.9
