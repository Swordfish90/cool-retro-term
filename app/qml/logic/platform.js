/*******************************************************************************
* Platform-aware key sequence resolution.
*
* This file is loaded both by QML (import "logic/platform.js" as Platform) and
* by the Node test suite (require(...)).  It must therefore stay free of any
* Qt/QML specific construct: plain ECMAScript only, no ".pragma" directives.
*******************************************************************************/

/** Normalize the many spellings of an OS name onto three canonical buckets. */
function normalizeOs(os) {
    if (os === undefined || os === null)
        return "linux"

    var s = String(os).toLowerCase()
    if (s === "osx" || s === "macos" || s === "mac" || s === "darwin" || s === "ios")
        return "mac"
    if (s === "win32" || s === "windows" || s === "win" || s === "win64")
        return "windows"
    // "x11", "wayland", "linux", "freebsd", "unix", ...
    return "linux"
}

function isMac(os) { return normalizeOs(os) === "mac" }

/**
 * The application-wide key map.
 *
 * Every entry uses the sequence that is conventional on that platform, so the
 * same *function* always lives on the same *place* as it does natively:
 *
 *   mac     Cmd+N new window, Cmd+W close tab, Cmd+Shift+W close window,
 *           Cmd+` next window, Cmd+, settings, Cmd+Q quit.
 *   win     Ctrl+Shift+N new window, Ctrl+W close tab,
 *           Ctrl+Shift+W close window, Alt+` next window,
 *           Ctrl+, settings, Ctrl+Shift+Q quit.
 *   linux   Identical to Windows; Alt+` is also the GNOME/KDE
 *           "switch windows of this application" binding.
 *
 * @param {string} os  Qt.platform.os value ("osx", "win32", "x11", ...).
 * @return {Object<string,string>}
 */
function sequences(os) {
    var mac = isMac(os)

    return {
        newWindow:    mac ? "Meta+N"        : "Ctrl+Shift+N",
        closeWindow:  mac ? "Meta+Shift+W"  : "Ctrl+Shift+W",
        newTab:       mac ? "Meta+T"        : "Ctrl+Shift+T",
        closeTab:     mac ? "Meta+W"        : "Ctrl+W",
        // Cmd+` / Alt+` is the native "next window of this application"
        // binding on macOS and on GNOME/KDE respectively.
        nextWindow:   mac ? "Meta+`"        : "Alt+`",
        prevWindow:   mac ? "Meta+Shift+`"  : "Alt+Shift+`",
        fullscreen:   "StandardKey.FullScreen",
        settings:     mac ? "Meta+,"        : "Ctrl+,",
        quit:         mac ? "StandardKey.Quit" : "Ctrl+Shift+Q",
        copy:         mac ? "StandardKey.Copy" : "Ctrl+Shift+C",
        paste:        mac ? "StandardKey.Paste": "Ctrl+Shift+V",
        zoomIn:       "StandardKey.ZoomIn",
        zoomOut:      "StandardKey.ZoomOut"
    }
}

/** Resolve one sequence, falling back to a sensible default if unknown. */
function sequence(os, name) {
    var map = sequences(os)
    if (map[name] === undefined)
        return ""
    return map[name]
}

/**
 * Sequences we claim must never be swallowed by the OS in a way that makes the
 * app unusable.  Returns the subset of `names` that Qt can register at all
 * (non-empty, well formed).
 */
function usableSequences(os, names) {
    var out = {}
    for (var i = 0; i < names.length; i++) {
        var s = sequence(os, names[i])
        if (s && s.length > 0)
            out[names[i]] = s
    }
    return out
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        normalizeOs: normalizeOs,
        isMac: isMac,
        sequences: sequences,
        sequence: sequence,
        usableSequences: usableSequences
    }
}
