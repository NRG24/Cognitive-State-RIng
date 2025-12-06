#include <ArduinoBLE.h>

// BLE Service
BLEService sensorService("180A");  // Using a standard service UUID for testing

// BLE Characteristic
BLEStringCharacteristic dataCharacteristic("2A56",  // Using a standard characteristic UUID
    BLERead | BLENotify, 20); // 20 bytes for a simple string

void setup() {
  Serial.begin(9600);

  // Initialize BLE
  if (!BLE.begin()) {
    Serial.println("BLE failed!");
    while (1);
  }

  // Set up the BLE service and characteristic
  BLE.setLocalName("XIAO_TEST");
  BLE.setAdvertisedService(sensorService);
  sensorService.addCharacteristic(dataCharacteristic);
  BLE.addService(sensorService);

  // Initial value
  dataCharacteristic.writeValue("Hello");

  // Start advertising
  BLE.advertise();
  Serial.println("Advertising...");
}

void loop() {
  BLE.poll();

  if (BLE.connected()) {
    Serial.println("Device connected!");
    dataCharacteristic.writeValue("Connected");
    delay(1000);
  }
}
