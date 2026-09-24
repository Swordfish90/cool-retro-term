/*******************************************************************************
* Qt Quick test: the on screen IBM PF / PA legend.
*
* Two contracts are asserted here:
*   1. it renders one cap per slot with the right identity and legend, and
*      hides itself when there is nothing to show;
*   2. it is reachable by eye only: no descendant can be clicked or hovered,
*      no descendant holds the keyboard, and clicking on it leaves focus
*      exactly where it was.
*******************************************************************************/
import QtQuick
import QtTest

import "../app/qml" as App
import "../app/qml/logic/pfkeys.js" as PfKeys
import "helpers.js" as Helpers

Rectangle {
    id: host
    width: 640
    height: 200
    color: "black"

    // Stand-in for the widget that owns the keyboard: the legend must never
    // take it away.
    TextInput {
        id: probe
        objectName: "focusProbe"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 30
        focus: true
        color: "white"
        font.family: "monospace"
    }

    App.PfKeyBar {
        id: bar
        objectName: "pfKeyBar"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        model: PfKeys.defaultAssignments()
    }

    TestCase {
        name: "PfKeyBarTests"
        when: windowShown

        function init() {
            bar.model = PfKeys.defaultAssignments()
            bar.showLegends = true
            probe.forceActiveFocus()
        }

        function test_rendersEverySlot() {
            compare(bar.count, 15)                       // 12 PF + 3 PA
            compare(bar.empty, false)
            verify(bar.visible)
            verify(bar.implicitHeight > 0)

            for (var i = 0; i < bar.count; i++) {
                var cap = findChild(bar, "pfCap_" + i)
                verify(cap !== null, "missing key cap " + i)
                var name = findChild(bar, "pfName_" + i)
                verify(name !== null, "missing key identity " + i)
                compare(name.text, PfKeys.defaultLabelFor(i))
            }
        }

        function test_capIdentitiesAreTheMainframeOnes() {
            compare(findChild(bar, "pfName_0").text, "PF1")
            compare(findChild(bar, "pfName_11").text, "PF12")
            compare(findChild(bar, "pfName_12").text, "PA1")
            compare(findChild(bar, "pfName_14").text, "PA3")
        }

        function test_legendShowsTheAssignedFunction() {
            // PA1 defaults to the 3270 Attention key.
            var attention = bar.model[12]
            compare(attention.action, "interrupt")
            compare(bar.legendFor(attention), PfKeys.legend(attention))
            compare(bar.legendFor(attention), "Attention")
            compare(findChild(bar, "pfLegend_12").text, "Attention")

            // A passed through PF key advertises no function at all: the
            // legend must not pretend the shell key has been claimed.
            compare(bar.legendFor(bar.model[0]), "")
            compare(findChild(bar, "pfLegend_0").text, "")
            compare(findChild(bar, "pfLegend_0").visible, false)
        }

        function test_legendCanBeTurnedOff() {
            bar.showLegends = false
            compare(bar.legendFor(bar.model[12]), "")
            compare(findChild(bar, "pfLegend_12").text, "")
            compare(findChild(bar, "pfLegend_12").visible, false)

            bar.showLegends = true
            compare(bar.legendFor(bar.model[12]), "Attention")
            compare(findChild(bar, "pfLegend_12").visible, true)
        }

        function test_emptyModelHidesTheBar() {
            bar.model = []
            compare(bar.count, 0)
            compare(bar.empty, true)
            compare(bar.visible, false)
            compare(bar.implicitHeight, 0)
            compare(Helpers.mouseTargets(bar), 0)
        }

        function test_isUnreachableByCursor() {
            compare(Helpers.mouseTargets(host), 0)
            compare(Helpers.mouseTargets(bar), 0)
            compare(bar.focus, false)
        }

        function test_clickingNeverTakesTheKeyboard() {
            var cap = findChild(bar, "pfCap_0")
            verify(cap !== null)
            verify(probe.focus, "the probe should own the keyboard")

            mouseClick(cap)

            compare(bar.focus, false)
            compare(Helpers.focusedItems(bar), 0)
            verify(probe.focus, "clicking the legend must not move focus")
        }
    }
}
