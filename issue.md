# Zeolife App — ON/OFF Power Button: How It Works

> **Audience:** Junior software engineer  
> **Scope:** Only the ON/OFF power toggle — how tapping the button sends `"1"` (active) or `"0"` (inactive) to the Arduino HC-05 module  
> **Default state:** Button starts **inactive** (OFF)

---

## Architecture Overview

The power button flow touches **4 files** in this exact order:

```
User taps button
    ↓
FloatingPowerController  (view/widget — UI)
    ↓
ZeoMachineController     (controller — business logic)
    ↓
BluetoothService         (service — hardware communication)
    ↓
HC-05 module receives ASCII "1" or "0"
```

---

## Step-by-Step Data Flow

### Step 1 — The Button (UI Layer)

**File:** `lib/views/widgets/floating_power_controller.dart`

This widget renders the circular power button at the bottom of the screen. It receives two things from its parent:

- `isPoweredOn` — current state (controls the button color)
- `onPressed` — callback to execute when tapped

```dart
InkWell(
  customBorder: const CircleBorder(),
  onTap: onPressed,  // ← this fires when the user taps the button
  child: Container(
    decoration: BoxDecoration(
      // coral (red) when ON, gray when OFF
      color: isPoweredOn ? AppColors.coral : AppColors.inactivePower,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.power_settings_new_rounded, ...),
  ),
)
```

**What it does:** Nothing smart — it just calls `onPressed` and displays a color based on `isPoweredOn`. All logic lives elsewhere.

---

### Step 2 — The Parent Screen Wires the Callback

**File:** `lib/views/control_screen.dart`

The `DashboardScreen` creates the `FloatingPowerController` and connects it to the `MachineController`:

```dart
FloatingPowerController(
  isPoweredOn: state.isPowerOn,
  onPressed: () => _controller.toggleMainPower(),  // ← calls the controller
)
```

The `state` object comes from a `StreamBuilder` that listens to `_controller.stateStream`. Every time the controller updates the state, this widget rebuilds and the button color changes automatically.

---

### Step 3 — The Controller (Business Logic Layer)

**File:** `lib/controllers/machine_controller.dart`

When `toggleMainPower()` is called:

```dart
void toggleMainPower() {
  final nextState = !_state.isPowerOn;                    // flip: OFF→ON or ON→OFF
  _updateState(_state.copyWith(isPowerOn: nextState));    // update local state (triggers UI rebuild)
  BluetoothService.sendPowerCommand(nextState);           // send to Arduino
}
```

**What happens here:**
1. **Flip the boolean** — if it was `false` (OFF), it becomes `true` (ON), and vice versa.
2. **Update the state** — `_updateState()` pushes the new `ZeoMachineState` into the `StreamController`, which the `StreamBuilder` in the UI is listening to. This is what makes the button change color instantly.
3. **Send the command** — calls `BluetoothService.sendPowerCommand(nextState)` to actually transmit to the HC-05.

---

### Step 4 — The Bluetooth Service (Hardware Layer)

**File:** `lib/services/bluetooth_service.dart`

```dart
static void sendPowerCommand(bool isOn) {
  if (!isConnected) {
    return;                            // guard: do nothing if not connected
  }
  _connection?.output.add(powerCommandBytes(isOn));
}
```

The bytes are built by:

```dart
static String commandForPower(bool isOn) => isOn ? '1' : '0';

static Uint8List powerCommandBytes(bool isOn) =>
    Uint8List.fromList(commandForPower(isOn).codeUnits);
```

**What this does:**
- `isOn = true` → string `'1'` → ASCII code units `[49]` → sent as 1 byte over Bluetooth
- `isOn = false` → string `'0'` → ASCII code units `[48]` → sent as 1 byte over Bluetooth

The Arduino's `Serial.read()` receives the ASCII character `'1'` or `'0'` and acts on it.

---

### Step 5 — Arduino Side (For Reference Only)

The Arduino sketch reads the incoming byte and controls an output pin:

```cpp
void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    if (c == '1') {
      digitalWrite(LED_BUILTIN, HIGH);   // ON
    } else if (c == '0') {
      digitalWrite(LED_BUILTIN, LOW);    // OFF
    }
  }
}
```

