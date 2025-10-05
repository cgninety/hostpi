#!/bin/bash

# IoT Sensor Host Cleanup Script
# Removes all IoT sensor services and files from host Pi
# Run as: curl -fsSL https://raw.githubusercontent.com/cgninety/hostpi/main/cleanup_host.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  IoT Sensor Host Cleanup${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This will remove ALL IoT sensor components:${NC}"
echo "• Stop and disable all IoT sensor services"
echo "• Remove systemd service files"
echo "• Delete application files"
echo "• Remove configuration files"
echo "• Clean up MQTT broker settings"
echo "• Remove SSL certificates"
echo "• Delete log files"
echo "• Remove created users and directories"
echo ""
echo -e "${RED}WARNING: This action cannot be undone!${NC}"
echo ""

read -p "Are you sure you want to proceed? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}"

# Stop and disable services
echo -e "${BLUE}Stopping services...${NC}"
sudo systemctl stop iot-sensor-host 2>/dev/null || true
sudo systemctl disable iot-sensor-host 2>/dev/null || true
sudo systemctl stop mosquitto 2>/dev/null || true
sudo systemctl disable mosquitto 2>/dev/null || true

echo -e "${GREEN}✓ Services stopped${NC}"

# Remove systemd service files
echo -e "${BLUE}Removing service files...${NC}"
sudo rm -f /etc/systemd/system/iot-sensor-host.service
sudo systemctl daemon-reload

echo -e "${GREEN}✓ Service files removed${NC}"

# Remove application files
echo -e "${BLUE}Removing application files...${NC}"
sudo rm -rf /opt/iot-sensor-host

# Remove from user home directories
if [[ -d "/home/host/hostpi" ]]; then
    rm -rf /home/host/hostpi
fi
if [[ -d "/home/pi/hostpi" ]]; then
    rm -rf /home/pi/hostpi
fi

echo -e "${GREEN}✓ Application files removed${NC}"

# Remove configuration files
echo -e "${BLUE}Removing configuration files...${NC}"
sudo rm -rf /etc/iot-sensor
sudo rm -f /etc/mosquitto/conf.d/iot-sensor.conf
sudo rm -f /etc/mosquitto/passwd

echo -e "${GREEN}✓ Configuration files removed${NC}"

# Remove SSL certificates
echo -e "${BLUE}Removing SSL certificates...${NC}"
sudo rm -rf /etc/ssl/iot-sensor

echo -e "${GREEN}✓ SSL certificates removed${NC}"

# Remove log files
echo -e "${BLUE}Removing log files...${NC}"
sudo rm -rf /var/log/iot-sensor
sudo rm -f /var/log/mosquitto/mosquitto.log

echo -e "${GREEN}✓ Log files removed${NC}"

# Remove data directories
echo -e "${BLUE}Removing data directories...${NC}"
sudo rm -rf /var/lib/iot-sensor

echo -e "${GREEN}✓ Data directories removed${NC}"

# Remove iot-sensor user
echo -e "${BLUE}Removing iot-sensor user...${NC}"
if id "iot-sensor" &>/dev/null; then
    sudo userdel iot-sensor 2>/dev/null || true
fi

echo -e "${GREEN}✓ User removed${NC}"

# Reset mosquitto to default state
echo -e "${BLUE}Resetting MQTT broker...${NC}"
sudo systemctl stop mosquitto 2>/dev/null || true

# Reinstall mosquitto to reset to defaults
if command -v mosquitto &> /dev/null; then
    sudo apt-get purge -y mosquitto mosquitto-clients 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
fi

echo -e "${GREEN}✓ MQTT broker reset${NC}"

# Clean up firewall rules
echo -e "${BLUE}Cleaning firewall rules...${NC}"
if command -v ufw &> /dev/null; then
    sudo ufw delete allow 8883/tcp 2>/dev/null || true
    sudo ufw delete allow 5000/tcp 2>/dev/null || true
fi

echo -e "${GREEN}✓ Firewall rules cleaned${NC}"

# Remove any leftover processes
echo -e "${BLUE}Cleaning up processes...${NC}"
sudo pkill -f "iot-sensor" 2>/dev/null || true
sudo pkill -f "mosquitto" 2>/dev/null || true

echo -e "${GREEN}✓ Processes cleaned${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Host Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}What was removed:${NC}"
echo "✓ IoT Sensor Host service"
echo "✓ MQTT broker (mosquitto) purged"
echo "✓ All configuration files"
echo "✓ SSL certificates"
echo "✓ Log files and data"
echo "✓ Application directories"
echo "✓ System user account"
echo "✓ Firewall rules"
echo ""
echo -e "${BLUE}System status:${NC}"
echo "• Host Pi returned to clean state"
echo "• No IoT sensor components remain"
echo "• All ports closed"
echo "• Ready for fresh installation"
echo ""
echo -e "${GREEN}Cleanup completed successfully! 🧹${NC}"