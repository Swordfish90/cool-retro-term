import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Window{
    id: insertnamedialog
    width: 400
    height: 100
    modality: Qt.ApplicationModal
    title: qsTr("Save current profile")

    signal nameSelected(string name)

    ColumnLayout{
        anchors.margins: 10
        anchors.fill: parent
        RowLayout{
            Label{text: qsTr("Name")}
            TextField{
                id: namefield
                Layout.fillWidth: true
                Component.onCompleted: forceActiveFocus()
            }
        }
        RowLayout{
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            Button{
                text: qsTr("OK")
                onClicked: {
                    nameSelected(namefield.text);
                    close();
                }
            }
            Button{
                text: qsTr("Cancel")
                onClicked: close()
            }
        }
    }
}
