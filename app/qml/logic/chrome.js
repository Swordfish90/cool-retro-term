/*******************************************************************************
* Visibility rules for every piece of on-screen chrome.
*
* The nostalgic mode contract: when it is on, nothing on screen may hint that
* there is a graphical interface behind the terminal.  Everything is reachable
* from the keyboard only.
*
* Pure function so the contract can be asserted directly by the test suite.
*******************************************************************************/

/**
 * @param {Object} s settings snapshot
 *   nostalgicMode  hide all chrome (default)
 *   showMenubar     legacy "show menu bar" switch, honoured only when the
 *                   nostalgic mode is off
 *   showTerminalSize  legacy size overlay switch
 *   tabCount        how many tabs the window currently has
 *   isMacOS         platform flag
 * @return {Object} boolean flags for each chrome element
 */
function visibility(s) {
    var cfg = s || {}
    var nostalgic = cfg.nostalgicMode !== false   // default ON
    var tabCount = Number(cfg.tabCount)
    if (isNaN(tabCount) || tabCount < 0)
        tabCount = 0

    if (nostalgic) {
        return {
            menubar: false,
            tabBar: false,
            contextMenu: false,
            sizeOverlay: false,
            settingsWindow: true,   // reachable, just never advertised
            anythingVisible: false
        }
    }

    // Without nostalgic mode the historical behaviour is preserved: on macOS
    // the menu bar is always there, elsewhere it is opt-in.
    var menubar = cfg.isMacOS === true || cfg.showMenubar === true
    var sizeOverlay = cfg.showTerminalSize !== false

    return {
        menubar: menubar,
        tabBar: tabCount > 1,
        contextMenu: true,
        sizeOverlay: sizeOverlay,
        settingsWindow: true,
        anythingVisible: menubar || tabCount > 1 || sizeOverlay
    }
}

/** Is there any chrome at all? Used by tests and by the settings tooltip. */
function hasChrome(s) {
    var v = visibility(s)
    return v.menubar || v.tabBar || v.contextMenu || v.sizeOverlay
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        visibility: visibility,
        hasChrome: hasChrome
    }
}
