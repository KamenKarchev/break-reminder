import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: fullRepresentation
    property PlasmoidItem plasmoidItem

    readonly property bool locked: plasmoidItem ? plasmoidItem.locked : true
    readonly property bool focusing: plasmoidItem ? plasmoidItem.focusing : false
    readonly property var schedule: plasmoidItem ? plasmoidItem.korganizerScheduleRef : null
    readonly property var currentEvent: fullRepresentation.schedule ? fullRepresentation.schedule.currentInterval : null
    readonly property string statusText: plasmoidItem ? plasmoidItem.statusText : "…"
    readonly property string statusDetail: plasmoidItem ? plasmoidItem.statusDetail : ""

    readonly property var modeNames: ({"f": "free", "s": "strict", "b": "blocked"})

    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: implicitHeight

    implicitHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0

        Kirigami.Heading {
            level: 3
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            text: {
                if (!fullRepresentation.currentEvent) {
                    return "Event: none scheduled"
                }
                var modeCode = fullRepresentation.currentEvent.mode
                var modeName = fullRepresentation.modeNames[modeCode] ? fullRepresentation.modeNames[modeCode] : modeCode
                return "Event: " + fullRepresentation.currentEvent.summary + "  (" + modeName + ")"
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Kirigami.Heading {
            level: 3
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            text: "You are " + fullRepresentation.statusText + (fullRepresentation.statusDetail ? (" (" + fullRepresentation.statusDetail + ")") : "")
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 0
            columnSpacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: "Focus"
            }

            QQC2.SpinBox {
                id: focusMinutes
                Layout.fillWidth: true
                from: 5
                to: 1440
                textFromValue: function(value) {
                    return i18n("%1 min", value)
                }
                valueFromText: function(text) {
                    return Math.max(from, parseInt(text) || from)
                }
                onValueModified: {
                    if (fullRepresentation.plasmoidItem) {
                        fullRepresentation.plasmoidItem.sessionFocusSeconds = value * 60
                    }
                }
                Component.onCompleted: {
                    var seconds = fullRepresentation.plasmoidItem ? fullRepresentation.plasmoidItem.sessionFocusSeconds : 1500
                    value = Math.max(from, Math.round(seconds / 60))
                }
            }

            QQC2.Button {
                text: "Start"
                enabled: !fullRepresentation.locked || fullRepresentation.focusing
                onClicked: {
                    if (fullRepresentation.plasmoidItem) {
                        fullRepresentation.plasmoidItem.startFocus(focusMinutes.value * 60)
                    }
                }
            }

            QQC2.Label {
                id: mandatoryLabel
                text: "Mandatory"
                font.strikeout: breakMinutes.value === 0
                MouseArea {
                    anchors.fill: parent
                    onClicked: breakMinutes.value = 0
                }
            }

            QQC2.SpinBox {
                id: breakMinutes
                Layout.fillWidth: true
                from: 0
                to: 1440
                textFromValue: function(value) {
                    return i18n("%1 min", value)
                }
                valueFromText: function(text) {
                    return Math.max(from, parseInt(text) || from)
                }
                onValueModified: {
                    if (fullRepresentation.plasmoidItem) {
                        fullRepresentation.plasmoidItem.sessionBreakSeconds = value * 60
                    }
                }
                Component.onCompleted: {
                    var seconds = fullRepresentation.plasmoidItem ? fullRepresentation.plasmoidItem.sessionBreakSeconds : 300
                    value = Math.round(seconds / 60)
                }
            }

            QQC2.Button {
                text: "Start"
                enabled: !fullRepresentation.locked
                onClicked: {
                    if (fullRepresentation.plasmoidItem) {
                        fullRepresentation.plasmoidItem.startBreakNow(breakMinutes.value * 60)
                    }
                }
            }
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: "Restart"
            enabled: !fullRepresentation.locked
            onClicked: {
                if (!fullRepresentation.plasmoidItem) {
                    return
                }
                fullRepresentation.plasmoidItem.reset()
                focusMinutes.value = Math.max(focusMinutes.from, Math.round(fullRepresentation.plasmoidItem.sessionFocusSeconds / 60))
                breakMinutes.value = Math.round(fullRepresentation.plasmoidItem.sessionBreakSeconds / 60)
            }
        }
    }
}
