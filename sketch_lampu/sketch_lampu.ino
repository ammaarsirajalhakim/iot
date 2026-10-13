#include <WiFi.h>
#include <FirebaseESP32.h>
#include <NTPClient.h> 
#include <WiFiUdp.h>   

// --- Kredensial WiFi ---
#define WIFI_SSID "REDMI Note 15 Pro+ 5G"
#define WIFI_PASSWORD "12345678"

// --- Kredensial Firebase ---
#define FIREBASE_HOST "project-iot-unw-default-rtdb.asia-southeast1.firebasedatabase.app" 
#define FIREBASE_AUTH "Q5iaMCeUKBlOMuaS8LnPJJUycQdudApNZe9NLlWk"

const int relayPin1 = 13;
const int relayPin2 = 12;
const int relayPin3 = 14;
const int relayPin4 = 27;

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// --- SETUP JAM INTERNET (NTP) ---
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 25200, 60000); 

int lastState1 = -1;
int lastState2 = -1;
int lastState3 = -1;
int lastState4 = -1;

// ==========================================
// VARIABEL CACHE UNTUK MENYIMPAN JADWAL
// ==========================================
String jNyala1 = "", jMati1 = "";
String jNyala2 = "", jMati2 = "";
String jNyala3 = "", jMati3 = "";
String jNyala4 = "", jMati4 = "";

unsigned long waktuTerakhirCekJadwal = 0;

// ==========================================
// VARIABEL GEMBOK (ANTI-BENTROK 1 MENIT)
// ==========================================
bool doneNyala1 = false, doneMati1 = false;
bool doneNyala2 = false, doneMati2 = false;
bool doneNyala3 = false, doneMati3 = false;
bool doneNyala4 = false, doneMati4 = false;

void setup() {
  Serial.begin(115200);
  
  pinMode(relayPin1, OUTPUT);
  pinMode(relayPin2, OUTPUT);
  pinMode(relayPin3, OUTPUT);
  pinMode(relayPin4, OUTPUT);

  digitalWrite(relayPin1, HIGH);
  digitalWrite(relayPin2, HIGH);
  digitalWrite(relayPin3, HIGH);
  digitalWrite(relayPin4, HIGH);

  Serial.print("Menghubungkan ke WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWiFi Terhubung!");

  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase Berhasil Terhubung!");

  timeClient.begin();
  Serial.println("Sistem Jam & Cache Siap!");
}

