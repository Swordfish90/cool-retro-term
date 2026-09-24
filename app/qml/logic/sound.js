/*******************************************************************************
* Audible feedback gating (IBM key click + attention bell).
*
* Pure decision logic so the "is this setting allowed to make a noise right
* now" rules can be tested without an audio backend.
*******************************************************************************/

/** Master gate: audible feedback must be explicitly enabled. */
function audible(settings) {
    var s = settings || {}
    return s.audioEnabled === true
}

/** Should a key click be played for this keystroke? */
function shouldClick(settings, keyInfo) {
    if (!audible(settings))
        return false
    if (settings.keyClick !== true)
        return false

    var info = keyInfo || {}
    // Key auto-repeat would machine-gun the click; one click per physical press.
    if (info.isAutoRepeat === true)
        return false

    // A paste floods the terminal with text in one shot.
    if (info.fromPaste === true)
        return false

    // Modifier-only presses are not keystrokes on a real keyboard.
    if (info.isModifierOnly === true)
        return false

    return true
}

/** Should the terminal bell be audible? */
function shouldBell(settings) {
    if (!audible(settings))
        return false
    return settings.bell === true
}

/** Clamp a volume to the [0, 1] range expected by the audio backend. */
function volume(value, fallback) {
    var d = (fallback === undefined) ? 0.5 : fallback
    // null/undefined/"" mean "unset"; Number(null) is 0, which is a valid
    // volume, so they have to be rejected before conversion.
    if (value === null || value === undefined || value === "")
        return d
    var v = Number(value)
    if (isNaN(v))
        return d
    return Math.max(0, Math.min(1, v))
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        audible: audible,
        shouldClick: shouldClick,
        shouldBell: shouldBell,
        volume: volume
    }
}
