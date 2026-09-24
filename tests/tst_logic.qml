/*******************************************************************************
* Qt Quick test: the shared logic modules as the QML engine sees them.
*
* Every module under app/qml/logic is loaded both by QML and by the Node suite
* (tests/logic).  Node can only prove the ECMAScript half of that promise;
* these tests import the very same files through the QML engine, so a Qt only
* construct (or a `module.exports` guard gone wrong) cannot slip through.
*******************************************************************************/
import QtTest

import "../app/qml/logic/chrome.js" as Chrome
import "../app/qml/logic/defaults.js" as Defaults
import "../app/qml/logic/linehighlight.js" as LineLogic
import "../app/qml/logic/pfkeys.js" as PfKeys
import "../app/qml/logic/platform.js" as Platform
import "../app/qml/logic/sound.js" as Sound
import "../app/qml/logic/windows.js" as Windows

TestCase {
    name: "LogicModulesTests"

    /***************************************************************************
    * Chrome: nostalgic mode hides every trace of a graphical interface.
    ***************************************************************************/
    function test_nostalgicModeIsTheDefault() {
        var v = Chrome.visibility({})
        compare(v.menubar, false)
        compare(v.tabBar, false)
        compare(v.contextMenu, false)
        compare(v.sizeOverlay, false)
        compare(v.anythingVisible, false)
        compare(v.settingsWindow, true)     // reachable, never advertised
        compare(Chrome.hasChrome({}), false)
    }

    function test_nostalgicModeWinsOverEveryLegacySwitch() {
        var v = Chrome.visibility({
            nostalgicMode: true,
            showMenubar: true,
            showTerminalSize: true,
            tabCount: 4,
            isMacOS: true
        })
        compare(v.menubar, false)
        compare(v.tabBar, false)
        compare(v.contextMenu, false)
        compare(v.sizeOverlay, false)
        compare(v.anythingVisible, false)
        compare(Chrome.hasChrome(v), false)
    }

    function test_legacyBehaviourIsPreservedWhenNostalgicModeIsOff() {
        var mac = Chrome.visibility({
            nostalgicMode: false, isMacOS: true, tabCount: 2, showTerminalSize: true
        })
        compare(mac.menubar, true)          // macOS always owns a menu bar
        compare(mac.tabBar, true)
        compare(mac.contextMenu, true)
        compare(mac.sizeOverlay, true)
        compare(mac.anythingVisible, true)

        var linux = Chrome.visibility({
            nostalgicMode: false, isMacOS: false, showMenubar: false,
            tabCount: 1, showTerminalSize: false
        })
        compare(linux.menubar, false)
        compare(linux.tabBar, false)
        compare(linux.contextMenu, true)    // still a real terminal context menu
        compare(linux.sizeOverlay, false)
        compare(linux.anythingVisible, false)
    }

    /***************************************************************************
    * Shortcuts: the same function always lives in the same place as natively.
    ***************************************************************************/
    function test_shortcutsFollowThePlatformConvention() {
        // macOS
        compare(Platform.sequence("mac", "newWindow"), "Meta+N")
        compare(Platform.sequence("osx", "newTab"), "Meta+T")
        compare(Platform.sequence("macos", "closeTab"), "Meta+W")
        compare(Platform.sequence("darwin", "closeWindow"), "Meta+Shift+W")
        compare(Platform.sequence("mac", "nextWindow"), "Meta+`")
        compare(Platform.sequence("mac", "prevWindow"), "Meta+Shift+`")
        compare(Platform.sequence("mac", "settings"), "Meta+,")
        compare(Platform.sequence("mac", "quit"), "StandardKey.Quit")

        // Windows
        compare(Platform.sequence("win32", "newWindow"), "Ctrl+Shift+N")
        compare(Platform.sequence("windows", "closeWindow"), "Ctrl+Shift+W")
        compare(Platform.sequence("win", "closeTab"), "Ctrl+W")
        compare(Platform.sequence("win32", "nextWindow"), "Alt+`")
        compare(Platform.sequence("win32", "quit"), "Ctrl+Shift+Q")

        // Linux: identical to Windows, Alt+` is GNOME/KDE "switch windows".
        compare(Platform.sequence("x11", "newWindow"), "Ctrl+Shift+N")
        compare(Platform.sequence("wayland", "newTab"), "Ctrl+Shift+T")
        compare(Platform.sequence("linux", "nextWindow"), "Alt+`")
        compare(Platform.sequence("linux", "prevWindow"), "Alt+Shift+`")
        compare(Platform.sequence("linux", "settings"), "Ctrl+,")
        compare(Platform.sequence("freebsd", "copy"), "Ctrl+Shift+C")
        compare(Platform.sequence("x11", "paste"), "Ctrl+Shift+V")

        // Platform agnostic functions stay on Qt's own standard keys.
        compare(Platform.sequence("linux", "fullscreen"), "StandardKey.FullScreen")
        compare(Platform.sequence("mac", "fullscreen"), "StandardKey.FullScreen")
        compare(Platform.sequence("mac", "zoomIn"), "StandardKey.ZoomIn")
        compare(Platform.sequence("win32", "zoomOut"), "StandardKey.ZoomOut")
        compare(Platform.sequence("mac", "copy"), "StandardKey.Copy")
        compare(Platform.sequence("mac", "paste"), "StandardKey.Paste")
        compare(Platform.sequence("win32", "paste"), "Ctrl+Shift+V")

        // Unknown functions resolve to nothing rather than to garbage.
        compare(Platform.sequence("linux", "teleport"), "")
        compare(Platform.isMac("osx"), true)
        compare(Platform.isMac("x11"), false)
    }

    /***************************************************************************
    * Multi window arithmetic.
    ***************************************************************************/
    function test_windowsCycleAndWrap() {
        compare(Windows.cycleIndex(0, 3, 1), 1)
        compare(Windows.cycleIndex(2, 3, 1), 0)      // wraps forward
        compare(Windows.cycleIndex(0, 3, -1), 2)     // wraps backward
        compare(Windows.cycleIndex(-1, 3, 1), 1)     // unknown active -> first
        compare(Windows.shouldCycle(0, 3), true)
        compare(Windows.shouldCycle(0, 1), false)    // one window: stay quiet
        compare(Windows.shouldCycle(0, 0), false)
        compare(Windows.wrap(5, 3), 2)
        compare(Windows.wrap(-1, 3), 2)
        compare(Windows.wrap(2, 0), -1)
    }

    function test_closingAWindowPicksTheRightSuccessor() {
        compare(Windows.indexAfterRemoval(1, 1, 3), 1)   // active closed
        compare(Windows.indexAfterRemoval(2, 2, 3), 1)   // last one closed
        compare(Windows.indexAfterRemoval(0, 2, 3), 0)   // an earlier one
        compare(Windows.indexAfterRemoval(1, 2, 3), 1)   // a later one
        compare(Windows.indexAfterRemoval(0, 0, 1), -1)  // nothing left
    }

    /***************************************************************************
    * IBM PF / PA keys.
    ***************************************************************************/
    function test_pfDefaultsMatchTheMainframe() {
        var defs = PfKeys.defaultAssignments()
        compare(defs.length, PfKeys.KEY_COUNT)       // 12 PF + 3 PA
        compare(PfKeys.PF_COUNT, 12)
        compare(PfKeys.PA_COUNT, 3)

        compare(defs[0].key, "F1")
        compare(defs[11].key, "F12")
        compare(defs[11].label, "PF12")

        // IBM PC / 3270 default bindings for the program attention keys.
        compare(defs[12].key, "Ctrl+F1")
        compare(defs[13].key, "Ctrl+F2")
        compare(defs[14].key, "Ctrl+F3")
        compare(defs[12].label, "PA1")

        // PA1 is the classic TSO Attention (break) key, wired to SIGINT.
        compare(defs[12].action, "interrupt")
        compare(PfKeys.actionById("interrupt").payload, "\u0003")
        // ERASE INPUT is Ctrl+U on POSIX.
        compare(PfKeys.actionById("eraseInput").payload, "\u0015")
    }

    function test_onlyAssignedKeysAreIntercepted() {
        var defs = PfKeys.defaultAssignments()

        // Every PF key starts as "Off": the shell keeps receiving F1..F12.
        for (var i = 0; i < PfKeys.PF_COUNT; i++) {
            compare(defs[i].action, "pass")
            compare(PfKeys.intercepts(defs[i]), false)
            compare(PfKeys.legend(defs[i]), "")
        }

        compare(PfKeys.intercepts(defs[12]), true)   // PA1 Attention
        compare(PfKeys.intercepts(defs[13]), false)  // PA2 unassigned
        compare(PfKeys.legend(defs[12]), "Attention")
        compare(PfKeys.anyIntercepting(defs), true)

        // Out of the box exactly one slot claims a keystroke: PA1.  Every
        // other key keeps going to the shell untouched.
        var claimed = []
        var normalized = PfKeys.normalize([])
        for (var j = 0; j < normalized.length; j++) {
            if (PfKeys.intercepts(normalized[j]))
                claimed.push(j)
        }
        compare(claimed.join(","), "12")
        compare(PfKeys.collisions(normalized).length, 0)
    }

    function test_normalizeRepairsHostileInput() {
        var out = PfKeys.normalize([
            { action: "nonsense", key: "", label: "" },
            "not an object"
        ])
        compare(out.length, PfKeys.KEY_COUNT)
        compare(out[0].action, "pass")           // unknown action -> default
        compare(out[0].key, "F1")                // empty key -> default
        compare(out[0].label, "PF1")             // empty label -> default
        compare(out[1].key, "F2")                // non object -> all defaults
        compare(out[12].action, "interrupt")     // untouched default survives
    }

    function test_macroTextBehavesLikeTheEnterKey() {
        // \n in a macro has to reach the shell as a carriage return.
        compare(PfKeys.macroText("ls \\n"), "ls \r")
        compare(PfKeys.macroText("\\r"), "\r")
        compare(PfKeys.macroText("\\t"), "\t")
        compare(PfKeys.macroText("\\e"), "\u001b")
        compare(PfKeys.macroText("\\\\"), "\\")
        compare(PfKeys.macroText("plain"), "plain")
        compare(PfKeys.macroText(undefined), "")
    }

    function test_serializeRoundTrips() {
        var defs = PfKeys.defaultAssignments()
        defs[0].action = "newWindow"
        defs[0].payload = ""

        var restored = PfKeys.parse(PfKeys.serialize(defs))
        compare(restored.length, defs.length)
        compare(restored[0].action, "newWindow")
        compare(restored[12].action, "interrupt")

        compare(PfKeys.parse("{ not json").length, PfKeys.KEY_COUNT)
        compare(PfKeys.parse(undefined).length, PfKeys.KEY_COUNT)
    }

    /***************************************************************************
    * Sound gating.
    ***************************************************************************/
    function test_soundGates() {
        var on = { audioEnabled: true, keyClick: true, bell: true }
        compare(Sound.shouldClick(on, {}), true)
        compare(Sound.shouldBell(on), true)

        compare(Sound.shouldClick({ audioEnabled: false, keyClick: true }, {}), false)
        compare(Sound.shouldBell({ audioEnabled: false, bell: true }), false)
        compare(Sound.shouldClick({ audioEnabled: true, keyClick: false }, {}), false)
        compare(Sound.shouldBell({ audioEnabled: true, bell: false }), false)

        compare(Sound.shouldClick(on, { isAutoRepeat: true }), false)
        compare(Sound.shouldClick(on, { isModifierOnly: true }), false)
        compare(Sound.shouldClick(on, { fromPaste: true }), false)
    }

    function test_volumesAreClamped() {
        compare(Sound.volume(0.5), 0.5)
        compare(Sound.volume(2, 0.5), 1)
        compare(Sound.volume(-1, 0.5), 0)
        compare(Sound.volume(undefined, 0.25), 0.25)
        compare(Sound.volume(null, 0.75), 0.75)
        compare(Sound.volume("nope", 0.5), 0.5)
    }

    /***************************************************************************
    * Retro settings: defaults, tolerant merge, hostile JSON.
    ***************************************************************************/
    function test_retroDefaults() {
        var d = Defaults.defaults()
        compare(d.nostalgicMode, true)      // no chrome out of the box
        compare(d.showPfKeys, false)        // legend opt-in
        compare(d.audioEnabled, false)      // click opt-in
        compare(d.highlightActiveLine, false)
        compare(d.cursorStyle, "block")
        compare(d.activeLineOpacity, 0.18)
        compare(d.keyClickVolume, 0.5)
    }

    function test_storedSettingsAreRepaired() {
        var m = Defaults.merge({
            audioEnabled: "yes",            // wrong type -> default
            keyClickVolume: 9,              // out of range -> clamped
            bellVolume: -4,                 // out of range -> clamped
            activeLineOpacity: "0.5",       // numeric string -> accepted
            cursorStyle: "weird",           // unknown value -> default
            highlightActiveLine: true,
            unknownKey: "ignored"
        })
        compare(m.audioEnabled, false)
        compare(m.keyClickVolume, 1)
        compare(m.bellVolume, 0)
        compare(m.activeLineOpacity, 0.5)
        compare(m.cursorStyle, "block")
        compare(m.highlightActiveLine, true)
        compare(m.nostalgicMode, true)
        compare("unknownKey" in m, false)
    }

    function test_hostileJsonFallsBackToDefaults() {
        var d = Defaults.parse("{ not json")
        compare(d.nostalgicMode, true)
        compare(d.cursorStyle, "block")
        compare(Defaults.parse(undefined).audioEnabled, false)
        compare(Defaults.parse("").showPfKeys, false)

        var round = Defaults.parse(Defaults.serialize({ showPfKeys: true }))
        compare(round.showPfKeys, true)
        compare(round.nostalgicMode, true)
    }

    /***************************************************************************
    * Active line geometry.
    ***************************************************************************/
    function test_bandGeometry() {
        var r = LineLogic.bandRect(
                    { x: 40, y: 180, width: 10, height: 18 },
                    { screenX: 8, screenWidth: 624, terminalY: 4 })
        verify(r !== null)
        compare(r.x, 8)
        compare(r.y, 184)
        compare(r.width, 624)
        compare(r.height, 18)

        compare(LineLogic.bandRect(null, {}), null)
        compare(LineLogic.bandRect({ x: 0, y: 0, width: 0, height: 18 }, {}), null)
        compare(LineLogic.bandRect({ x: 0, y: 0, width: 10, height: 0 }, {}), null)

        compare(LineLogic.cursorRow({ x: 40, y: 180, width: 10, height: 18 }), 10)
        compare(LineLogic.cursorColumn({ x: 40, y: 180, width: 10, height: 18 }), 4)
        compare(LineLogic.cursorRow(null), -1)
        compare(LineLogic.bandOpacity(9), 1)
        compare(LineLogic.bandOpacity(-9), 0)
        compare(LineLogic.bandOpacity(undefined), 0)
    }
}
