#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Path to the Xray update script
SCRIPT_PATH="/usr/local/bin/update_xray.sh"
SERVICE_FILE="/etc/systemd/system/update-xray.service"
TIMER_FILE="/etc/systemd/system/update-xray.timer"

# Function to create the update script
create_update_script() {

    cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

# Execute the command to install or update Xray
bash -c "\$(curl -L https://github.com/evgenyzh/Xray-install/raw/main/install-release.sh)" @ $@
EOF

    chmod +x "$SCRIPT_PATH"
}

# Function to create the systemd service file
create_service_file() {
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Update Xray TProxy
Wants=update-xray.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF
}

# Function to create the systemd timer file
create_timer_file() {
    cat << EOF > "$TIMER_FILE"
[Unit]
Description=Run Update Xray TProxy Monthly

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

# Function to reload and start the timer
reload_and_start_timer() {
    systemctl daemon-reload
    systemctl enable update-xray.timer
    systemctl start update-xray.timer

    local success=true
    local timer_status=$(systemctl is-active update-xray.timer)
    local service_status=$(systemctl is-active xray.service)

    if [ "$timer_status" != "active" ]; then
        echo "Warning: The update-xray.timer is not active. Please check the timer configuration."
        success=false
    fi

    if [ "$service_status" != "active" ]; then
        echo "Warning: The xray.service is not running. Please ensure the Xray service is correctly configured and started."
        success=false
    fi

    systemctl list-timers --all | grep update-xray

    if [ "$success" = true ]; then
        echo "Xray update service and timer have been successfully created and started."
    fi
}

# Function to execute command
execute_command () {
    echo "Execute update:"
    local command_run_status=$(eval "$SCRIPT_PATH")
    echo "$command_run_status"
}

# Function to stop and remove the timer and service
remove_timer_and_service() {
    echo "Stopping and disabling the timer and service..."
    systemctl stop update-xray.timer 2>/dev/null
    systemctl disable update-xray.timer 2>/dev/null
    rm -f "$TIMER_FILE"
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    echo "Timer and service removed."
}

# Function to fully remove Xray and related configurations
full_remove() {
    remove_timer_and_service
    echo "Running the Xray removal command..."
    bash -c "\$(curl -L https://github.com/evgenyzh/Xray-install/raw/main/install-release.sh)" @ remove
    rm -f "$SCRIPT_PATH"
    echo "Xray and all related configurations have been fully removed."
}

# Check for required arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <install|stop|remove> [action] [username] [--logrotate <time>]"
    exit 1
fi

# Read the first argument to determine the action
COMMAND=$1
shift

case "$COMMAND" in
    install)
        # Check for additional arguments
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 install <action> <username> [--logrotate <time>]"
            exit 1
        fi
        
        ACTION=$1
        LOGROTATE=""
	LOGROTATE_TIME=""
	if [ "$2" == "--logrotate" ] && [ -n "$3" ]; then	
            USERNAME=""
            LOGROTATE="--logrotate"
	    LOGROTATE_TIME="$3"
        else
	    USERNAME="$2"
	fi
	
        if [ "$3" == "--logrotate" ] && [ -n "$4" ]; then
            LOGROTATE="--logrotate"
	    LOGROTATE_TIME="$4"
        fi

        # Add -u prefix to USERNAME if not provided
        if [[ -n "$USERNAME" && "$USERNAME" != -* ]]; then
            USERNAME="-u $USERNAME"
        fi
        
        create_update_script "$ACTION" "$USERNAME" "$LOGROTATE" "$LOGROTATE_TIME"
        create_service_file
        create_timer_file
        reload_and_start_timer
	execute_command
        ;;
    stop)
        remove_timer_and_service
        ;;
    remove)
        full_remove
        ;;
    *)
        echo "Invalid command: $COMMAND"
        echo "Usage: $0 <install|stop|remove> [action] [username] [--logrotate <time>]"
        exit 1
        ;;
esac
