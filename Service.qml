import QtQuick
import Quickshell
import Quickshell.Io

// Carnelian runs from the Share menu and a terminal, not inside the shell.
// This service only checks that dist/install.sh has put the `carnelian`
// command and the Share menu entries in place, and says how to finish setup
// when it hasn't. It changes nothing on its own.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null
  property var manifest: null

  readonly property string installScript: Quickshell.env("HOME") + "/.config/omarchy/plugins/derekross.carnelian/dist/install.sh"

  Process {
    id: check
    command: ["bash", "-c", "command -v carnelian >/dev/null && grep -q '\"trigger.share.carnelian' \"$HOME/.config/omarchy/extensions/omarchy-menu.jsonc\" 2>/dev/null"]
    running: true
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) remind.running = true
    }
  }

  Process {
    id: remind
    command: ["notify-send", "-a", "Carnelian", "Finish setting up Carnelian",
      "Run " + root.installScript + " to add Publish to Nostr to the Share menu."]
  }
}