void loop() {
  if (Firebase.ready()) {
    
    timeClient.update();
    String jamSekarang = timeClient.getFormattedTime().substring(0, 5);

    // ==========================================
    // HEARTBEAT (KIRIM DETAK JANTUNG KE FLUTTER)
    // ==========================================
    static unsigned long waktuHeartbeat = 0;
    if (millis() - waktuHeartbeat > 10000 || waktuHeartbeat == 0) {
      // Kirim waktu Epoch NTP saat ini ke Firebase setiap 10 detik
      Firebase.setInt(firebaseData, "/system/last_beat", timeClient.getEpochTime());
      waktuHeartbeat = millis();
    }

    // ==========================================
    // 1. UPDATE JADWAL DARI FIREBASE (HANYA SETIAP 30 DETIK)
    // ==========================================
    if (millis() - waktuTerakhirCekJadwal > 30000 || waktuTerakhirCekJadwal == 0) {
      Serial.println("... Sinkronisasi Jadwal dari Firebase ...");
      
      if (Firebase.getString(firebaseData, "/jadwal/relay1/nyala")) jNyala1 = firebaseData.stringData();
      if (Firebase.getString(firebaseData, "/jadwal/relay1/mati"))  jMati1 = firebaseData.stringData();
      
      if (Firebase.getString(firebaseData, "/jadwal/relay2/nyala")) jNyala2 = firebaseData.stringData();
      if (Firebase.getString(firebaseData, "/jadwal/relay2/mati"))  jMati2 = firebaseData.stringData();

      if (Firebase.getString(firebaseData, "/jadwal/relay3/nyala")) jNyala3 = firebaseData.stringData();
      if (Firebase.getString(firebaseData, "/jadwal/relay3/mati"))  jMati3 = firebaseData.stringData();

      if (Firebase.getString(firebaseData, "/jadwal/relay4/nyala")) jNyala4 = firebaseData.stringData();
      if (Firebase.getString(firebaseData, "/jadwal/relay4/mati"))  jMati4 = firebaseData.stringData();

      waktuTerakhirCekJadwal = millis(); // Reset timer
    }

    // ==========================================
    // 2. EKSEKUSI JADWAL (DENGAN GEMBOK ANTI-BENTROK)
    // ==========================================
    
    // --- RELAY 1 ---
    if (jNyala1 != "" && jamSekarang == jNyala1) {
      if (!doneNyala1) { // Jika belum dieksekusi di menit ini
        if (lastState1 != 1) Firebase.setInt(firebaseData, "/lampu/relay1", 1);
        doneNyala1 = true; // Kunci gembok
      }
    } else { doneNyala1 = false; } // Buka gembok saat menit berganti

    if (jMati1 != "" && jamSekarang == jMati1) {
      if (!doneMati1) {
        if (lastState1 != 0) Firebase.setInt(firebaseData, "/lampu/relay1", 0);
        doneMati1 = true;
      }
    } else { doneMati1 = false; }

    // --- RELAY 2 ---
    if (jNyala2 != "" && jamSekarang == jNyala2) {
      if (!doneNyala2) {
        if (lastState2 != 1) Firebase.setInt(firebaseData, "/lampu/relay2", 1);
        doneNyala2 = true;
      }
    } else { doneNyala2 = false; }

    if (jMati2 != "" && jamSekarang == jMati2) {
      if (!doneMati2) {
        if (lastState2 != 0) Firebase.setInt(firebaseData, "/lampu/relay2", 0);
        doneMati2 = true;
      }
    } else { doneMati2 = false; }

    // --- RELAY 3 ---
    if (jNyala3 != "" && jamSekarang == jNyala3) {
      if (!doneNyala3) {
        if (lastState3 != 1) Firebase.setInt(firebaseData, "/lampu/relay3", 1);
        doneNyala3 = true;
      }
    } else { doneNyala3 = false; }

    if (jMati3 != "" && jamSekarang == jMati3) {
      if (!doneMati3) {
        if (lastState3 != 0) Firebase.setInt(firebaseData, "/lampu/relay3", 0);
        doneMati3 = true;
      }
    } else { doneMati3 = false; }

    // --- RELAY 4 ---
    if (jNyala4 != "" && jamSekarang == jNyala4) {
      if (!doneNyala4) {
        if (lastState4 != 1) Firebase.setInt(firebaseData, "/lampu/relay4", 1);
        doneNyala4 = true;
      }
    } else { doneNyala4 = false; }

    if (jMati4 != "" && jamSekarang == jMati4) {
      if (!doneMati4) {
        if (lastState4 != 0) Firebase.setInt(firebaseData, "/lampu/relay4", 0);
        doneMati4 = true;
      }
    } else { doneMati4 = false; }


    // ==========================================
    // 3. EKSEKUSI TOMBOL MANUAL (TETAP DICEK TERUS)
    // ==========================================
    if (Firebase.getInt(firebaseData, "/lampu/relay1")) {
      int val = firebaseData.intData();
      if (val != lastState1) { digitalWrite(relayPin1, val == 1 ? LOW : HIGH); lastState1 = val; Serial.println("Relay 1 Berubah"); }
    }
    if (Firebase.getInt(firebaseData, "/lampu/relay2")) {
      int val = firebaseData.intData();
      if (val != lastState2) { digitalWrite(relayPin2, val == 1 ? LOW : HIGH); lastState2 = val; Serial.println("Relay 2 Berubah"); }
    }
    if (Firebase.getInt(firebaseData, "/lampu/relay3")) {
      int val = firebaseData.intData();
      if (val != lastState3) { digitalWrite(relayPin3, val == 1 ? LOW : HIGH); lastState3 = val; Serial.println("Relay 3 Berubah"); }
    }
    if (Firebase.getInt(firebaseData, "/lampu/relay4")) {
      int val = firebaseData.intData();
      if (val != lastState4) { digitalWrite(relayPin4, val == 1 ? LOW : HIGH); lastState4 = val; Serial.println("Relay 4 Berubah"); }
    }
  }

  // Delay aman yang kamu minta sebelumnya
  delay(500); 
}