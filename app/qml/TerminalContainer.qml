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
import Qt5Compat.GraphicalEffects

import "utils.js" as Utils

ShaderTerminal {
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize
    property bool isActive: false
    property string initialWorkingDirectory: ""
    // Profile JSON this terminal starts with; afterwards its profile changes independently.
    property string initialProfile: ""
    readonly property bool terminalHasFocus: terminal.mainTerminal.activeFocus
    signal sessionFinished()

    profile: TerminalProfile {
        Component.onCompleted: {
            if (mainShader.initialProfile) {
                loadProfileString(mainShader.initialProfile)
            }
        }
    }

    property bool loadBloomEffect: profile.bloom > 0 || profile._frameShininess > 0

    id: mainShader
    opacity: profile.windowOpacity * 0.3 + 0.7

    source: terminal.mainSource
    burnInEffect: terminal.burnInEffect
    virtualResolution: terminal.virtualResolution
    screenResolution: Qt.size(
        width * Screen.devicePixelRatio * appSettings.windowScaling,
        height * Screen.devicePixelRatio * appSettings.windowScaling
    )
    bloomSource: bloomSourceLoader.item

    PreprocessedTerminal {
        id: terminal
        anchors.fill: parent
        isActive: mainShader.isActive
        profile: mainShader.profile
        normalizedScale: mainShader.normalizedScale
        initialWorkingDirectory: mainShader.initialWorkingDirectory
        onSessionFinished: mainShader.sessionFinished()
    }

    function activate() {
        terminal.mainTerminal.forceActiveFocus()
    }

    function currentDir() {
        return terminal.currentDir()
    }

    //  EFFECTS  ////////////////////////////////////////////////////////////////
    Loader {
        id: bloomEffectLoader
        active: loadBloomEffect
        asynchronous: true
        width: parent.width * appSettings.bloomQuality
        height: parent.height * appSettings.bloomQuality

        sourceComponent: FastBlur {
            radius: Utils.lint(16, 64, appSettings.bloomQuality)
            source: terminal.mainSource
            transparentBorder: true
        }
    }
    Loader {
        id: bloomSourceLoader
        active: loadBloomEffect
        asynchronous: true
        sourceComponent: ShaderEffectSource {
            id: _bloomEffectSource
            sourceItem: bloomEffectLoader.item
            wrapMode: ShaderEffectSource.Repeat
            hideSource: true
            smooth: true
            visible: false
        }
    }
}
