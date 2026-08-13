import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSVG
import org.kde.kirigami as Kirigami
import org.kde.notification

PlasmoidItem {
    id: root

    property bool isOnBreak: true
    property int focusSeconds: plasmoid.configuration.focusMinutes * 60
    property int breakSeconds: plasmoid.configuration.breakMinutes * 60
    property int remainingSeconds: focusSeconds
    property alias denyControllerRef: denyController
    property alias korganizerScheduleRef: schedule

    // Per-session overrides of the config defaults, editable from the popup.
    // Plain (non-declarative) values so they survive independently of config changes;
    // reset() snaps them back to the config defaults.
    property int sessionFocusSeconds: focusSeconds
    property int sessionBreakSeconds: breakSeconds

    property bool korganizerEnabled: plasmoid.configuration.korganizerEnabled
    property bool warned15: false
    property bool warned5: false

    // True only while a focus session is actively counting down.
    readonly property bool focusing: !isOnBreak
    // True whenever the UI should be locked down (deny mode, or an active focus session).
    readonly property bool locked: denyController.active || focusing


    property string formattedRemainingSeconds: {
        var minutes = Math.floor(remainingSeconds / 60);
        var seconds = remainingSeconds % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    property string formattedDenySeconds: {
        var minutes = Math.floor(denyController.remaining / 60);
        var seconds = denyController.remaining % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    property string statusText: denyController.active ? "Not supposed to be here" : (focusing ? "Focusing" : "Chilling")
    property string statusDetail: denyController.active ? formattedDenySeconds : (focusing ? formattedRemainingSeconds : "")

    preferredRepresentation: root.compactRepresentation
    activationTogglesExpanded: true

    toolTipMainText: statusText
    toolTipSubText: denyController.active ? ("Locked for " + statusDetail) : (focusing ? ("Time left: " + statusDetail) : "Click to start a focus session")
    Plasmoid.icon: isOnBreak ? Qt.resolvedUrl("../icons/break.svg") : Qt.resolvedUrl("../icons/in-focus.svg")

    Timer {
        id: timer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds -= 1
                if (sessionBreakSeconds > 0 && !(korganizerEnabled && schedule.currentMode === "f")) {
                    if (remainingSeconds === 900) {
                        notificationManager.sendDenyWarning(15)
                    } else if (remainingSeconds === 300) {
                        notificationManager.sendDenyWarning(5)
                    }
                }
                return
            }

            timer.stop()
            if (!isOnBreak) {
                startBreak()
            }
        }
    }

    Notifications {
        id: notificationManager
    }

    DenyMode {
        id: denyController
        graceSeconds: plasmoid.configuration.denyGraceSeconds
    }

    KorganizerSchedule {
        id: schedule
        enabled: root.korganizerEnabled
        helperPath: plasmoid.configuration.korganizerHelperPath
        pollMinutes: plasmoid.configuration.korganizerPollMinutes

        onCurrentModeChanged: {
            if (currentMode === "b" && currentInterval !== null) {
                var endMs = Date.parse(currentInterval.end)
                var secondsRemaining = Math.ceil((endMs - Date.now()) / 1000)
                if (secondsRemaining > 0 && (!denyController.active || endMs > denyController.endTime)) {
                    isOnBreak = true
                    denyController.start(secondsRemaining)
                }
            }
        }

        onNextBlockedIntervalChanged: {
            warned15 = false
            warned5 = false
        }

        onUpcomingBlockedIn: (secondsUntilStart, interval) => {
            if (!warned15 && secondsUntilStart <= 900) {
                notificationManager.sendDenyWarning(15)
                warned15 = true
            }
            if (!warned5 && secondsUntilStart <= 300) {
                notificationManager.sendDenyWarning(5)
                warned5 = true
            }
        }
    }

    function startFocus(durationSeconds) {
        if (denyController.active) {
            return
        }
        sessionFocusSeconds = durationSeconds > 0 ? durationSeconds : sessionFocusSeconds
        isOnBreak = false
        remainingSeconds = sessionFocusSeconds
        timer.start()
    }

    function startBreak() {
        isOnBreak = true
        notificationManager.sendBreakNotification()
        if (sessionBreakSeconds <= 0 || (korganizerEnabled && schedule.currentMode === "f")) {
            return
        }
        var newEnd = Date.now() + sessionBreakSeconds * 1000
        if (!denyController.active || newEnd > denyController.endTime) {
            denyController.start(sessionBreakSeconds)
        }
    }

    function startBreakNow(durationSeconds) {
        if (locked) {
            return
        }
        sessionBreakSeconds = durationSeconds
        timer.stop()
        isOnBreak = true
        if (durationSeconds > 0) {
            denyController.start(durationSeconds)
        }
    }

    function reset() {
        if (locked) {
            return
        }
        timer.stop()
        isOnBreak = true
        sessionFocusSeconds = focusSeconds
        sessionBreakSeconds = breakSeconds
    }

    compactRepresentation: CompactRepresentation{
        plasmoidItem: root
    }
    fullRepresentation: FullRepresentation{
        plasmoidItem: root
    }
}

