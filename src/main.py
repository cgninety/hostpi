"""
IoT Sensor Host Server - Main Application
Coordinates MQTT broker, web dashboard, and data management
"""

import sys
import signal
import argparse
from pathlib import Path
from typing import Optional

# Add shared directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "shared"))

from shared.logger import get_logger
from shared.config_manager import ConfigManager

# Import host-specific modules
# These will be implemented as the host system grows
# from mqtt_broker import MQTTBrokerManager
# from dashboard_server import DashboardServer
# from data_manager import DataManager

class IoTSensorHost:
    """Main host server class"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.logger = get_logger('host_main')
        self.config_manager = ConfigManager()
        self.running = False
        
        # Load configuration
        if config_path:
            self.config = self.config_manager.load_config(config_path)
        else:
            self.config = self.config_manager.get_default_host_config()
        
        self.logger.info("IoT Sensor Host Server initialized")
        
        # Initialize components (to be implemented)
        # self.mqtt_broker = MQTTBrokerManager(self.config.get('mqtt', {}))
        # self.data_manager = DataManager(self.config.get('database', {}))
        # self.dashboard = DashboardServer(self.config.get('dashboard', {}))
    
    def start(self) -> None:
        """Start the host server"""
        self.logger.info("Starting IoT Sensor Host Server...")
        self.running = True
        
        try:
            # Start MQTT broker
            # self.mqtt_broker.start()
            self.logger.info("MQTT broker started (placeholder)")
            
            # Start data manager
            # self.data_manager.start()
            self.logger.info("Data manager started (placeholder)")
            
            # Start web dashboard
            # self.dashboard.start()
            self.logger.info("Web dashboard started (placeholder)")
            
            self.logger.info("Host server started successfully")
            
            # Keep running
            while self.running:
                import time
                time.sleep(1)
                
        except KeyboardInterrupt:
            self.logger.info("Received interrupt signal")
        except Exception as e:
            self.logger.error(f"Error starting host server: {e}")
        finally:
            self.stop()
    
    def stop(self) -> None:
        """Stop the host server"""
        self.logger.info("Stopping IoT Sensor Host Server...")
        self.running = False
        
        # Stop components in reverse order
        # if hasattr(self, 'dashboard'):
        #     self.dashboard.stop()
        # if hasattr(self, 'data_manager'):
        #     self.data_manager.stop()
        # if hasattr(self, 'mqtt_broker'):
        #     self.mqtt_broker.stop()
        
        self.logger.info("Host server stopped")
    
    def get_status(self) -> dict:
        """Get host server status"""
        return {
            'running': self.running,
            'config': self.config,
            'components': {
                'mqtt_broker': 'placeholder',
                'data_manager': 'placeholder', 
                'dashboard': 'placeholder'
            }
        }

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='IoT Sensor Host Server')
    parser.add_argument('--config', '-c', help='Configuration file path')
    parser.add_argument('--debug', '-d', action='store_true', help='Enable debug mode')
    
    args = parser.parse_args()
    
    # Create host server
    host = IoTSensorHost(args.config)
    
    # Set up signal handlers
    def signal_handler(signum, frame):
        host.logger.info(f"Received signal {signum}")
        host.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start the server
    if args.debug:
        host.logger.info("Debug mode enabled")
    
    host.start()

if __name__ == "__main__":
    main()