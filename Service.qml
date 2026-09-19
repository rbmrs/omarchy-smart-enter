import QtQuick
import Quickshell
import Quickshell.Io

// Smart Enter wraps the stock omarchy.lock service instead of forking it: the
// upstream Service.qml runs unmodified (lock surface, PAM, IPC "lock" target),
// and this file only watches its public state and calls submitPassword().
Item {
  id: root

  property var shell: null
  property string omarchyPath: ""

  readonly property string home: Quickshell.env("HOME")
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
  readonly property string upstreamServiceUrl: omarchyPath.length > 0
    ? "file://" + omarchyPath + "/shell/plugins/lock/Service.qml" : ""
  readonly property var lock: upstreamLoader.status === Loader.Ready ? upstreamLoader.item : null

  // After a manual Enter unlock succeeds, only the password's length is kept,
  // in memory. Input that reaches that length is submitted to PAM, so every
  // attempt still counts toward pam_faillock. No password, hash, or verifier
  // is kept anywhere.
  property int smartEnterLength: 0
  // Consecutive failed auto-submits. One is usually a typo; repeated failures
  // suggest a stale remembered length, so Smart Enter disarms.
  property int smartEnterFailures: 0
  readonly property int smartEnterFailureLimit: 2
  // Pause after typing reaches the length, so a further keystroke or Enter can
  // still take over before anything is auto-submitted.
  readonly property int autoSubmitDelay: 200

  property int previousPasswordLength: 0
  // Set only for the duration of our own submitPassword() call.
  property bool autoSubmitting: false
  // The password attempt PAM is currently checking: its length and whether we
  // submitted it. Cleared when it fails.
  property int inFlightLength: 0
  property bool inFlightAuto: false

  function logEvent(event) {
    if (lock) lock.logEvent(event)
    else console.log("smart-enter " + event)
  }

  function primeSmartEnter(length) {
    if (length <= 0) return
    smartEnterFailures = 0
    smartEnterLength = length
    logEvent("smart-enter: armed")
  }

  function disarmSmartEnter(reason) {
    smartEnterFailures = 0
    if (smartEnterLength === 0) return
    smartEnterLength = 0
    logEvent("smart-enter: disarmed " + reason)
  }

  function recordAutoSubmitFailure() {
    smartEnterFailures += 1
    if (smartEnterFailures >= smartEnterFailureLimit) disarmSmartEnter("after-" + smartEnterFailures + "-failed-auto-submits")
    else logEvent("smart-enter: auto-submit failed " + smartEnterFailures + "/" + smartEnterFailureLimit)
  }

  function clearInFlight() {
    inFlightLength = 0
    inFlightAuto = false
  }

  function autoSubmit() {
    if (!lock || smartEnterLength <= 0) return
    if (!lock.lockRequested || lock.authenticatingPassword) return
    var password = lock.enteredPassword
    if (password.length !== smartEnterLength) return

    autoSubmitting = true
    lock.enteredPassword = ""
    lock.submitPassword(password)
    autoSubmitting = false
  }

  Loader {
    id: upstreamLoader
    source: root.upstreamServiceUrl
    onLoaded: {
      item.omarchyPath = root.omarchyPath
      item.shell = root.shell
    }
    onStatusChanged: {
      if (status === Loader.Error) console.warn("smart-enter: failed to load the stock lock service from " + source)
    }
  }

  onShellChanged: if (lock) lock.shell = shell

  Timer {
    id: autoSubmitTimer
    interval: root.autoSubmitDelay
    repeat: false
    onTriggered: root.autoSubmit()
  }

  Connections {
    target: root.lock

    // Typing forward to the remembered length starts the grace period. Any
    // other edit cancels it (Enter clears the field first); deleting back down
    // to the length does not start it.
    function onEnteredPasswordChanged() {
      var length = root.lock.enteredPassword.length
      if (root.smartEnterLength > 0 && length === root.smartEnterLength && root.previousPasswordLength < root.smartEnterLength) autoSubmitTimer.restart()
      else autoSubmitTimer.stop()
      root.previousPasswordLength = length
    }

    // submitPassword() sets pendingPassword before PAM starts, and it is only
    // cleared in between, so each attempt shows up here once.
    function onPendingPasswordChanged() {
      if (root.lock.pendingPassword.length === 0) return
      root.inFlightLength = root.lock.pendingPassword.length
      root.inFlightAuto = root.autoSubmitting
    }

    // A failed auto-submit is a typo or a stale remembered length. Repeated
    // failures fall back to Enter until the next manual unlock succeeds.
    function onFailedAttemptsChanged() {
      if (root.lock.failedAttempts === 0) return
      if (root.inFlightAuto) root.recordAutoSubmitFailure()
      root.clearInFlight()
    }

    // PAM success clears authenticatingPassword and pendingPassword before
    // finishUnlock() drops lockRequested. A fingerprint unlock or a lost
    // session lock drops lockRequested with a password still in flight or
    // none at all, so neither can arm Smart Enter.
    function onLockRequestedChanged() {
      autoSubmitTimer.stop()
      if (root.lock.lockRequested) {
        root.clearInFlight()
        return
      }
      if (root.inFlightLength > 0 && !root.lock.authenticatingPassword && root.lock.pendingPassword.length === 0) {
        root.smartEnterFailures = 0
        if (!root.inFlightAuto) root.primeSmartEnter(root.inFlightLength)
      }
      root.clearInFlight()
    }
  }

  Timer {
    id: legacyCleanupWatchdog
    interval: 3000
    repeat: false
    onTriggered: {
      if (legacyCleanupProc.running) {
        root.logEvent("smart-enter: legacy-cleanup-timeout")
        legacyCleanupProc.running = false
      }
    }
  }

  // Versions before 2.0 kept a password verifier on disk and in the session
  // keyring. Delete that state once at startup.
  Process {
    id: legacyCleanupProc
    command: [
      "/usr/bin/bash",
      "-c",
      "/usr/bin/rm -f -- \"$HOME/.config/omarchy/lock_hash.json\" \"$HOME/.config/omarchy/smart_enter.json\"; if [ -x /usr/bin/keyctl ]; then /usr/bin/keyctl purge -s user omarchy:smart_enter >/dev/null 2>&1; fi; exit 0"
    ]
    clearEnvironment: true
    environment: ({
      "PATH": "/usr/bin",
      "LC_ALL": "C",
      "USER": root.userName,
      "HOME": root.home
    })
    onStarted: legacyCleanupWatchdog.restart()
    onExited: legacyCleanupWatchdog.stop()
  }

  Component.onCompleted: legacyCleanupProc.running = true

  IpcHandler {
    target: "smart-enter"

    function status(): string {
      return JSON.stringify({
        loaded: root.lock !== null,
        armed: root.smartEnterLength > 0,
        failures: root.smartEnterFailures
      })
    }
  }
}
