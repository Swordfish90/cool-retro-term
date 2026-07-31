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
    // Maximum length of a user-assigned tab name.
    readonly property int maxTabNameLength: 30
    // Bumped whenever a tab's title changes so currentTitle re-evaluates.
    property int titleRevision: 0
    readonly property string currentTitle: (titleRevision, tabDisplayName(currentIndex))
    property alias currentIndex: tabBar.currentIndex
    readonly property int count: tabsModel.count
    property size terminalSize: Qt.size(0, 0)

    function normalizeTitle(rawTitle) {
        if (rawTitle === undefined || rawTitle === null) {
            return ""
        }
        return String(rawTitle).trim()
    }

    // The name shown for a tab. With named tabs enabled, a user-assigned custom
    // name wins; otherwise the shell title is prefixed with the tab's
    // left-to-right position number (e.g. "1: bash"). With named tabs disabled,
    // the shell title is shown as-is. Always returns a non-empty string, so it
    // is suitable for the window title.
    function tabDisplayName(index) {
        var entry = tabsModel.get(index)
        if (!entry) {
            return "cool-retro-term"
        }
        if (appSettings.enableNamedTabs && entry.customTitle && entry.customTitle.length > 0) {
            return entry.customTitle
        }
        var base = entry.title && entry.title.length > 0 ? entry.title : "cool-retro-term"
        if (appSettings.enableNamedTabs) {
            return (index + 1) + ": " + base
        }
        return base
    }

    function addTab() {
        tabsModel.append({ title: "", customTitle: "" })
        tabBar.currentIndex = tabsModel.count - 1
        titleRevision++
    }

    function closeTab(index) {
        if (tabsModel.count <= 1) {
            terminalWindow.close()
            return
        }

        tabsModel.remove(index)
        tabBar.currentIndex = Math.min(tabBar.currentIndex, tabsModel.count - 1)
        // Tab positions shifted, so refresh the position-number labels.
        titleRevision++
    }

    ListModel {
        id: tabsModel
    }

    Component.onCompleted: addTab()

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

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    focusPolicy: Qt.NoFocus

                    Repeater {
                        model: tabsModel
                        TabButton {
                            id: tabButton

                            // True while this tab's name is being edited inline.
                            property bool editing: false

                            function beginEditing() {
                                if (!appSettings.enableNamedTabs) {
                                    return
                                }
                                // Prefill with the existing custom name, or the shell
                                // title (without the position-number prefix).
                                nameField.text = model.customTitle && model.customTitle.length > 0
                                        ? model.customTitle
                                        : (model.title && model.title.length > 0 ? model.title : "")
                                editing = true
                                nameField.forceActiveFocus()
                                nameField.selectAll()
                            }

                            function commitEditing() {
                                if (!editing) {
                                    return
                                }
                                editing = false
                                tabsModel.setProperty(index, "customTitle",
                                                      tabsRoot.normalizeTitle(nameField.text))
                                tabsRoot.titleRevision++
                            }

                            function cancelEditing() {
                                editing = false
                            }

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors { leftMargin: innerPadding; rightMargin: innerPadding }
                                spacing: innerPadding

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Label {
                                        id: tabLabel
                                        anchors.fill: parent
                                        visible: !tabButton.editing
                                        // Referencing the reactive model roles and titleRevision
                                        // keeps the label in sync when the shell title, the custom
                                        // name, or the tab ordering changes. Empty when named tabs
                                        // are disabled (old behaviour: no title text).
                                        text: (model.title, model.customTitle, tabsRoot.titleRevision,
                                               appSettings.enableNamedTabs ? tabsRoot.tabDisplayName(index) : "")
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            // Clicking an inactive tab just selects it; clicking the
                                            // already-active tab's label begins inline renaming (only
                                            // when named tabs are enabled).
                                            onClicked: {
                                                if (tabBar.currentIndex === index) {
                                                    tabButton.beginEditing()
                                                } else {
                                                    tabBar.currentIndex = index
                                                }
                                            }
                                        }
                                    }

                                    TextField {
                                        id: nameField
                                        anchors.fill: parent
                                        visible: tabButton.editing
                                        maximumLength: tabsRoot.maxTabNameLength
                                        verticalAlignment: Text.AlignVCenter
                                        selectByMouse: true
                                        onEditingFinished: tabButton.commitEditing()
                                        onActiveFocusChanged: {
                                            if (!activeFocus) {
                                                tabButton.commitEditing()
                                            }
                                        }
                                        Keys.onReturnPressed: tabButton.commitEditing()
                                        Keys.onEnterPressed: tabButton.commitEditing()
                                        Keys.onEscapePressed: tabButton.cancelEditing()
                                    }
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

                ToolButton {
                    id: addTabButton
                    text: "+"
                    focusPolicy: Qt.NoFocus
                    Layout.fillHeight: true
                    padding: innerPadding
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: tabsRoot.addTab()
                }
            }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            Repeater {
                model: tabsModel
                TerminalContainer {
                    property bool shouldHaveFocus: terminalWindow.active && StackLayout.isCurrentItem
                    isActive: StackLayout.isCurrentItem
                    onShouldHaveFocusChanged: {
                        if (shouldHaveFocus) {
                            activate()
                        }
                    }
                    onTitleChanged: {
                        tabsModel.setProperty(index, "title", normalizeTitle(title))
                        tabsRoot.titleRevision++
                    }
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onSessionFinished: tabsRoot.closeTab(index)
                    onTerminalSizeChanged: updateTerminalSize()

                    function updateTerminalSize() {
                        // Every tab will have the same size so we can simply take the first one.
                        if (index == 0) {
                            tabsRoot.terminalSize = terminalSize
                        }
                    }
                }
            }
        }
    }
}
