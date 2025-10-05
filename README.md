# IoT Sensor Host Server (Raspberry Pi)

This repository contains the host server code for the IoT sensor network, designed to run on a Raspberry Pi that acts as the central hub.

## Features

- **MQTT Broker**: Eclipse Mosquitto with TLS encryption
- **Web Dashboard**: Real-time sensor monitoring and visualization
- **Data Storage**: SQLite database for sensor readings and history
- **Admin Panel**: Configuration and management interface
- **API Endpoints**: RESTful API for external integrations
- **Alert System**: Configurable alerts for sensor thresholds
- **Multi-client Support**: Handle multiple sensor clients simultaneously

## Hardware Requirements

- Raspberry Pi 3B+ or newer (recommended Pi 4B for better performance)
- MicroSD card (32GB+ recommended)
- Ethernet connection (Wi-Fi optional)
- Power supply (official Pi adapter recommended)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/hostpi.git
   cd hostpi
   ```

2. **Run the installation script:**
   ```bash
   chmod +x install_host.sh
   sudo ./install_host.sh
   ```

3. **Configure the host:**
   ```bash
   sudo nano /etc/iot-sensor/host.yaml
   ```

## Configuration

Edit `/etc/iot-sensor/host.yaml` to configure:
- MQTT broker settings
- Database configuration
- Web dashboard settings
- SSL/TLS certificates
- Alert thresholds

Example configuration:
```yaml
mqtt:
  broker_port: 8883
  use_tls: true
  max_clients: 50
  
database:
  path: "/var/lib/iot-sensor/sensors.db"
  retention_days: 365
  
dashboard:
  host: "0.0.0.0"
  port: 5000
  secret_key: "your-secret-key"
  
alerts:
  email_enabled: true
  smtp_server: "smtp.gmail.com"
  temp_threshold_high: 35.0
  temp_threshold_low: 10.0
```

## Usage

### Start the services:
```bash
sudo systemctl start iot-sensor-host
sudo systemctl start mosquitto
sudo systemctl enable iot-sensor-host
sudo systemctl enable mosquitto
```

### Access the dashboard:
Open your browser and navigate to:
- Dashboard: `http://your-pi-ip:5000`
- Admin Panel: `http://your-pi-ip:5000/admin`

### Monitor logs:
```bash
sudo journalctl -u iot-sensor-host -f
sudo journalctl -u mosquitto -f
```

### API Endpoints:
- `GET /api/sensors` - List all sensors
- `GET /api/sensors/{id}/readings` - Get sensor readings  
- `GET /api/status` - System status
- `POST /api/alerts/config` - Configure alerts

## Project Structure

```
hostpi/
├── src/                      # Source code
│   ├── main.py              # Main host application
│   ├── mqtt_broker.py       # MQTT broker management
│   ├── data_manager.py      # Database operations
│   ├── dashboard_server.py  # Web dashboard
│   └── admin_panel.py       # Administration interface
├── shared/                  # Shared utilities
│   ├── logger.py           # Logging system
│   ├── config_manager.py   # Configuration management
│   └── constants.py        # System constants
├── templates/              # HTML templates
│   ├── dashboard.html     # Main dashboard
│   ├── admin.html        # Admin panel
│   └── base.html         # Base template
├── static/               # Static web assets
│   ├── css/             # Stylesheets
│   └── js/              # JavaScript files
├── config/              # Configuration files
├── data/               # Database and data files
├── requirements.txt    # Python dependencies
├── install_host.sh    # Installation script
└── README.md         # This file
```

## Development

### Install dependencies:
```bash
pip3 install -r requirements.txt
```

### Run in development mode:
```bash
python3 src/main.py --config config/host.yaml --debug
```

### Database setup:
```bash
python3 -c "from src.data_manager import setup_database; setup_database()"
```

## Security

- TLS encryption for MQTT communication
- Authentication for admin panel
- Rate limiting on API endpoints
- Input validation and sanitization
- Regular security updates

## License

MIT License - see LICENSE file for details

## Support

For issues and questions, please use the GitHub issue tracker.