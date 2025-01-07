# Xray Update Script

This script automates the installation, management, and removal of a scheduled systemd timer and service for updating Xray TProxy. It provides an easy way to periodically update Xray using the official installation script.

## Features

- Automates the creation of a systemd service and timer to update Xray monthly.
- Supports additional configuration options like specifying the action, username, and log rotation interval.
- Provides commands to stop or fully remove the timer, service, and Xray installation.
- Validates the status of the timer and service after setup, issuing warnings if they are not active.

## Prerequisites

- Root or sudo access is required to run this script.
- Systemd must be available on the system.

## Usage

### General Syntax
```bash
./xray-autoupdate.sh <install|stop|remove> [action] [username] [--logrotate <time>]
```

### Commands

#### Install
Installs the Xray update timer and service.

```bash
./xray-autoupdate.sh install <action> <username> [--logrotate <time>]
```

- `<action>`: The action to pass to the Xray installation script (e.g., `install`, `update`).
- `<username>`: The username to pass with the `-u` option.
- `--logrotate <time>`: (Optional) Log rotation interval.

Example:
```bash
./xray-autoupdate.sh install install xray_tproxy --logrotate weekly
```

#### Stop
Stops and removes the systemd timer and service.

```bash
./xray-autoupdate.sh stop
```

#### Remove
Fully removes Xray, including the timer, service, update script, and running the official removal command.

```bash
./xray-autoupdate.sh remove
```

### Validation
After installation, the script checks the status of the `xray.service` and the `update-xray.timer`. Warnings will be displayed if either is not active or properly configured.

## Files Created

- **Update Script**: `/usr/local/bin/update_xray.sh`
  - Executes the Xray installation or update command.
- **Systemd Service**: `/etc/systemd/system/update-xray.service`
  - Runs the update script.
- **Systemd Timer**: `/etc/systemd/system/update-xray.timer`
  - Triggers the service on a monthly schedule.

## Requirements

- Bash shell
- Curl
- Systemd

## Running the script directly from GitHub

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/evgenyzh/xray-update/main/xray-autoupdate.sh)" @ install install xray_tproxy --logrotate 02:30:10
```

## Notes

- Ensure the script is executable before running:
  ```bash
  chmod +x xray-autoupdate.sh
  ```
- The script automatically reloads systemd to apply changes.

## License

This script is distributed under the Apache 2 license.
