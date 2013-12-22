import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

RowLayout {
    property string name
    property double value
    property double prev_value: 0.0
    property double min_value: 0.0
    property double max_value: 1.0

    id: setting_component
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 10

    CheckBox{
        id: check
        implicitWidth: 150

        text: name
        onCheckedChanged:{
            if(checked) value = prev_value;
            else {
                prev_value = value;
                value = 0;
            }
        }
        Component.onCompleted: checked = (value !== 0);
    }
    Slider{
        id: slider
        stepSize: 0.01
        minimumValue: min_value
        maximumValue: max_value
        onValueChanged: setting_component.value = value;
        Layout.fillWidth: true

        Component.onCompleted: slider.value = setting_component.value
    }
    TextField{
        id: textfield

        text: value.toFixed(2)
        implicitWidth: 50
        enabled: false

        Component.onCompleted: text = value.toFixed(2)
    }
}