> ⚠️ **Do not modify the Arduino sketch** without the firmware owner's approval. This is shown only so you understand what happens on the receiving end.

---

## How the Connection is Established

Before the power button can send anything, the app must connect to the HC-05. This happens in the controller:

**File:** `lib/controllers/machine_controller.dart`

```dart
Future<void> connectToDevice(String macAddress) async {
  await BluetoothService.connectToDevice(macAddress);     // opens Bluetooth serial link
  _updateState(_state.copyWith(isConnected: true));        // mark as connected
  BluetoothService.sendData('GET_STATUS');                 // request initial status
}
```

Which calls into `BluetoothService.connectToDevice()`:

**File:** `lib/services/bluetooth_service.dart`

```dart
static Future<void> connectToDevice(String address) async {
  await requestPermissions();                              // Bluetooth + Location permissions
  final bluetooth = FlutterClassicBluetooth();
  _connection = await bluetooth.connect(address: address); // open SPP serial connection
  _connection?.input.listen(                               // listen for data FROM Arduino
    (bytes) {
      final received = String.fromCharCodes(bytes);
      _dataController.add(received);
    },
    onDone: () => _connection = null,
  );
}
```

**Key points:**
- The phone must already be **manually paired** with the HC-05 in Android Bluetooth settings (PIN is usually `1234`).
- The MAC address is currently a placeholder — replace `"00:00:00:00:00:00"` with the real HC-05 MAC when testing.
- Baud rate (38400) is configured on the HC-05 module and the Arduino sketch — the Flutter/Android Bluetooth SPP layer handles this transparently.

---

## Default State

**File:** `lib/models/zeo_machine_state.dart`

The `ZeoMachineState` model defines the initial state. Currently:

```dart
const ZeoMachineState({
  this.isConnected = false,
  this.isPowerOn = true,       // ⚠️ currently defaults to ON
  ...
});
```

> **Per requirements, the default should be `false` (inactive/OFF).** This needs to be changed so the button starts in the OFF state. See the fix below.

### Fix: Change Default Power State to OFF

In `lib/models/zeo_machine_state.dart`, line 68:

```diff
- this.isPowerOn = true,
+ this.isPowerOn = false,
```

This ensures:
- The button renders in the **inactive (gray)** color on app start
- The first tap sends `"1"` (ON) to the Arduino
- The second tap sends `"0"` (OFF) back

---

## Required Permissions (Already Configured)

**File:** `android/app/src/main/AndroidManifest.xml`

These are already in place:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

Runtime permission requests are handled in `BluetoothService.requestPermissions()` using the `permission_handler` package.

---

## Dependencies (Already Configured)

**File:** `pubspec.yaml`

```yaml
dependencies:
  flutter_classic_bluetooth: ^1.0.1   # Bluetooth Classic SPP — works with HC-05
  permission_handler: ^13.0.2         # Runtime permission requests
```

---

## Summary: What Happens When the User Taps the Power Button

| Step | File | What Happens |
|------|------|-------------|
| 1 | `floating_power_controller.dart` | `onTap` fires the `onPressed` callback |
| 2 | `control_screen.dart` | Callback calls `_controller.toggleMainPower()` |
| 3 | `machine_controller.dart` | Flips `isPowerOn`, updates state stream, calls `BluetoothService.sendPowerCommand()` |
| 4 | `bluetooth_service.dart` | Converts `true`→`"1"` or `false`→`"0"`, sends ASCII byte(s) over Bluetooth SPP |
| 5 | Arduino (HC-05) | `Serial.read()` receives `'1'` or `'0'`, sets output pin HIGH or LOW |

---

## Testing Checklist

- [ ] Changed `isPowerOn` default to `false` in `zeo_machine_state.dart`
- [ ] Phone paired with HC-05 manually in Android Bluetooth settings (PIN: `1234`)
- [ ] Replaced placeholder MAC address with real HC-05 MAC
- [ ] App starts with button in **inactive (gray)** state
- [ ] First tap sends `"1"` → Arduino output goes HIGH
- [ ] Second tap sends `"0"` → Arduino output goes LOW
- [ ] Disconnecting/leaving the screen calls `dispose()` properly