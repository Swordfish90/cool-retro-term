import QtQuick 2.1
import QtQuick.Dialogs 1.1

ColorDialog {
    id: colorDialog
    title: qsTr("Choose a color")
    modality: Qt.ApplicationModal

    property string color_to_change

    color: "green"

    //This is a workaround to a Qt 5.2 bug.
    onCurrentColorChanged: colorDialog.color = colorDialog.currentColor;

    onAccepted: {
        console.log("[MyColorDialog.qml] Color chosen: " + colorDialog.color);
        shadersettings[color_to_change] = colorDialog.color;
    }
    onRejected: {
        console.log("[MyColorDialog.qml] No color selected")
    }

    Component.onCompleted: visible = true
}
