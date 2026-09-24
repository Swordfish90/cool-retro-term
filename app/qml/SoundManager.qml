/*******************************************************************************
* Audible feedback front end (IBM key click + terminal bell).
*
* The QtMultimedia import lives in SoundBackend.qml, *not* here, and the
* backend is instantiated through a Component/Loader.  If Qt Multimedia is
* missing or cannot open an audio device, instantiation simply fails, the
* Loader stays empty and every call becomes a no-op: sound is a purely
* optional feature and must never break the terminal.
*
* Free of application globals so the test suite can drive it directly.
*******************************************************************************/
import QtQuick

import "logic/sound.js" as SoundLogic

QtObject {
    id: manager

    /** Master gate. Everything is silent while this is false. */
    property bool active: false
    property bool clickEnabled: true
    property bool bellEnabled: true
    property real clickVolume: 0.5
    property real bellVolume: 0.5

    /** Set once the backend resolved; useful for tests and diagnostics. */
    readonly property bool backendReady: backend.item !== null
    readonly property string backendStatus: backend.item ? "ready" : (active ? "unavailable" : "disabled")

    /**
     * The resolved backend object, or null when the feature is unavailable.
     * Kept as an untyped property on purpose: it only exists so diagnostics
     * (and the test suite) can reach the volumes without guessing.
     */
    readonly property var backendObject: backend.item

    property Loader backend: Loader {
        sourceComponent: manager.active ? backendComponent : null
    }

    property Component backendComponent: Component {
        SoundBackend {
            clickVolume: manager.clickVolume
            bellVolume: manager.bellVolume
        }
    }

    /** True when the supplied info object says this press should click. */
    function shouldClick(info) {
        return SoundLogic.shouldClick({
            audioEnabled: active,
            keyClick: clickEnabled
        }, info === undefined ? {} : info)
    }

    function shouldBell() {
        return SoundLogic.shouldBell({
            audioEnabled: active,
            bell: bellEnabled
        })
    }

    /** Play a single key click, if every gate allows it. */
    function keyClick(info) {
        if (!shouldClick(info) || !backend.item)
            return false
        backend.item.playClick()
        return true
    }

    /** Play the terminal bell, if every gate allows it. */
    function bell() {
        if (!shouldBell() || !backend.item)
            return false
        backend.item.playBell()
        return true
    }

    function stopAll() {
        if (backend.item)
            backend.item.stopAll()
    }
}
