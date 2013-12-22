import QtQuick 2.1
import QtQuick.Dialogs 1.1

Item {
    property color button_color;

    ColorDialog {
        id: colorDialog
        title: qsTr("Choose a color")
        modality: Qt.ApplicationModal
        visible: false

        //This is a workaround to a Qt 5.2 bug.
        onCurrentColorChanged: colorDialog.color = colorDialog.currentColor;
        onAccepted: button_color = color;
    }
    Rectangle{
        radius: 10
        anchors.fill: parent
        color: button_color

        Text{
            id: text_color
            anchors.centerIn: parent
            z: 1.1
            text: button_color
        }

        Rectangle{
            anchors.centerIn: parent
            width: text_color.width * 1.4
            height: text_color.height * 1.4
            radius: 10
            border.color: "black"
            border.width: 2
            color: "white"
        }
    }
    MouseArea{
        anchors.fill: parent
        onClicked: colorDialog.visible = true;
    }
}
