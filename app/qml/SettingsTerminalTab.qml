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
import QtQuick 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQml 2.0

import "Components"

ColumnLayout {

    GroupBox {
        title: qsTr("Font")
        Layout.fillWidth: true
        GridLayout {
            anchors.fill: parent
            columns: 2
            Label {
                text: qsTr("Rasterization")
            }
            ComboBox {
                id: rasterizationBox

                property string selectedElement: model[currentIndex]

                Layout.fillWidth: true
                model: [qsTr("Default"), qsTr("Scanlines"), qsTr("Pixels"), qsTr("Sub-Pixels")]
                currentIndex: appSettings.rasterization
                onCurrentIndexChanged: {
                    appSettings.rasterization = currentIndex
                }
            }
            Label {
                text: qsTr("Name")
            }
            ComboBox {
                id: fontChanger
                Layout.fillWidth: true
                model: appSettings.fontlist
                textRole: "text"
                onActivated: {
                    var name = appSettings.fontlist.get(index).name
                    appSettings.fontNames[appSettings.rasterization] = name
                    appSettings.handleFontChanged()
                }
                function updateIndex() {
                    var name = appSettings.fontNames[appSettings.rasterization]
                    var index = appSettings.getIndexByName(name)
                    if (index !== undefined)
                        currentIndex = index
                }
                Connections {
                    target: appSettings

                    onTerminalFontChanged: {
                        fontChanger.updateIndex()
                    }
                }
                Component.onCompleted: updateIndex()
            }
            Label {
                text: qsTr("Scaling")
            }
            RowLayout {
                Layout.fillWidth: true
                Slider {
                    Layout.fillWidth: true
                    id: fontScalingChanger
                    onValueChanged: appSettings.fontScaling = value
                    value: appSettings.fontScaling
                    stepSize: 0.05
                    from: appSettings.minimumFontScaling
                    to: appSettings.maximumFontScaling
                }
                SizedLabel {
                    text: Math.round(fontScalingChanger.value * 100) + "%"
                }
            }
            Label {
                text: qsTr("Font Width")
            }
            RowLayout {
                Layout.fillWidth: true
                Slider {
                    Layout.fillWidth: true
                    id: widthChanger
                    onValueChanged: appSettings.fontWidth = value
                    value: appSettings.fontWidth
                    stepSize: 0.05
                    from: 0.5
                    to: 1.5
                }
                SizedLabel {
                    text: Math.round(widthChanger.value * 100) + "%"
                }
            }
        }
    }
    GroupBox {
        title: qsTr("Cursor")
        Layout.fillWidth: true
        ColumnLayout {
            anchors.fill: parent
            CheckBox {
                id: blinkingCursor
                text: qsTr("Blinking Cursor")
                checked: appSettings.blinkingCursor
                onCheckedChanged: appSettings.blinkingCursor = checked
            }
            Binding {
                target: blinkingCursor
                property: "checked"
                value: appSettings.blinkingCursor
            }
        }
    }
    GroupBox {
        title: qsTr("Colors")
        Layout.fillWidth: true
        ColumnLayout {
            anchors.fill: parent
            ColumnLayout {
                Layout.fillWidth: true
                CheckableSlider {
                    name: qsTr("Chroma Color")
                    onNewValue: appSettings.chromaColor = newValue
                    value: appSettings.chromaColor
                }
                CheckableSlider {
                    name: qsTr("Saturation Color")
                    onNewValue: appSettings.saturationColor = newValue
                    value: appSettings.saturationColor
                    enabled: appSettings.chromaColor !== 0
                }
            }
            RowLayout {
                Layout.fillWidth: true
                ColorButton {
                    name: qsTr("Font")
                    height: 50
                    Layout.fillWidth: true
                    onColorSelected: appSettings._fontColor = color
                    color: appSettings._fontColor
                }
                ColorButton {
                    name: qsTr("Background")
                    height: 50
                    Layout.fillWidth: true
                    onColorSelected: appSettings._backgroundColor = color
                    color: appSettings._backgroundColor
                }
            }
        }
    }
}
