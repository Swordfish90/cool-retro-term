/*******************************************************************************
* Qt Quick test: the window's IBM audio front end.
*
* Sound is purely optional: with no audio backend, no sample, or no device the
* manager must degrade to silence instead of failing.  These tests therefore
* assert the gating decisions and the reported backend state rather than any
* audible effect, so they hold on a headless CI machine as well.
*******************************************************************************/
import QtQuick
import QtMultimedia
import QtTest

import "../app/qml" as App

Rectangle {
    id: host
    width: 320
    height: 200
    color: "black"

    App.SoundManager {
        id: sound
    }

    TestCase {
        name: "SoundManagerTests"
        when: windowShown

        function init() {
            sound.active = false
            sound.clickEnabled = true
            sound.bellEnabled = true
            sound.clickVolume = 0.5
            sound.bellVolume = 0.5
        }

        function test_isSilentUntilItIsSwitchedOn() {
            compare(sound.backendReady, false)
            compare(sound.backendStatus, "disabled")
            compare(sound.shouldClick({}), false)
            compare(sound.shouldBell(), false)
            compare(sound.keyClick({}), false)
            compare(sound.bell(), false)
            sound.stopAll()             // a no-op, never an error
        }

        function test_everyGateMustBeOpen() {
            sound.active = true
            sound.clickEnabled = false
            sound.bellEnabled = false
            compare(sound.shouldClick({}), false)
            compare(sound.shouldBell(), false)

            sound.clickEnabled = true
            sound.bellEnabled = false
            compare(sound.shouldClick({}), true)
            compare(sound.shouldBell(), false)

            sound.clickEnabled = false
            sound.bellEnabled = true
            compare(sound.shouldClick({}), false)
            compare(sound.shouldBell(), true)

            sound.active = false
            sound.clickEnabled = true
            sound.bellEnabled = true
            compare(sound.shouldClick({}), false)
            compare(sound.shouldBell(), false)
        }

        function test_repeatModifierAndPasteNeverClick() {
            sound.active = true

            compare(sound.shouldClick({ isAutoRepeat: false }), true)
            compare(sound.shouldClick({ isAutoRepeat: true }), false)
            compare(sound.shouldClick({ isModifierOnly: true }), false)
            compare(sound.shouldClick({ fromPaste: true }), false)
            // Nothing at all is reported: defaults behave like a real press.
            compare(sound.shouldClick({}), true)
        }

        function test_reportsItsBackendHonestly() {
            sound.active = true
            // Either the backend resolved or the feature is unavailable; both
            // are legitimate, silence is the only requirement.
            verify(sound.backendStatus === "ready"
                   || sound.backendStatus === "unavailable")

            // With every gate open, the result of a request is exactly
            // "was there a backend to play it?".
            compare(sound.keyClick({}), sound.backendReady)
            compare(sound.bell(), sound.backendReady)

            sound.active = false
            compare(sound.backendReady, false)
            compare(sound.backendStatus, "disabled")
            compare(sound.keyClick({}), false)
            compare(sound.bell(), false)
        }

        function test_bundledSamplesDecode() {
            sound.active = true

            var backend = sound.backendObject
            if (!backend)
                return                      // multimedia unavailable: silence

            // Both samples ship with the application.  A missing or corrupt
            // file would surface as SoundEffect.Error and the feature would
            // silently degrade to nothing.
            tryVerify(function() {
                return backend.click.status === SoundEffect.Ready
                        || backend.click.status === SoundEffect.Error
            }, 2000, "the key click sample never settled")
            compare(backend.click.status, SoundEffect.Ready,
                    "the bundled key click sample must decode")

            tryVerify(function() {
                return backend.bell.status === SoundEffect.Ready
                        || backend.bell.status === SoundEffect.Error
            }, 2000, "the bell sample never settled")
            compare(backend.bell.status, SoundEffect.Ready,
                    "the bundled bell sample must decode")

            compare(backend.click.source.toString(), "qrc:/sounds/keyclick.wav")
            compare(backend.bell.source.toString(), "qrc:/sounds/bell.wav")
        }

        function test_requestsAreAlwaysSafe() {
            sound.active = true
            sound.clickVolume = 0.9
            sound.bellVolume = 0.1

            // Whatever the backend state and the volumes, asking for feedback
            // must never throw.
            sound.keyClick({ isAutoRepeat: false })
            sound.keyClick({ isAutoRepeat: true })
            sound.bell()
            sound.stopAll()
            sound.active = false
            sound.stopAll()
        }

        function test_volumesAreHandedToTheBackend() {
            sound.active = true
            sound.clickVolume = 0.9
            sound.bellVolume = 0.1

            var backend = sound.backendObject
            if (!backend)
                return                      // feature unavailable: silence only

            compare(backend.clickVolume, 0.9)
            compare(backend.bellVolume, 0.1)

            // Out of range volumes are clamped where they are used, so a
            // hostile setting can never blow the speakers.
            sound.clickVolume = 7
            sound.bellVolume = -2
            compare(backend.clamp(backend.clickVolume), 1)
            compare(backend.clamp(backend.bellVolume), 0)
            compare(backend.clamp("not a number"), 0.5)
        }
    }
}
