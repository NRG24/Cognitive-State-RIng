This is a sensor packed device that features a GSR sensor and max30102 sensor that measure skin electrical conductivity (arousal), temperature, spo2, heart rate, and HRV. The point of this is to build a tracker that isn't focused on fitness, but cognitive health tied to the nervous system. These sensors will be packed into a small PCB that goes on one of the two rings. There is a ring on the index finger with the PCB+ one electrode and the other ring on the middle finger has the other electrode. This data is controlled by the nrf52840, a small MCU on the PCB, and sent via Bluetooth low energy to a mobile based Flutter app. The data goes through a filter, removing any outliers. Additionally, in the app there is a "Cognitive Score." The app interprets all the data and based off of an algorithm, it can give you a score out of 100 as well as some insights.

Bill of Materials:
https://docs.google.com/spreadsheets/d/1M4TGVIU_XtcH1ejhJ6mys-NpG31-dXWfCi7Ya9xVGhs/edit?usp=sharing

