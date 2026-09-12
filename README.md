# Omarchy Smart Enter

A lightweight, secure Omarchy plugin that auto-submits your password the exact millisecond it is typed—**no Enter key required**.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why Smart Enter?

On a traditional Linux lock screen, you type your password and must press the **Enter** key to submit it to PAM.

**Smart Enter** listens as you type and automatically confirms authentication the moment the valid password is typed.

### Why not test PAM directly on every keystroke?
On standard Linux/Arch systems, `/etc/pam.d/omarchy-lock-password` enforces `pam_faillock` (typically `deny=10 unlock_time=120`). Testing PAM on every keystroke would trigger 9 failed attempts before you even reach character 10—**locking your account out for 2 minutes**. Furthermore, Linux `yescrypt` hashing takes 50–150ms of CPU per check, causing typing lag.

**Smart Enter solves this safely:**
- Keeps a local, salted SHA-256 hash in `~/.config/omarchy/smart_enter.json` (`chmod 600`).
- Checks candidate input on each keystroke in < 0.1ms without touching PAM.
- Typos never trigger PAM failure counters.
- The millisecond the hash matches, the full credentials are sent to PAM for the official session unlock.

---

## Features

- ⚡ **Zero-latency submission**: Unlocks instantly on the final keystroke.
- 🛡️ **PAM faillock safe**: Incomplete typing and typos never count as failed attempts.
- 🧠 **Auto-Learning**: Unlocking once with the Enter key automatically registers/updates the password hash.
- 🔄 **Self-Healing**: If you change your password with `passwd`, simply typing the new password and pressing Enter once re-trains the plugin.
- 📦 **Omarchy native**: Fully compliant with the Omarchy plugin manifest schema and Quickshell architecture.

---

## Installation

### Method 1: Using `omarchy plugin add` (Recommended)

```bash
omarchy plugin add https://github.com/rbmrs/omarchy-smart-enter.git --enable --yes
```

### Method 2: Manual Installation / Local Development

Clone this repository and run the included installer:

```bash
git clone https://github.com/rbmrs/omarchy-smart-enter.git
cd omarchy-smart-enter
./install.sh
```

---

## Usage

### Quick Start: Auto-Learning (No setup required)
1. Lock your screen (`Super+Esc` or `omarchy system lock`).
2. Type your password and press **Enter** once to let the plugin learn your password hash.
3. Lock again (`Super+Esc`): type your password—it will now auto-submit without pressing Enter!

### CLI Management: `omarchy-smart-enter`

The plugin comes with a dedicated CLI utility installed to `~/.local/bin/omarchy-smart-enter`:

```bash
# Check status and configuration file permissions
omarchy-smart-enter status

# Test password match in terminal without locking
omarchy-smart-enter test

# Manually enroll or update your password
omarchy-smart-enter setup

# Temporarily disable auto-enter
omarchy-smart-enter disable

# Re-enable auto-enter
omarchy-smart-enter enable
```

---

## File Layout

```
omarchy-smart-enter/
├── manifest.json       # Omarchy plugin manifest
├── Service.qml         # Headless PAM & auto-learn lock service
├── LockView.qml        # Real-time hash comparison lock surface
├── Sha256.js           # Fast, zero-dependency UTF-8 SHA-256 implementation
├── bin/
│   └── omarchy-smart-enter # CLI management utility
├── install.sh          # One-click installation and validation script
├── README.md           # Documentation
└── LICENSE             # MIT License
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
