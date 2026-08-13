import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: schedule

    property bool enabled: false
    property string helperPath: ""
    property int pollMinutes: 2
    property var intervals: []
    property string currentMode: ""
    property var currentInterval: null
    property var nextBlockedInterval: null

    signal upcomingBlockedIn(int secondsUntilStart, var interval)

    onEnabledChanged: {
        if (enabled) {
            _poll()
            pollTimer.start()
            tickTimer.start()
        } else {
            pollTimer.stop()
            tickTimer.stop()
            intervals = []
            currentMode = ""
            nextBlockedInterval = null
        }
    }

    function _poll() {
        if (!helperPath || helperPath.length === 0) {
            return
        }
        executable.connectSource(helperPath)
    }

    function _recompute() {
        var now = Date.now()
        var mode = ""
        var current = null
        var nextBlocked = null

        for (var i = 0; i < intervals.length; i++) {
            var iv = intervals[i]
            var start = Date.parse(iv.start)
            var end = Date.parse(iv.end)
            if (now >= start && now < end) {
                mode = iv.mode
                current = iv
            }
            if (iv.mode === "b" && start > now) {
                if (nextBlocked === null || start < Date.parse(nextBlocked.start)) {
                    nextBlocked = iv
                }
            }
        }

        currentMode = mode
        currentInterval = current
        nextBlockedInterval = nextBlocked
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            var stdout = data["stdout"]
            if (!stdout) {
                return
            }
            try {
                schedule.intervals = JSON.parse(String(stdout))
            } catch (e) {
                schedule.intervals = []
            }
            schedule._recompute()
        }
    }

    Timer {
        id: pollTimer
        interval: schedule.pollMinutes * 60 * 1000
        repeat: true
        running: false
        onTriggered: schedule._poll()
    }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            schedule._recompute()
            if (schedule.nextBlockedInterval !== null) {
                var secondsUntil = Math.round((Date.parse(schedule.nextBlockedInterval.start) - Date.now()) / 1000)
                if (secondsUntil >= 0) {
                    schedule.upcomingBlockedIn(secondsUntil, schedule.nextBlockedInterval)
                }
            }
        }
    }
}
