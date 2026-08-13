import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: denyMode

    property bool active: false
    property real endTime: 0
    property int graceSeconds: 15
    property int remaining: 0

    signal finished()

    readonly property string lockCheckCmd: "loginctl show-session \"$XDG_SESSION_ID\" -p LockedHint --value"
    readonly property string suspendCmd: "systemctl suspend"

    function start(durationSeconds) {
        endTime = Date.now() + durationSeconds * 1000
        active = true
        graceTimer.stop()
        remaining = durationSeconds
        pollTimer.start()
        tickTimer.start()
    }

    function _finish() {
        active = false
        remaining = 0
        graceTimer.stop()
        pollTimer.stop()
        tickTimer.stop()
        finished()
    }

    function _handleLockState(locked) {
        if (!active) {
            return
        }
        if (Date.now() >= endTime) {
            _finish()
            return
        }
        if (locked === "yes") {
            graceTimer.stop()
        } else if (!graceTimer.running) {
            graceTimer.restart()
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (sourceName === denyMode.lockCheckCmd) {
                denyMode._handleLockState(String(data["stdout"]).trim())
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: false
        onTriggered: executable.connectSource(denyMode.lockCheckCmd)
    }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            denyMode.remaining = Math.max(0, Math.ceil((denyMode.endTime - Date.now()) / 1000))
            if (Date.now() >= denyMode.endTime) {
                denyMode._finish()
            }
        }
    }

    Timer {
        id: graceTimer
        interval: denyMode.graceSeconds * 1000
        repeat: false
        onTriggered: {
            if (denyMode.active && Date.now() < denyMode.endTime) {
                executable.connectSource(denyMode.suspendCmd)
            }
        }
    }
}
