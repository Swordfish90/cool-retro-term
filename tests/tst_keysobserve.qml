/*******************************************************************************
* Qt Quick test: observing keystrokes without swallowing them.
*
* PreprocessedTerminal installs a Keys handler at BeforeItem priority in front
* of the terminal widget so the optional IBM key click can sound.  The event
* must reach the widget exactly as it would have without the observer, and
* whatever the widget does not take must keep climbing the parent chain, which
* is how the window level PF / PA shortcuts stay reachable.
*
* A plain TextInput stands in for QMLTermWidget: it takes focus, handles keys
* itself, and is enough to prove the ordering of the observer.
*******************************************************************************/
import QtQuick
import QtTest

import "../app/qml/logic/sound.js" as Sound

Rectangle {
    id: host
    width: 640
    height: 240
    color: "black"

    /** Every keystroke the observer in front of the widget saw. */
    property var observed: []
    /** Keys the widget did not take, as seen by an ancestor. */
    property var propagated: []

    TextInput {
        id: editor
        objectName: "editor"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40
        focus: true
        color: "white"
        font.family: "monospace"

        // The pattern PreprocessedTerminal installs on the terminal widget.
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            host.observed.push({ key: event.key, autoRepeat: event.isAutoRepeat })
            // The contract: observe, never consume.
            event.accepted = false
        }
    }

    // Ancestors keep seeing whatever the widget did not take, exactly like
    // the window level shortcuts do in the application.
    Keys.onPressed: function(event) {
        host.propagated.push(event.key)
        event.accepted = false
    }

    TestCase {
        name: "KeyObserverTests"
        when: windowShown

        function init() {
            host.observed = []
            host.propagated = []
            editor.text = ""
            editor.forceActiveFocus()
        }

        function test_observesWithoutConsuming() {
            keyClick("a")

            compare(host.observed.length, 1)
            compare(host.observed[0].key, Qt.Key_A)
            compare(host.observed[0].autoRepeat, false)

            // The widget still received the keystroke: nothing was swallowed.
            compare(editor.text, "a")
        }

        function test_repeatedPressesAreObservedOneByOne() {
            keyClick("a")
            keyClick("b")
            keyClick("c")

            compare(host.observed.length, 3)
            compare(host.observed[1].key, Qt.Key_B)
            compare(editor.text, "abc")
        }

        function test_modifierPressesAreObservedButTypedNowhere() {
            keyClick(Qt.Key_Shift)

            compare(host.observed.length, 1)
            compare(host.observed[0].key, Qt.Key_Shift)
            compare(editor.text, "")        // a modifier types nothing
        }

        function test_onlyRealKeystrokesWouldClick() {
            keyClick("a")
            keyClick(Qt.Key_Shift)
            compare(host.observed.length, 2)

            var on = { audioEnabled: true, keyClick: true }

            // A plain character press clicks...
            compare(Sound.shouldClick(on, {
                                          isAutoRepeat: host.observed[0].autoRepeat,
                                          isModifierOnly: false
                                      }), true)
            // ...a bare modifier (what the observer saw second) never does,
            // ...and neither does a key held down.
            compare(Sound.shouldClick(on, {
                                          isAutoRepeat: false,
                                          isModifierOnly: true
                                      }), false)
            compare(Sound.shouldClick(on, {
                                          isAutoRepeat: true,
                                          isModifierOnly: false
                                      }), false)
            // Nothing clicks while the audio is switched off.
            compare(Sound.shouldClick({ audioEnabled: false, keyClick: true },
                                      { isAutoRepeat: false }), false)
            compare(Sound.shouldClick({ audioEnabled: true, keyClick: false },
                                      { isAutoRepeat: false }), false)
        }

        function test_unhandledKeysStillReachTheWindow() {
            keyClick(Qt.Key_F1)

            compare(host.observed.length, 1)
            compare(host.observed[0].key, Qt.Key_F1)

            // The widget has no use for F1, so the event keeps climbing: that
            // is precisely how the window level PF shortcuts stay reachable.
            compare(host.propagated.indexOf(Qt.Key_F1) !== -1, true)
        }

        function test_keysHandledByTheWidgetDoNotLeakOut() {
            keyClick("a")
            // The widget took it, so ancestors must not see it a second time.
            compare(host.propagated.indexOf(Qt.Key_A), -1)
        }
    }
}
