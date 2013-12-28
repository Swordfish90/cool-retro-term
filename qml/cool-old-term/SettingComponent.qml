import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

RowLayout {
    property string name
    property double value: (check.checked) ? _value : 0.0
    property double _value: 0.0
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
        Component.onCompleted: checked = (_value !== 0);
    }
    Slider{
        id: slider
        stepSize: 0.01
        minimumValue: min_value
        maximumValue: max_value
        onValueChanged: setting_component._value = slider.value;
        Layout.fillWidth: true
        enabled: check.checked
        value: setting_component._value

        Component.onCompleted: slider.value = setting_component._value
    }
    Text{
        id: textfield
        text: Math.round(((_value - min_value) / (max_value - min_value)) * 100) + "%"
    }
}
