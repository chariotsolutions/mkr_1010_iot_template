/*
  AWS IoT WiFi
  This sketch securely connects to an AWS IoT using MQTT over WiFi.
  It uses a private key stored in the ATECC508A and a public
  certificate for SSL/TLS authentication.
  It publishes a message every 5 seconds to arduino/outgoing
  topic and subscribes to messages on the arduino/incoming
  topic.
  The circuit:
  - Arduino MKR WiFi 1010 or MKR1000
  The following tutorial on Arduino Project Hub can be used
  to setup your AWS account and the MKR board:
  https://create.arduino.cc/projecthub/132016/securely-connecting-an-arduino-mkr-wifi-1010-to-aws-iot-core-a9f365
  This example code is in the public domain.
*/

#include <ArduinoBearSSL.h>
#include <ArduinoECCX08.h>
#include <ArduinoMqttClient.h>
#include <WiFiNINA.h> // change to #include <WiFi101.h> for MKR1000
#include <Arduino_MKRENV.h>
#include "./secret/arduino_secrets.h"

// Enter your sensitive data in arduino_secrets.h
const char ssid[]       = SECRET_SSID;
const char pass[]       = SECRET_PASS;
const char broker[]     = SECRET_BROKER;
const char* certificate  = SECRET_CERTIFICATE;

const char* publish_topic = "environment/telemetry";

WiFiClient    wifiClient;            // Used for the TCP socket connection
BearSSLClient sslClient(wifiClient); // Used for SSL/TLS connection, integrates with ECC508
MqttClient    mqttClient(sslClient);

unsigned long lastMillis = 0;

void setup() {
  Serial.begin(9600);
  while (!Serial);

  if (!ECCX08.begin()) {
    Serial.println("No ECCX08 present!");
    while (1);
  }

  if (!ENV.begin()) {
    Serial.println("Failed to initialize MKR ENV shield!");
    while (1);
  }

  // Set a callback to get the current time
  // used to validate the servers certificate
  ArduinoBearSSL.onGetTime(getTime);

  // Set the ECCX08 slot to use for the private key
  // and the accompanying public certificate for it
  sslClient.setEccSlot(0, certificate);

}

void publishTelemetry() {

  // read sensor values using the ENV library
  // https://www.arduino.cc/en/Reference/Arduino_MKRENV
  float temperature = ENV.readTemperature(FAHRENHEIT);   // °F
  float humidity    = ENV.readHumidity();                // % Relative Humidity
  float pressure    = ENV.readPressure(MILLIBAR);        // Pressure in Millibars
  float illuminance = ENV.readIlluminance();             // lux

  // Manually build JSON string
  String data =
    "{\n"
    "  \"temperature\": " + String(temperature, 1) + ",\n"
    "  \"humidity\": "    + String(humidity, 3)    + ",\n"
    "  \"pressure\": "    + String(pressure, 3)    + ",\n"
    "  \"illuminance\": " + String(illuminance, 3) + "\n"
    "}";

    Serial.println(data); 

    Serial.print("Sending message to queue ");
    Serial.println(publish_topic);

    mqttClient.beginMessage(publish_topic);
    mqttClient.print(data);
    mqttClient.endMessage();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  if (!mqttClient.connected()) {
    // MQTT client is disconnected, connect
    connectMQTT();
  }

  // poll for new MQTT messages and send keep alive
  mqttClient.poll();

  // publish a message roughly every 5 seconds.
  if (millis() - lastMillis > 5000) {
    lastMillis = millis();

    publishTelemetry();
  }
}

unsigned long getTime() {
  // get the current time from the WiFi module  
  return WiFi.getTime();
}

void connectWiFi() {
  Serial.print("Attempting to connect to SSID: ");
  Serial.print(ssid);

  while (WiFi.begin(ssid, pass) != WL_CONNECTED) {
    // failed, retry
    Serial.print(" .");
    delay(3000);
  }
  Serial.println("\nYou're connected to the network\n");
  
}

void connectMQTT() {
  Serial.print("Attempting to connect to MQTT broker: ");
  Serial.print(broker);

  while (!mqttClient.connect(broker, 8883)) {
    // failed, retrying
    Serial.print(" .");
    delay(3000);
  }

  Serial.println("\nYou're connected to the MQTT broker");

}

