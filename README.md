# zeolife_app

A new Flutter project.

## Arduino code 
```cpp
/*
  ============================================================================
  ZEOLIFE MACHINE CONTROLLER
  ============================================================================
  Based on schematic: 1_1_7_ECAD_Circuit_Zeolife.pdf (U3 = Arduino Uno)

  CONFIRMED FROM SCHEMATIC (traced wire-by-wire):
    D2  -> AC Dimmer U4 "ZC"   (zero-cross detect, wired in HW, unused below)
    D3  -> AC Dimmer U4 "C1"   (drives M3, 220V AC motor)
    D4  -> SSR U8 (DA40)       (drives M4, 220V AC motor)
    D5  -> SSR U7 (DA40)       (drives R1, the Heater)
    D6  -> IRF520 driver SIG   (drives M1 + M2, 12V DC fans)
    VIN <- HLK-10M09 9V DC module (powers the Arduino itself)

  NOT YET ON THE SCHEMATIC -- ASSUMED, PLEASE VERIFY / CHANGE:
    Bluetooth module   -> SoftwareSerial on D7 (RX) / D8 (TX)
                          Wire: BT TXD -> D7, BT RXD -> D8, VCC/GND as usual
    Temperature probe  -> DS18B20 (OneWire) on D9, with a 4.7k pull-up
                          resistor between the data line and 5V.

  SAFETY NOTE: this circuit switches live 220V AC. Only qualified people
  should wire/modify it, with proper isolation or an electrician's review.
  ============================================================================
*/

#include <SoftwareSerial.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// ---------------------------------------------------------------------------
// PIN DEFINITIONS
// ---------------------------------------------------------------------------
#define ZC_PIN            2   // AC Dimmer zero-cross (input, unused for now)
#define DIMMER_C1_PIN     3   // AC Dimmer control -> M3
#define SSR_M4_PIN        4   // SSR U8 -> M4
#define SSR_HEATER_PIN    5   // SSR U7 -> Heater R1
#define DC_FAN_PIN        6   // IRF520 driver SIG -> M1 & M2 (cooling fans)

#define BT_RX_PIN         7   // <- BT module TXD
#define BT_TX_PIN         8   // -> BT module RXD
#define TEMP_PROBE_PIN    9   // DS18B20 data line

// ---------------------------------------------------------------------------
// USER-ADJUSTABLE SETTINGS
// ---------------------------------------------------------------------------
const float TARGET_TEMP_C          = 60.0;   // placeholder heating setpoint
const float TEMP_HYSTERESIS_C      = 3.0;    // cooldown gap before re-heating
const float FRAME_OVERHEAT_TEMP_C  = 75.0;   // fans force ON above this temp

unsigned long HEATING_DURATION_MIN = 15;     // <-- set your heating time (minutes)

const unsigned long TEMP_READ_INTERVAL_MS = 2000;
const unsigned long TEMP_SEND_INTERVAL_MS = 5000;

// ---------------------------------------------------------------------------
// GLOBALS
// ---------------------------------------------------------------------------
SoftwareSerial btSerial(BT_RX_PIN, BT_TX_PIN); // RX, TX

OneWire oneWire(TEMP_PROBE_PIN);
DallasTemperature tempSensor(&oneWire);

bool systemOn          = false;   // toggled by Bluetooth '1' / '0'
bool heaterActive       = false;
bool heatingCycleDone   = false;  // lockout until temp drops again
bool coolingFansOn      = false;
unsigned long heatStartTime      = 0;
unsigned long lastTempReadTime   = 0;
unsigned long lastTempSendTime   = 0;
float currentTempC = NAN;

// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(38400);
  btSerial.begin(38400);

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  pinMode(SSR_HEATER_PIN, OUTPUT);
  pinMode(SSR_M4_PIN, OUTPUT);
  pinMode(DIMMER_C1_PIN, OUTPUT);
  pinMode(DC_FAN_PIN, OUTPUT);
  pinMode(ZC_PIN, INPUT);

  digitalWrite(SSR_HEATER_PIN, LOW);
  digitalWrite(SSR_M4_PIN, LOW);
  digitalWrite(DIMMER_C1_PIN, LOW);
  digitalWrite(DC_FAN_PIN, LOW);

  tempSensor.begin();

  Serial.println(F("Zeolife controller ready. Waiting for BT '1' to start."));
}

// ---------------------------------------------------------------------------
void loop() {
  handleBluetoothCommands();

  if (systemOn) {
    updateTemperature();
    sendTemperatureOverBT();
    handleHeatingLogic();
    handleCoolingFans();
  } else {
    shutdownAllOutputs();
  }
}

// ---------------------------------------------------------------------------
void handleBluetoothCommands() {
  if (btSerial.available()) {
    char cmd = btSerial.read();

    if (cmd == '1') {
      systemOn = true;
      digitalWrite(LED_BUILTIN, HIGH); // Lights up Arduino built-in LED
      btSerial.println(F("STATUS:ON"));
      Serial.println(F("System turned ON via Bluetooth"));
    } else if (cmd == '0') {
      systemOn = false;
      digitalWrite(LED_BUILTIN, LOW);  // Turns off Arduino built-in LED
      shutdownAllOutputs();
      btSerial.println(F("STATUS:OFF"));
      Serial.println(F("System turned OFF via Bluetooth"));
    }
  }
}

// ---------------------------------------------------------------------------
void updateTemperature() {
  if (millis() - lastTempReadTime >= TEMP_READ_INTERVAL_MS) {
    lastTempReadTime = millis();
    tempSensor.requestTemperatures();
    float t = tempSensor.getTempCByIndex(0);
    if (t != DEVICE_DISCONNECTED_C) {
      currentTempC = t;
    } else {
      Serial.println(F("WARNING: temperature probe not responding"));
    }
  }
}

void sendTemperatureOverBT() {
  if (millis() - lastTempSendTime >= TEMP_SEND_INTERVAL_MS) {
    lastTempSendTime = millis();
    if (!isnan(currentTempC)) {
      btSerial.print(F("TEMP:"));
      btSerial.println(currentTempC);
    }
  }
}

// ---------------------------------------------------------------------------
// PLACEHOLDER: replace with your real "chemical component needed" trigger.
// ---------------------------------------------------------------------------
bool shouldStartHeating(float tempC) {
  return (tempC < TARGET_TEMP_C);   // TODO: replace with real trigger logic
}

void handleHeatingLogic() {
  if (isnan(currentTempC)) return;

  unsigned long heatingDurationMs = HEATING_DURATION_MIN * 60000UL;

  if (!heaterActive && !heatingCycleDone) {
    if (shouldStartHeating(currentTempC)) {
      heaterActive = true;
      heatStartTime = millis();
      digitalWrite(SSR_HEATER_PIN, HIGH);
      Serial.println(F("Heating started"));
      btSerial.println(F("HEATER:ON"));
    }
  }

  if (heaterActive) {
    if (millis() - heatStartTime >= heatingDurationMs) {
      heaterActive = false;
      heatingCycleDone = true;
      digitalWrite(SSR_HEATER_PIN, LOW);
      Serial.println(F("Heating finished (duration elapsed)"));
      btSerial.println(F("HEATER:OFF"));
    }
  }

  if (heatingCycleDone && currentTempC < (TARGET_TEMP_C - TEMP_HYSTERESIS_C)) {
    heatingCycleDone = false;
  }
}

// ---------------------------------------------------------------------------
void handleCoolingFans() {
  bool needCooling = heaterActive ||
                      (!isnan(currentTempC) && currentTempC > FRAME_OVERHEAT_TEMP_C);

  if (needCooling != coolingFansOn) {
    coolingFansOn = needCooling;
    digitalWrite(DC_FAN_PIN, coolingFansOn ? HIGH : LOW);
    Serial.println(coolingFansOn ? F("Cooling fans ON") : F("Cooling fans OFF"));
  }
}

// ---------------------------------------------------------------------------
// M3 / M4 helpers -- ready to use, not auto-called (purpose unspecified)
// ---------------------------------------------------------------------------
void setM3(bool on) {
  digitalWrite(DIMMER_C1_PIN, on ? HIGH : LOW);
}

void setM4(bool on) {
  digitalWrite(SSR_M4_PIN, on ? HIGH : LOW);
}

// ---------------------------------------------------------------------------
void shutdownAllOutputs() {
  digitalWrite(SSR_HEATER_PIN, LOW);
  heaterActive = false;
  digitalWrite(DC_FAN_PIN, LOW);
  coolingFansOn = false;
  setM3(false);
  setM4(false);
}
```
