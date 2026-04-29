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
        Layout.fillHeight: true
        padding: appSettings.defaultMargin
        GridLayout {
            anchors.fill: parent
            columns: 2
            Label {
                text: qsTr("Source")
            }
            RowLayout {
                Layout.fillWidth: true
                RadioButton {
                    text: qsTr("Bundled")
                    checked: appSettings.fontSource === appSettings.bundled_fonts
                    onClicked: {
                        appSettings.fontSource = appSettings.bundled_fonts
                    }
                }
                RadioButton {
                    text: qsTr("System")
                    checked: appSettings.fontSource === appSettings.system_fonts
                    onClicked: {
                        appSettings.fontSource = appSettings.system_fonts
                    }
                }
            }
            Label {
                text: qsTr("Rendering")
                enabled: appSettings.fontSource === appSettings.bundled_fonts
            }
            ComboBox {
                id: renderingBox

                property string selectedElement: model[currentIndex]

                Layout.fillWidth: true
                model: [qsTr("Default"), qsTr("Scanlines"), qsTr("Pixels"), qsTr("Sub-Pixels"), qsTr("Modern")]
                currentIndex: appSettings.rasterization
                onCurrentIndexChanged: {
                    appSettings.rasterization = currentIndex
                }
                enabled: appSettings.fontSource === appSettings.bundled_fonts
            }
            Label {
                text: qsTr("Name")
            }
            ComboBox {
                id: fontChanger
                Layout.fillWidth: true
                model: appSettings.filteredFontList
                textRole: "text"
                onActivated: {
                    var font = appSettings.filteredFontList.get(currentIndex)

                    // If selecting a high-res font while not in Modern mode,
                    // switch to Modern to render at full resolution.
                    if (!font.lowResolutionFont && appSettings.rasterization !== appSettings.modern_rasterization) {
                        appSettings.rasterization = appSettings.modern_rasterization
                    }
                    // If selecting a low-res font while in Modern mode, switch back to default.
                    if (font.lowResolutionFont && appSettings.rasterization === appSettings.modern_rasterization) {
                        appSettings.rasterization = appSettings.no_rasterization
                    }

                    appSettings.fontName = font.name
                }
                function updateIndex() {
                    for (var i = 0; i < appSettings.filteredFontList.count; i++) {
                        var font = appSettings.filteredFontList.get(i)
                        if (font.name === appSettings.fontName) {
                            currentIndex = i
                            return
                        }
                    }
                    currentIndex = 0
                }
                Connections {
                    target: appSettings.fontManager

                    onTerminalFontChanged: {
                        fontChanger.updateIndex()
                    }

                    onFilteredFontListChanged: {
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
            Label {
                text: qsTr("Line Spacing")
            }
            RowLayout {
                Layout.fillWidth: true
                Slider {
                    Layout.fillWidth: true
                    id: lineSpacingChanger
                    onValueChanged: appSettings.lineSpacing = value
                    value: appSettings.lineSpacing
                    stepSize: 0.01
                    from: 0.0
                    to: 1.0
                }
                SizedLabel {
                    text: Math.round(lineSpacingChanger.value * 100) + "%"
                }
            }
        }
    }
    GroupBox {
        title: qsTr("Colors")
        Layout.fillWidth: true
        Layout.fillHeight: true
        padding: appSettings.defaultMargin
        ColumnLayout {
            anchors.fill: parent
            ColumnLayout {
                Layout.fillWidth: true
                CheckableSlider {
                    name: qsTr("Chroma Color")
                    onNewValue: function(newValue) { appSettings.chromaColor = newValue }
                    value: appSettings.chromaColor
                }
                CheckableSlider {
                    name: qsTr("Saturation Color")
                    onNewValue: function(newValue) { appSettings.saturationColor = newValue }
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
                ColorButton {
                    name: qsTr("Frame")
                    height: 50
                    Layout.fillWidth: true
                    onColorSelected: appSettings._frameColor = color
                    color: appSettings._frameColor
                }
            }
        }
    }
}
