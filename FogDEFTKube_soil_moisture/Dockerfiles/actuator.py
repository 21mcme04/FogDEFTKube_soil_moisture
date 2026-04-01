from gpiozero import AngularServo
from gpiozero.pins.pigpio import PiGPIOFactory
import paho.mqtt.client as mqtt
import os
import time

# --- Servo Setup ---
factory = PiGPIOFactory()
servo = AngularServo(18, min_angle=0, max_angle=180, min_pulse_width=0.0005, max_pulse_width=0.0025, pin_factory=factory)

# --- MQTT Configuration ---
BROKER_ADDRESS = os.getenv('MQTT_BROKER', 'localhost')
BROKER_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_TOPIC = "actuator/control"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"Connected to MQTT broker at {BROKER_ADDRESS}")
        client.subscribe(MQTT_TOPIC)
        print(f"Subscribed to topic: {MQTT_TOPIC}")
    else:
        print(f"Failed to connect. Return code: {rc}")

def on_message(client, userdata, msg):
    command = msg.payload.decode()
    print(f"Received actuator command: {command}")
    if command == "OPEN":
        print("Moving servo to 180 (OPEN)")
        servo.angle = 180
        time.sleep(1.5)
    elif command == "CLOSE":
        print("Moving servo to 0 (CLOSE)")
        servo.angle = 0
        time.sleep(1.5)

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

try:
    print(f"Connecting to MQTT broker at {BROKER_ADDRESS}:{BROKER_PORT}...")
    client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
    client.loop_forever()
except KeyboardInterrupt:
    print("\nShutting down actuator...")
finally:
    servo.detach()
    client.disconnect()