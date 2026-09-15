# Omarchy Smart Enter

Unlocks your Omarchy lock screen as soon as you finish typing your password: no Enter key required.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## How It Works

1. Unlock once the normal way: type your password and press **Enter**.
2. When PAM accepts it, Smart Enter remembers **only the length** of that password, in the memory of the running shell.
3. On later locks, once you type up to that length and pause briefly, your input is submitted to PAM automatically.

PAM makes every decision, exactly as if you had pressed Enter.

---

## Security Model

- **Nothing derived from your password is stored.** No password, hash, salt, or verifier is kept on disk, in the kernel keyring, or in memory. Only the length is kept, and it is forgotten when the shell restarts.
- **Every attempt goes through PAM.** Auto-submitted attempts count toward `pam_faillock` like any other attempt. There is no local password check that could be used to guess passwords without limits.
- **Repeated failures disarm Smart Enter.** After two failed auto-submits in a row it stays off until your next successful Enter unlock, so a stale length after a password change costs at most two failed attempts.
- **Fingerprint unlock** works as in the stock lock screen and does not arm Smart Enter.

### Trade-offs

- Smart Enter waits 0.4 seconds after your input reaches the full length. Typing another key during that pause cancels the auto-submit, and pressing Enter submits normally. A typo still present after the pause is submitted and counts as one failed attempt.
- Someone at your lock screen can learn your password's length by typing until it submits, at the cost of one failed attempt.
- After the shell restarts, unlock once with Enter to re-arm.

---

## Installation

```bash
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable
```

Enabling Smart Enter replaces the stock Omarchy lock screen (`omarchy.lock`). Lock your screen (`Super+Esc`), unlock once with Enter, and later unlocks submit automatically.

To check whether Smart Enter is armed:

```bash
omarchy-shell lock status
```

The output includes `"smartEnterArmed": true` once it is armed.

## Removal

```bash
omarchy plugin remove io.github.rbmrs.smart-enter
```

This restores the stock Omarchy lock screen.

## Upgrading From 1.x

Version 1.x stored a password verifier in the kernel session keyring, shipped a CLI and install scripts, and used the plugin ID `omarchy-smart-enter`. Version 2 uses `io.github.rbmrs.smart-enter`. Version 2 deletes the old keyring entry, `~/.config/omarchy/lock_hash.json`, and `~/.config/omarchy/smart_enter.json` automatically when it starts.

To upgrade from 1.x, reinstall under the new plugin ID:

```bash
omarchy plugin remove omarchy-smart-enter
omarchy plugin enable omarchy.lock
rm -f ~/.local/bin/omarchy-smart-enter
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable
omarchy restart shell
```

The shell can keep running the previously loaded 1.x code until it restarts, so restart it after upgrading by any method. Afterwards, `omarchy-shell lock status` should include `smartEnterArmed`.

`omarchy plugin remove` keeps a backup folder named `~/.config/omarchy/plugins/.omarchy-smart-enter.bak.*`, which you can delete.

## Requirements

Omarchy with its Quickshell-based shell. There are no other dependencies.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
