# Omarchy Smart Enter

Auto-submits your lock screen password the moment it is typed: no Enter key required.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## How It Works

Traditional lock screens require pressing Enter to submit your password to PAM. Testing PAM on every keystroke is unsafe because Linux `pam_faillock` locks accounts after 10 failed attempts, meaning any 10-character password would lock you out while typing.

Smart Enter solves this safely:
- Computes a local salted SHA-256 hash in `~/.config/omarchy/smart_enter.json` (`chmod 600`).
- Evaluates input on each keystroke in under 0.1ms without touching PAM.
- Typos never trigger PAM failure counters.
- When the hash matches, it submits credentials to PAM for the official session unlock.

---

## Features

- **Instant Unlock**: Submits immediately on the final keystroke.
- **PAM Faillock Safe**: Incomplete attempts never count as authentication failures.
- **Auto-Learning**: Unlocking once with the Enter key automatically registers your password hash.
- **Self-Healing**: Changing your password with `passwd` updates the hash the next time you log in with Enter.
- **Native Omarchy Plugin**: Runs directly inside Quickshell with zero external runtime dependencies.

---

## Installation

### Via `omarchy plugin add` (Recommended)

```bash
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable --yes
```

### Manual Install

```bash
git clone https://github.com/rbmrs/omarchy-smart-enter.git
cd omarchy-smart-enter
./install.sh
```

### Removal

```bash
omarchy plugin remove omarchy-smart-enter
```

---

## Usage

### Quick Start
1. Lock your screen (`Super+Esc`).
2. Type your password and press **Enter** once to train the plugin.
3. Lock again (`Super+Esc`). Type your password: it unlocks automatically.

### CLI Commands

```bash
omarchy-smart-enter status   # View active status and file permissions
omarchy-smart-enter test     # Test password match in terminal
omarchy-smart-enter setup    # Manually configure or update password
omarchy-smart-enter disable  # Disable auto-enter
omarchy-smart-enter enable   # Re-enable auto-enter
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
