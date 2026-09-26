char Incoming_value = 0;
int light = 13; // TETAP DI PIN 13 (Lampu internal onboard Arduino)

void setup() {
  Serial.begin(38400); // Kecepatan HC-05 kamu
  pinMode(light, OUTPUT);
  digitalWrite(light, LOW); 
}

void loop() {
  if (Serial.available() > 0) {
    Incoming_value = Serial.read();

    if (Incoming_value == '\n' || Incoming_value == '\r') {
      return; 
    }

    // LOG NYA: Mengirim teks langsung ke layar terminal HP kamu!
    Serial.print("Arduino Menerima Byte: ");
    Serial.println(Incoming_value);
    
    // Logika kontrol ON / OFF untuk Pin 13
    if (Incoming_value == '1') {
      digitalWrite(light, HIGH); // Lampu internal "L" menyala
    }
    else if (Incoming_value == '0') {
      digitalWrite(light, LOW);  // Lampu internal "L" mati
    }
  }
}
