# Omarchy Smart Enter

Unlocks your Omarchy lock screen as soon as you finish typing your password: no Enter key required.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchyplugins.com/plugin.html?id=io.github.rbmrs.smart-enter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## How It Works

1. Unlock once the normal way: type your password and press **Enter**.
2. When PAM accepts it, Smart Enter remembers **only the length** of that password, in the memory of the running shell.
3. On later locks, once you type up to that length and pause for 0.2 seconds, your input is submitted to PAM automatically.

## Installation

```bash
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable
```

This replaces the stock Omarchy lock screen (`omarchy.lock`). Lock the screen with `Super+Ctrl+L`, unlock once with Enter, and later unlocks submit themselves. To check that it is armed, run `omarchy-shell smart-enter status` and look for `"armed":true`.

Smart Enter runs the stock lock screen unmodified and adds auto-submit on top, so lock screen fixes from Omarchy updates apply without updating the plugin.

## Security and Trade-offs

- **Only the length is remembered.** After a successful Enter unlock, Smart Enter keeps one number in the running shell's memory: how many characters that password had. No password, hash, salt, or verifier is written anywhere, on disk or in the kernel keyring, and the length itself is gone when the shell restarts.
- **Every attempt goes through PAM.** There is no local password check, so nothing here can be used to guess your password without limits, and auto-submitted attempts count toward `pam_faillock` like any other attempt.
- **Repeated failures disarm Smart Enter.** After two failed auto-submits with no successful password unlock in between, it stays off until your next Enter unlock. A password change therefore costs at most two failed attempts.
- **The 0.2 second pause is the escape hatch.** Editing the field during the pause cancels the auto-submit, and Enter submits immediately. A typo still present when the pause ends is submitted and counts as one failed attempt. Only typing forward to the length starts the pause, so if you overshoot and delete back, press Enter.
- **Your password's length is discoverable.** Someone at your lock screen can learn it by typing one character at a time and pausing after each, at the cost of one failed attempt.
- **Fingerprint unlock** works as on the stock lock screen. It neither arms Smart Enter nor changes what it remembers.

## Requirements

Omarchy with its Quickshell-based shell. No other dependencies.

## Disabling and Removal

```bash
omarchy plugin disable io.github.rbmrs.smart-enter   # keep it installed
omarchy plugin remove io.github.rbmrs.smart-enter    # uninstall
```

Either one restores the stock Omarchy lock screen.

## Upgrading From 1.x

Version 1.x stored a password verifier in the kernel session keyring, shipped a CLI, and used the plugin ID `omarchy-smart-enter`. Version 2 stores no verifier and deletes that state at startup. Reinstall under the new ID:

```bash
omarchy plugin remove omarchy-smart-enter
omarchy plugin enable omarchy.lock
rm -f ~/.local/bin/omarchy-smart-enter
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable
omarchy restart shell
```

Smart Enter is a `keepLoaded` service, so the shell does not swap it out while running. Restart the shell after installing or updating by any method.

If you installed 1.x with its `install.sh`, `omarchy plugin remove` leaves a backup folder at `~/.config/omarchy/plugins/.omarchy-smart-enter.bak.*`, which you can delete.

## License

MIT License. See [LICENSE](LICENSE) for details.
