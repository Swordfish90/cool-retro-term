/*******************************************************************************
* Audio backend.  This is the only file in the application that imports
* QtMultimedia, and it is only ever reached through SoundManager's Loader.
* If the module or an audio device is missing, the Loader simply stays empty
* and the whole feature degrades to silence instead of breaking the terminal.
*
* Bundled samples were synthesised by scripts/gen-sounds.py:
*   - keyclick.wav  a short, dry buckling-spring style tick
*   - bell.wav      the classic terminal attention beep
*******************************************************************************/
import QtQuick
import QtMultimedia

QtObject {
    id: backend

    property real clickVolume: 0.5
    property real bellVolume: 0.5

    function clamp(value) {
        var v = Number(value)
        if (isNaN(v))
            v = 0.5
        return Math.max(0, Math.min(1, v))
    }

    property SoundEffect click: SoundEffect {
        source: "qrc:/sounds/keyclick.wav"
        volume: backend.clamp(backend.clickVolume)
    }

    property SoundEffect bell: SoundEffect {
        source: "qrc:/sounds/bell.wav"
        volume: backend.clamp(backend.bellVolume)
    }

    function playClick() {
        if (click.status !== SoundEffect.Error)
            click.play()
    }

    function playBell() {
        if (bell.status !== SoundEffect.Error)
            bell.play()
    }

    function stopAll() {
        click.stop()
        bell.stop()
    }
}
