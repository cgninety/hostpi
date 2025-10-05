#!/bin/bash

# IoT Sensor Host Installation Script
# Installs and configures the host server on Raspberry Pi

set -e

echo "IoT Sensor Host Installation Starting..."
echo "======================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install required system packages
echo "Installing system packages..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    mosquitto \
    mosquitto-clients \
    sqlite3 \
    nginx \
    openssl \
    git

# Create iot-sensor user if doesn't exist
if ! id "iot-sensor" &>/dev/null; then
    echo "Creating iot-sensor user..."
    useradd -r -s /bin/false iot-sensor
fi

# Create directories
echo "Creating directories..."
mkdir -p /opt/iot-sensor-host
mkdir -p /etc/iot-sensor
mkdir -p /var/lib/iot-sensor
mkdir -p /var/log/iot-sensor
mkdir -p /etc/ssl/iot-sensor

# Set permissions
chown -R iot-sensor:iot-sensor /opt/iot-sensor-host
chown -R iot-sensor:iot-sensor /var/lib/iot-sensor
chown -R iot-sensor:iot-sensor /var/log/iot-sensor

# Copy application files
echo "Installing application files..."
cp -r src/ /opt/iot-sensor-host/
cp -r shared/ /opt/iot-sensor-host/
cp -r templates/ /opt/iot-sensor-host/
cp -r static/ /opt/iot-sensor-host/
cp requirements.txt /opt/iot-sensor-host/

# Copy configuration
cp config/host.yaml /etc/iot-sensor/

# Install Python dependencies
echo "Installing Python dependencies..."
cd /opt/iot-sensor-host
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

# Generate SSL certificates if they don't exist
if [ ! -f /etc/ssl/iot-sensor/server.crt ]; then
    echo "Generating SSL certificates..."
    openssl genrsa -out /etc/ssl/iot-sensor/ca.key 4096
    openssl req -new -x509 -days 365 -key /etc/ssl/iot-sensor/ca.key -out /etc/ssl/iot-sensor/ca.crt -subj "/CN=IoT-Sensor-CA"
    openssl genrsa -out /etc/ssl/iot-sensor/server.key 4096
    openssl req -new -key /etc/ssl/iot-sensor/server.key -out /etc/ssl/iot-sensor/server.csr -subj "/CN=iot-sensor-host"
    openssl x509 -req -days 365 -in /etc/ssl/iot-sensor/server.csr -CA /etc/ssl/iot-sensor/ca.crt -CAkey /etc/ssl/iot-sensor/ca.key -CAcreateserial -out /etc/ssl/iot-sensor/server.crt
    
    chmod 600 /etc/ssl/iot-sensor/*.key
    chmod 644 /etc/ssl/iot-sensor/*.crt
    chown iot-sensor:iot-sensor /etc/ssl/iot-sensor/*
fi

# Configure Mosquitto MQTT broker
echo "Configuring Mosquitto MQTT broker..."
cat > /etc/mosquitto/conf.d/iot-sensor.conf << EOF
# IoT Sensor MQTT Configuration
port 8883
cafile /etc/ssl/iot-sensor/ca.crt
certfile /etc/ssl/iot-sensor/server.crt
keyfile /etc/ssl/iot-sensor/server.key
require_certificate true
use_identity_as_username true

# Logging
log_dest file /var/log/mosquitto/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information
log_type debug

# Security
allow_anonymous false
password_file /etc/mosquitto/passwd

# Connection limits
max_connections 50
max_inflight_messages 100
EOF

# Create mosquitto password file
touch /etc/mosquitto/passwd
chown mosquitto:mosquitto /etc/mosquitto/passwd
chmod 600 /etc/mosquitto/passwd

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/iot-sensor-host.service << EOF
[Unit]
Description=IoT Sensor Host Server
After=network.target mosquitto.service
Requires=mosquitto.service

[Service]
Type=simple
User=iot-sensor
Group=iot-sensor
WorkingDirectory=/opt/iot-sensor-host
Environment=PATH=/opt/iot-sensor-host/venv/bin
ExecStart=/opt/iot-sensor-host/venv/bin/python src/main.py --config /etc/iot-sensor/host.yaml
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=iot-sensor-host

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable mosquitto
systemctl enable iot-sensor-host

# Start services
echo "Starting services..."
systemctl restart mosquitto
systemctl start iot-sensor-host

# Configure firewall if ufw is available
if command -v ufw &> /dev/null; then
    echo "Configuring firewall..."
    ufw allow 8883/tcp comment "MQTT TLS"
    ufw allow 5000/tcp comment "IoT Dashboard"
fi

echo ""
echo "==============================================="
echo "IoT Sensor Host Installation Complete!"
echo "==============================================="
echo ""
echo "Services status:"
systemctl is-active mosquitto && echo "✓ Mosquitto MQTT broker: Running" || echo "✗ Mosquitto MQTT broker: Failed"
systemctl is-active iot-sensor-host && echo "✓ IoT Sensor Host: Running" || echo "✗ IoT Sensor Host: Failed"
echo ""
echo "Configuration files:"
echo "  Host config: /etc/iot-sensor/host.yaml"
echo "  MQTT config: /etc/mosquitto/conf.d/iot-sensor.conf"
echo ""
echo "Logs:"
echo "  Host logs: journalctl -u iot-sensor-host -f"
echo "  MQTT logs: journalctl -u mosquitto -f"
echo ""
echo "Dashboard URL: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "Next steps:"
echo "1. Edit /etc/iot-sensor/host.yaml for your network"
echo "2. Add MQTT users: mosquitto_passwd -c /etc/mosquitto/passwd username"
echo "3. Configure client certificates for sensor devices"
echo ""