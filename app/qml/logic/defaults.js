/*******************************************************************************
* Defaults + tolerant merging for the settings introduced by the retro
* feature set.  Pure ECMAScript so the round trip can be tested directly.
*******************************************************************************/

function defaults() {
    return {
        // Zero chrome: no menu bar, no tab strip, no context menu, no overlay.
        nostalgicMode: true,
        // On-screen IBM PF/PA key legend.
        showPfKeys: false,
        pfKeys: "",                 // JSON produced by pfkeys.serialize()
        // Audible IBM key click + terminal bell.
        audioEnabled: false,
        keyClick: true,
        keyClickVolume: 0.5,
        bell: true,
        bellVolume: 0.5,
        // iTerm2 style highlight of the row the cursor sits on.
        highlightActiveLine: false,
        activeLineOpacity: 0.18,
        // Block / half block cursor, as on 3270 and PC BIOS screens.
        cursorStyle: "block"        // "block" | "half"
    }
}

/**
 * Merge a stored (possibly partial, possibly hostile) object onto the defaults.
 * Unknown keys are ignored, wrong types are repaired.
 */
function merge(stored) {
    var out = defaults()
    if (!stored || typeof stored !== "object")
        return out

    if (typeof stored.nostalgicMode === "boolean") out.nostalgicMode = stored.nostalgicMode
    if (typeof stored.showPfKeys === "boolean")    out.showPfKeys = stored.showPfKeys
    if (typeof stored.pfKeys === "string")         out.pfKeys = stored.pfKeys

    if (typeof stored.audioEnabled === "boolean")  out.audioEnabled = stored.audioEnabled
    if (typeof stored.keyClick === "boolean")      out.keyClick = stored.keyClick
    if (typeof stored.bell === "boolean")          out.bell = stored.bell
    if (typeof stored.highlightActiveLine === "boolean")
        out.highlightActiveLine = stored.highlightActiveLine

    out.keyClickVolume = clampNumber(stored.keyClickVolume, out.keyClickVolume, 0, 1)
    out.bellVolume     = clampNumber(stored.bellVolume, out.bellVolume, 0, 1)
    out.activeLineOpacity = clampNumber(stored.activeLineOpacity, out.activeLineOpacity, 0, 1)

    if (stored.cursorStyle === "block" || stored.cursorStyle === "half")
        out.cursorStyle = stored.cursorStyle

    return out
}

function clampNumber(value, fallback, min, max) {
    var v = Number(value)
    if (isNaN(v))
        return fallback
    return Math.max(min, Math.min(max, v))
}

/** The subset that is persisted, ready to be JSON encoded. */
function serialize(stored) {
    return JSON.stringify(merge(stored))
}

function parse(json) {
    if (json === undefined || json === null || json === "")
        return defaults()
    try {
        return merge(JSON.parse(json))
    } catch (err) {
        return defaults()
    }
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        defaults: defaults,
        merge: merge,
        clampNumber: clampNumber,
        serialize: serialize,
        parse: parse
    }
}
