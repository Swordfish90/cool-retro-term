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

QtObject {
    id: timeManager

    property bool enableTimer: false
    property real time: 0

    property bool hasVisibleWindows: false
    property bool hasContinuousAnimation: false
    property bool hasTemporaryAnimation: false
    property real temporaryAnimationDeadline: 0
    property real timeOriginInSeconds: Date.now() / 1000

    property int framesPerUpdate: Math.max(1, appSettings.effectsFrameSkip)
    property int _frameCounter: 0

    function nowInSeconds() {
        return Date.now() / 1000 - timeOriginInSeconds
    }

    function updateTimerState() {
        enableTimer = hasVisibleWindows && (hasContinuousAnimation || hasTemporaryAnimation)
    }

    function scheduleTemporaryAnimationStop() {
        var remainingMs = Math.max(0, Math.ceil((temporaryAnimationDeadline - nowInSeconds()) * 1000))

        if (remainingMs <= 0) {
            hasTemporaryAnimation = false
            updateTimerState()
            return
        }

        temporaryAnimationTimer.interval = remainingMs
        temporaryAnimationTimer.restart()
    }

    function requestTemporaryAnimation(durationSeconds) {
        if (durationSeconds <= 0) {
            return
        }

        time = nowInSeconds()
        temporaryAnimationDeadline = Math.max(temporaryAnimationDeadline, time + durationSeconds)
        hasTemporaryAnimation = true
        updateTimerState()
        scheduleTemporaryAnimationStop()
    }

    property var frameDriver: FrameAnimation {
        running: enableTimer
        onTriggered: {
            timeManager._frameCounter += 1

            if (timeManager._frameCounter >= timeManager.framesPerUpdate) {
                time = timeManager.nowInSeconds()
                timeManager._frameCounter = 0
            }
        }
    }

    property var temporaryAnimationTimer: Timer {
        repeat: false
        running: false
        onTriggered: {
            timeManager.time = timeManager.nowInSeconds()

            if (timeManager.temporaryAnimationDeadline > timeManager.time) {
                timeManager.scheduleTemporaryAnimationStop()
                return
            }

            timeManager.hasTemporaryAnimation = false
            timeManager.updateTimerState()
        }
    }

    onEnableTimerChanged: if (!enableTimer) _frameCounter = 0
    onFramesPerUpdateChanged: _frameCounter = 0
    onHasVisibleWindowsChanged: updateTimerState()
    onHasContinuousAnimationChanged: updateTimerState()
    onHasTemporaryAnimationChanged: updateTimerState()
}
