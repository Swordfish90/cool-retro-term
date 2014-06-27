import QtQuick 2.2

Rectangle {
    anchors.centerIn: parent
    width: parent.width - parent.border.width
    height: parent.height - parent.border.width
    radius:parent.radius - parent.border.width/2
    smooth: true

    border.width: parent.border.width/2
    border.color: "#22FFFFFF"

    gradient: Gradient {
        GradientStop { position: 0;    color: "#88FFFFFF" }
        GradientStop { position: .1;   color: "#55FFFFFF" }
        GradientStop { position: .5;   color: "#33FFFFFF" }
        GradientStop { position: .501; color: "#11000000" }
        GradientStop { position: .8;   color: "#11FFFFFF" }
        GradientStop { position: 1;    color: "#55FFFFFF" }
    }
}
