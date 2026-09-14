# Omarchy Smart Enter

Auto-submits your lock screen password the moment it is typed: no Enter key required.

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Security Model: Ephemeral Linux Kernel Keyring

Traditional lock screens require pressing Enter to submit your password to PAM. Continuously checking PAM on every keystroke is unsafe because Linux `pam_faillock` locks accounts after failed attempts, which would lock your account during normal typing.

Older auto-enter implementations attempted to solve this by storing password hashes on disk. That approach creates an offline verification hazard: anyone who reads the file can run high-speed dictionary attacks against your password.

Smart Enter implements an ephemeral session security model using the Linux Kernel Keyring (`keyctl`):

- **Zero Credentials on Disk**: No password, salt, or hash is ever written to disk. The configuration file `~/.config/omarchy/smart_enter.json` stores strictly non-sensitive runtime flags (`{"enabled": true}`).
- **Zero Offline Attack Vectors**: Because no verifier exists on storage, an attacker with physical access to your disk or system backups has zero password hashes to crack.
- **Ephemeral Session Priming**: When you first log in or unlock your session with the Enter key, PAM validates your password. Upon success, an ephemeral HMAC verifier is registered directly in Linux Kernel Session Keyring (`@s`) and in process memory.
- **Possessor-Only Access**: Keyring permissions are locked to possessor-only (`0x3f000000`), restricting access strictly to your active login session.
- **Instant Unlock**: On subsequent lock screens, keystrokes are evaluated against the ephemeral kernel-backed session verifier in under 0.1ms. The exact millisecond the final character is typed, the password is auto-submitted to PAM.
- **Automatic Kernel Teardown**: When you log out, power down, or reboot, the Linux kernel automatically destroys and reclaims the session keyring.

---

## Features

- **Instant Unlock**: Submits credentials to PAM automatically on the final keystroke.
- **Kernel-Backed Session Security**: Leverages the Linux Kernel Keyring (`keyctl`) for session-bound verification.
- **PAM Faillock Safe**: Incomplete attempts never touch PAM and cannot trigger account lockouts.
- **Zero Disk Persistence**: Password verification data lives strictly in ephemeral kernel session memory.
- **Hardened Execution**: External helper processes execute with absolute paths, stripped environments, and strict watchdog deadlines.
- **Native Omarchy Plugin**: Runs directly inside the Quickshell Wayland session lock architecture.

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

Or run the uninstaller script:

```bash
./uninstall.sh
```

---

## Usage

### Quick Start

1. Ensure the plugin is enabled: `omarchy-smart-enter enable`.
2. Lock your screen (`Super+Esc`).
3. Enter your password and press **Enter** once to prime the session keyring.
4. Lock again (`Super+Esc`). Type your password: the screen unlocks automatically without pressing Enter.

### CLI Commands

```bash
omarchy-smart-enter status   # View active status and session keyring state
omarchy-smart-enter enable   # Enable smart enter
omarchy-smart-enter disable  # Disable smart enter
omarchy-smart-enter test     # Test session verifier against input in terminal
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
