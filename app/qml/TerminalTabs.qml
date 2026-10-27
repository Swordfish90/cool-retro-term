/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

Item {
    id: tabsRoot

    readonly property int innerPadding: 6
    readonly property string currentTitle: tabsModel.get(currentIndex)?.title ?? "cool-retro-term"
    property alias currentIndex: tabBar.currentIndex
    readonly property int count: tabsModel.count
    property size terminalSize: Qt.size(0, 0)

    // Tilix-like strip with a live preview of every tab.
    property bool quickViewOpen: false
    onCountChanged: {
        if (count <= 1) {
            closeQuickView()
        }
    }

    readonly property Item currentTabItem: tabsRepeater.count > 0 && currentIndex >= 0 ? tabsRepeater.itemAt(currentIndex) : null
    // Profile of the focused terminal of the current tab.
    readonly property TerminalProfile activeProfile: currentTabItem && currentTabItem.focusedTerminal
                                                     ? currentTabItem.focusedTerminal.profile : null

    function normalizeTitle(rawTitle) {
        if (rawTitle === undefined || rawTitle === null) {
            return ""
        }
        return String(rawTitle).trim()
    }

    // New tabs start with the given profile JSON, by default a copy of the focused terminal's.
    function addTab(profileString) {
        if (profileString === undefined) {
            profileString = activeProfile ? activeProfile.composeProfileString() : terminalWindow.initialProfile
        }
        tabsModel.append({ title: "", profile: profileString })
        tabBar.currentIndex = tabsModel.count - 1
    }

    function closeTab(index) {
        if (tabsModel.count <= 1) {
            terminalWindow.close()
            return
        }

        tabsModel.remove(index)
        tabBar.currentIndex = Math.min(tabBar.currentIndex, tabsModel.count - 1)
    }

    function openQuickView() {
        quickViewOpen = true
    }

    function closeQuickView() {
        if (!quickViewOpen)
            return

        quickViewOpen = false
        if (currentTabItem) {
            currentTabItem.activateFocusedTerminal()
        }
    }

    function currentTab() {
        return currentTabItem
    }

    // Qt.Horizontal puts the new terminal to the right, Qt.Vertical below.
    function splitCurrent(orientation) {
        var tab = currentTab()
        if (tab) {
            tab.split(orientation)
        }
    }

    function closeCurrentTerminal() {
        var tab = currentTab()
        if (tab) {
            tab.closeFocusedTerminal()
        }
    }

    function focusNeighbor(direction) {
        var tab = currentTab()
        if (tab) {
            tab.focusNeighbor(direction)
        }
    }

    // Destroy all terminals while the window is still alive. If they are left to be
    // deleted as children of the window, Qt 6.4 crashes in clearFocusInScope.
    function releaseTabs() {
        tabsModel.clear()
    }

    ListModel {
        id: tabsModel
    }

    Component.onCompleted: addTab(terminalWindow.initialProfile)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: tabRow
            Layout.fillWidth: true
            height: rowLayout.implicitHeight
            color: palette.window
            visible: tabsModel.count > 1

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                spacing: 0

                ToolButton {
                    id: quickViewButton
                    // "(current/total) arrow": toggles the tab quick view.
                    text: "(" + (tabsRoot.currentIndex + 1) + "/" + tabsModel.count + ") "
                          + (tabsRoot.quickViewOpen ? "\u2191" : "\u2193")
                    checked: tabsRoot.quickViewOpen
                    focusPolicy: Qt.NoFocus
                    Layout.fillHeight: true
                    padding: innerPadding
                    onClicked: tabsRoot.quickViewOpen ? tabsRoot.closeQuickView() : tabsRoot.openQuickView()
                }

                ToolButton {
                    id: addTabButton
                    text: "+"
                    focusPolicy: Qt.NoFocus
                    Layout.fillHeight: true
                    padding: innerPadding
                    onClicked: tabsRoot.addTab()
                }

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    focusPolicy: Qt.NoFocus

                    Repeater {
                        model: tabsModel
                        TabButton {
                            id: tabButton
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors { leftMargin: innerPadding; rightMargin: innerPadding }
                                spacing: innerPadding

                                Label {
                                    text: model.title
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ToolButton {
                                    text: "\u00d7"
                                    focusPolicy: Qt.NoFocus
                                    padding: innerPadding
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: tabsRoot.closeTab(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Only the current tab is shown. While the quick view is open the other tabs are made
        // visible too, so it can render their previews; it hides them from the scene itself.
        Item {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                id: tabsRepeater
                model: tabsModel
                TerminalTab {
                    isCurrent: index === tabsRoot.currentIndex
                    initialProfile: model.profile
                    onTitleChanged: tabsModel.setProperty(index, "title", normalizeTitle(title))
                    anchors.fill: parent
                    visible: isCurrent || tabsRoot.quickViewOpen
                    enabled: isCurrent
                    z: isCurrent ? 1 : 0
                    onFinished: tabsRoot.closeTab(index)
                    onTerminalSizeChanged: updateTerminalSize()
                    onIsCurrentChanged: updateTerminalSize()

                    function updateTerminalSize() {
                        if (isCurrent) {
                            tabsRoot.terminalSize = terminalSize
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                z: 2
                active: tabsRoot.quickViewOpen
                sourceComponent: TabQuickView {
                    model: tabsModel
                    tabs: tabsRepeater
                    currentIndex: tabsRoot.currentIndex
                    onTabSelected: function(index) {
                        tabsRoot.currentIndex = index
                        tabsRoot.closeQuickView()
                    }
                    onCloseRequested: tabsRoot.closeQuickView()
                }
            }
        }
    }
}
