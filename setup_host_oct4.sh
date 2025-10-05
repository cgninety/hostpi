#!/bin/bash

# Host Pi Setup Script - Oct 4 2025
# Supports host@node username
# Run this script on host@192.168.1.112

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GITHUB_USER="cgninety"
REPO_NAME="hostpi"
HOST_IP=""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  IoT Sensor Host Setup (Oct 4 2025)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to detect Pi IP
detect_ip() {
    hostname -I | awk '{print $1}'
}

# Get host IP
DETECTED_IP=$(detect_ip)
echo -e "${YELLOW}Detected Pi IP: $DETECTED_IP${NC}"

if [[ "$DETECTED_IP" == "192.168.1.112" ]]; then
    echo -e "${GREEN}✓ Correct host IP detected!${NC}"
    HOST_IP="$DETECTED_IP"
else
    echo -e "${YELLOW}Expected: 192.168.1.112, Got: $DETECTED_IP${NC}"
    read -p "Use detected ($DETECTED_IP) or expected (192.168.1.112)? [d/e]: " choice
    case $choice in
        e|E) HOST_IP="192.168.1.112" ;;
        *) HOST_IP="$DETECTED_IP" ;;
    esac
fi

echo -e "${GREEN}Using Host IP: $HOST_IP${NC}"

# Check user - support both pi and host users
echo -e "${BLUE}Current user: $USER${NC}"
if [[ "$USER" != "pi" && "$USER" != "host" ]]; then
    echo -e "${RED}Error: Run as 'pi' or 'host' user${NC}"
    echo "Current user: $USER"
    exit 1
fi

echo -e "${GREEN}✓ User check passed${NC}"

# Set home directory based on user
if [[ "$USER" == "host" ]]; then
    INSTALL_DIR="/home/host"
else
    INSTALL_DIR="/home/pi"
fi

echo -e "${BLUE}Installing to: $INSTALL_DIR${NC}"

# Update system
echo -e "${YELLOW}Updating system...${NC}"
sudo apt update -qq
sudo apt upgrade -y -qq

# Install git
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo apt install -y git
fi

# Clone/update repository
cd "$INSTALL_DIR"
if [ -d "hostpi" ]; then
    echo -e "${YELLOW}Updating existing repository...${NC}"
    cd hostpi
    git pull origin main
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    cd hostpi
fi

# Run installation
echo -e "${YELLOW}Running installation script...${NC}"
chmod +x install_host.sh
sudo ./install_host.sh

# Configure IP
echo -e "${YELLOW}Configuring host settings...${NC}"
sudo sed -i "s/host_ip: .*/host_ip: \"$HOST_IP\"/" /etc/iot-sensor/host.yaml

# Create MQTT user
echo -e "${YELLOW}Setting up MQTT authentication...${NC}"
echo -e "${BLUE}Creating MQTT user 'sensor_client'${NC}"
sudo mosquitto_passwd -c /etc/mosquitto/passwd sensor_client

# Start services
echo -e "${YELLOW}Starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable mosquitto iot-sensor-host
sudo systemctl restart mosquitto iot-sensor-host

sleep 3

# Check status
echo -e "${YELLOW}Service Status:${NC}"
if systemctl is-active --quiet mosquitto; then
    echo -e "${GREEN}✓ MQTT Broker: Running${NC}"
else
    echo -e "${RED}✗ MQTT Broker: Failed${NC}"
fi

if systemctl is-active --quiet iot-sensor-host; then
    echo -e "${GREEN}✓ Host Server: Running${NC}"
else
    echo -e "${RED}✗ Host Server: Failed${NC}"
fi

# Firewall
if command -v ufw &> /dev/null; then
    sudo ufw allow 8883/tcp >/dev/null 2>&1 || true
    sudo ufw allow 5000/tcp >/dev/null 2>&1 || true
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Host Details:${NC}"
echo "  IP: $HOST_IP"
echo "  MQTT: $HOST_IP:8883"
echo "  Dashboard: http://$HOST_IP:5000"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Note the MQTT password above"
echo "2. Setup client Pi with:"
echo "   curl -fsSL https://raw.githubusercontent.com/cgninety/clientpi/main/setup_client_oct4.sh | bash"
echo ""
echo -e "${GREEN}Done! 🎉${NC}"