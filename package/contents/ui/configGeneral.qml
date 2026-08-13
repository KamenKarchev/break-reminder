import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_focusMinutes: focusMinutes.value
    property alias cfg_breakMinutes: breakMinutes.value
    property alias cfg_denyGraceSeconds: denyGraceSeconds.value
    property alias cfg_korganizerEnabled: korganizerEnabled.checked
    property alias cfg_korganizerHelperPath: korganizerHelperPath.text
    property alias cfg_korganizerPollMinutes: korganizerPollMinutes.value

    QQC2.SpinBox {
        id: focusMinutes
        Kirigami.FormData.label: "Focus:"

        from: 1
        to: 1440

        textFromValue: function(value) {
            return i18n("%1 min", value)
        }
        valueFromText: function(text) {
            return parseInt(text) || from
        }
    }

    QQC2.SpinBox {
        id: breakMinutes
        Kirigami.FormData.label: "Break:"

        from: 1
        to: 1440

        textFromValue: function(value) {
            return i18n("%1 min", value)
        }
        valueFromText: function(text) {
            return parseInt(text) || from
        }
    }

    QQC2.SpinBox {
        id: denyGraceSeconds
        Kirigami.FormData.label: "Deny mode grace period:"

        from: 1
        to: 60

        textFromValue: function(value) {
            return i18n("%1 sec", value)
        }
        valueFromText: function(text) {
            return parseInt(text) || from
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "KOrganizer integration"
    }

    QQC2.CheckBox {
        id: korganizerEnabled
        Kirigami.FormData.label: "Enabled:"
        text: "Map today's KOrganizer tasks to free/strict/blocked modes"
    }

    QQC2.TextField {
        id: korganizerHelperPath
        Kirigami.FormData.label: "Helper binary path:"
        Layout.fillWidth: true
        enabled: korganizerEnabled.checked
    }

    QQC2.SpinBox {
        id: korganizerPollMinutes
        Kirigami.FormData.label: "Poll interval:"
        enabled: korganizerEnabled.checked

        from: 1
        to: 60

        textFromValue: function(value) {
            return i18n("%1 min", value)
        }
        valueFromText: function(text) {
            return parseInt(text) || from
        }
    }
}
