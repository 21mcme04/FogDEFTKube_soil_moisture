import paho.mqtt.client as mqtt
import time
import os

BROKER_ADDRESS = os.getenv('MQTT_BROKER', 'localhost')
BROKER_PORT = int(os.getenv('MQTT_PORT', '1883'))
SUB_TOPIC = "sensor/moisture"
PUB_TOPIC = "actuator/control"

last_event_time = 0
debounce_time = 10.0  # seconds

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"Connected to MQTT broker at {BROKER_ADDRESS}")
        client.subscribe(SUB_TOPIC)
        print(f"Subscribed to topic: {SUB_TOPIC}")
    else:
        print(f"Failed to connect. Return code: {rc}")

def on_message(client, userdata, message):
    global last_event_time
    try:
        if (time.time() - last_event_time) < debounce_time:
            return
        status = message.payload.decode()
        print(f"Received moisture status: {status}")
        if status == "DRY":
            command = "OPEN"
            print("Soil is dry. Sending actuator command: OPEN")
            client.publish(PUB_TOPIC, command)
            last_event_time = time.time()
        elif status == "WET":
            command = "CLOSE"
            print("Soil is wet. Sending actuator command: CLOSE")
            client.publish(PUB_TOPIC, command)
            last_event_time = time.time()
    except Exception as e:
        print(f"Error processing message: {e}")

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

try:
    print(f"Connecting to MQTT broker at {BROKER_ADDRESS}:{BROKER_PORT}...")
    client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
    client.loop_forever()
except KeyboardInterrupt:
    print("\nShutting down subscriber...")
    client.disconnect()