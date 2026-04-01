import time
import RPi.GPIO as GPIO
import paho.mqtt.client as mqtt
import os

# --- MQTT Configuration ---
BROKER_ADDRESS = os.getenv('MQTT_BROKER', 'localhost')
BROKER_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_TOPIC = "sensor/moisture"

# --- GPIO Setup ---
MOISTURE_PIN = 4
GPIO.setmode(GPIO.BCM)
GPIO.setup(MOISTURE_PIN, GPIO.IN)

# --- MQTT Client Setup ---
client = mqtt.Client()
try:
    client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
    print(f"Connected to MQTT broker at {BROKER_ADDRESS}")
except Exception as e:
    print(f"Failed to connect to MQTT broker: {e}")
    GPIO.cleanup()
    exit()

print("Starting soil moisture monitoring... (Press Ctrl+C to stop)")
try:
    while True:
        is_dry = GPIO.input(MOISTURE_PIN)
        status = "DRY" if is_dry else "WET"
        print(f"Publishing: {status}")
        client.publish(MQTT_TOPIC, status)
        time.sleep(5)
except KeyboardInterrupt:
    print("\nMonitoring stopped by user.")
finally:
    GPIO.cleanup()
    client.disconnect()