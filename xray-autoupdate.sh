#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Path to the Xray update script
SCRIPT_PATH="/usr/local/bin/update_xray.sh"

# Check for required arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <action> <username> [--logrotate <time>]"
    exit 1
fi

# Read arguments
ACTION=$1
USERNAME=$2
LOGROTATE=""
if [ "$3" == "--logrotate" ] && [ -n "$4" ]; then
    LOGROTATE="--logrotate $4"
fi

# Add -u prefix to USERNAME if not provided
if [[ "$USERNAME" != -* ]]; then
    USERNAME="-u $USERNAME"
fi

# Create the Xray update script
cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

# Execute the command to install or update Xray
bash -c "\$(curl -L https://github.com/evgenyzh/Xray-install/raw/main/install-release.sh)" @ $ACTION $USERNAME $LOGROTATE
EOF

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Create the systemd service file
SERVICE_FILE="/etc/systemd/system/update-xray.service"
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Update Xray TProxy
Wants=update-xray.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

# Create the systemd timer file
TIMER_FILE="/etc/systemd/system/update-xray.timer"
cat << EOF > "$TIMER_FILE"
[Unit]
Description=Run Update Xray TProxy Monthly

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd and enable the timer
systemctl daemon-reload
systemctl enable update-xray.timer
systemctl start update-xray.timer

# Check the status of the timer and service
success=true
timer_status=$(systemctl is-active update-xray.timer)
service_status=$(systemctl is-active xray.service)

if [ "$timer_status" != "active" ]; then
    echo "Warning: The update-xray.timer is not active. Please check the timer configuration."
    success=false
fi

if [ "$service_status" != "active" ]; then
    echo "Warning: The xray.service is not running. Please ensure the Xray service is correctly configured and started."
    success=false
fi

# Display timer status
systemctl list-timers --all | grep update-xray

if [ "$success" = true ]; then
    echo "Xray update service and timer have been successfully created and started."
fi
