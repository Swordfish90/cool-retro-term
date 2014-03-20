import QtQuick 2.0

import org.kde.konsole 0.1

KTerminal {
    font.pointSize: shadersettings.fontSize
    font.family: shadersettings.font.name

    colorScheme: "WhiteOnBlack"

    session: KSession {
        id: ksession
        kbScheme: "linux"

        onFinished: {
            Qt.quit()
        }
    }

    Component.onCompleted: {
        font.pointSize = shadersettings.fontSize;
        font.family = shadersettings.font.name;
        console.log(shadersettings.font.name);
    }

    Component.onDestruction: console.log("Destroy")
}
