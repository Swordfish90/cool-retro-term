import QtQuick

DropArea {
    property var targetTerminal

    onEntered: function(drag) {
        drag.accepted = drag.hasUrls
    }
    onDropped: function(drop) {
        if (!drop.hasUrls) {
            drop.accepted = false
            return
        }
        targetTerminal.insertDroppedUrls(drop.urls)
        drop.acceptProposedAction()
    }
}
