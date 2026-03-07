import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase secara manual (Bypass google-services.json)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA3iWj-m6zYUgwHMKHzESLUJx_euAh3Lrk", // Contoh: AIzaSyD...
      appId: "1:66255449286:android:640acf4f3fd927bdd47bc7",       // Contoh: 1:123456789:android:abcde...
      messagingSenderId: "66255449286", // Contoh: 123456789012
      projectId: "project-iot-unw",    // Contoh: kontrol-lampu-iot-123
      // Pastikan URL di bawah ini diakhiri tanpa tanda slash (/) di belakangnya
      databaseURL: "https://project-iot-unw-default-rtdb.asia-southeast1.firebasedatabase.app", 
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kontrol IoT',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reference ke Realtime Database pada node "lampu"
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("lampu");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home Control"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          children: [
            LampButton(dbRef: dbRef, label: "Lampu 1", relayKey: "relay1"),
            LampButton(dbRef: dbRef, label: "Lampu 2", relayKey: "relay2"),
            LampButton(dbRef: dbRef, label: "Lampu 3", relayKey: "relay3"),
            LampButton(dbRef: dbRef, label: "Lampu 4", relayKey: "relay4"),
          ],
        ),
      ),
    );
  }
}

class LampButton extends StatelessWidget {
  final DatabaseReference dbRef;
  final String label;
  final String relayKey;

  const LampButton({
    super.key, 
    required this.dbRef, 
    required this.label, 
    required this.relayKey
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dbRef.child(relayKey).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        // Default status 0 (Mati)
        int status = 0;
        
        // Cek apakah ada data dari Firebase
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          status = int.tryParse(snapshot.data!.snapshot.value.toString()) ?? 0;
        }

        bool isOn = (status == 1);

        return GestureDetector(
          onTap: () {
            // Toggle nilai: jika 1 jadi 0, jika 0 jadi 1
            dbRef.child(relayKey).set(isOn ? 0 : 1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isOn ? Colors.yellow[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (isOn)
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 50,
                  color: isOn ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(height: 10),
                Text(
                  label, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOn ? Colors.white : Colors.black87,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  isOn ? "ON" : "OFF",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isOn ? Colors.white70 : Colors.grey[600],
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}