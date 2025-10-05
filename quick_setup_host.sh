#!/bin/bash

# Quick Setup Script for IoT Sensor Host Pi
# Run this script on your central Raspberry Pi server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
GITHUB_USER="cgninety"
REPO_NAME="hostpi"
INSTALL_DIR="/home/pi"
HOST_IP=""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  IoT Sensor Host Pi Quick Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to detect Pi IP
detect_ip() {
    local ip=$(hostname -I | awk '{print $1}')
    echo "$ip"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get host IP
DETECTED_IP=$(detect_ip)
echo -e "${YELLOW}Detected Pi IP: $DETECTED_IP${NC}"

# Simple IP selection
if [[ "$DETECTED_IP" == "192.168.1.112" ]]; then
    echo -e "${GREEN}✓ Correct host IP detected!${NC}"
    HOST_IP="$DETECTED_IP"
else
    echo -e "${YELLOW}Expected host IP: 192.168.1.112${NC}"
    read -p "Use detected IP ($DETECTED_IP) or expected (192.168.1.112)? [d/e]: " choice
    
    case $choice in
        e|E|expected)
            HOST_IP="192.168.1.112"
            ;;
        *)
            HOST_IP="$DETECTED_IP"
            ;;
    esac
fi

echo -e "${GREEN}Using Host IP: $HOST_IP${NC}"
echo ""

# Check if running as pi user
if [[ "$USER" != "pi" ]]; then
    echo -e "${RED}This script should be run as the 'pi' user${NC}"
    echo "Switch to pi user: su - pi"
    exit 1
fi

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update -qq
sudo apt upgrade -y -qq

# Install git if needed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo apt install -y git
fi

# Navigate to install directory
cd "$INSTALL_DIR"

# Check if directory exists
if [ -d "hostpi" ]; then
    echo -e "${YELLOW}hostpi directory exists. Updating...${NC}"
    cd hostpi
    git pull origin main
else
    echo -e "${YELLOW}Cloning hostpi repository...${NC}"
    git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    cd hostpi
fi

# Make install script executable
chmod +x install_host.sh

# Run installation
echo -e "${YELLOW}Running installation script...${NC}"
sudo ./install_host.sh

# Update configuration with detected IP
echo -e "${YELLOW}Configuring host settings...${NC}"
sudo sed -i "s/host_ip: .*/host_ip: \"$HOST_IP\"/" /etc/iot-sensor/host.yaml

# Create MQTT users
echo -e "${YELLOW}Setting up MQTT authentication...${NC}"
echo -e "${BLUE}Creating default MQTT user 'sensor_client'${NC}"
sudo mosquitto_passwd -c /etc/mosquitto/passwd sensor_client
echo ""

# Start and enable services
echo -e "${YELLOW}Starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable mosquitto
sudo systemctl enable iot-sensor-host
sudo systemctl restart mosquitto
sudo systemctl restart iot-sensor-host

# Wait a moment for services to start
sleep 3

# Check service status
echo -e "${YELLOW}Checking service status...${NC}"
if systemctl is-active --quiet mosquitto; then
    echo -e "${GREEN}✓ Mosquitto MQTT broker: Running${NC}"
else
    echo -e "${RED}✗ Mosquitto MQTT broker: Failed${NC}"
fi

if systemctl is-active --quiet iot-sensor-host; then
    echo -e "${GREEN}✓ IoT Sensor Host: Running${NC}"
else
    echo -e "${RED}✗ IoT Sensor Host: Failed${NC}"
fi

# Configure firewall
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configuring firewall...${NC}"
    sudo ufw allow 8883/tcp comment "MQTT TLS" >/dev/null 2>&1 || true
    sudo ufw allow 5000/tcp comment "IoT Dashboard" >/dev/null 2>&1 || true
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Host Pi Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Host Information:${NC}"
echo "  IP Address: $HOST_IP"
echo "  MQTT Port: 8883 (TLS)"
echo "  Dashboard: http://$HOST_IP:5000"
echo ""
echo -e "${BLUE}Configuration Files:${NC}"
echo "  Host config: /etc/iot-sensor/host.yaml"
echo "  MQTT config: /etc/mosquitto/conf.d/iot-sensor.conf"
echo ""
echo -e "${BLUE}Log Commands:${NC}"
echo "  Host logs: sudo journalctl -u iot-sensor-host -f"
echo "  MQTT logs: sudo journalctl -u mosquitto -f"
echo ""
echo -e "${BLUE}MQTT User Created:${NC}"
echo "  Username: sensor_client"
echo "  Use this for client Pi connections"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Note the MQTT password you just created"
echo "2. Run the client setup script on your sensor Pis"
echo "3. Use Host IP $HOST_IP in client configurations"
echo ""
echo -e "${GREEN}Setup complete! 🎉${NC}"