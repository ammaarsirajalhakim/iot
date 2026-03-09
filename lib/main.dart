import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui'; 
import 'dart:math' as math;
import 'dart:async'; // WAJIB UNTUK TIMER HEARTBEAT

// ====================== GLOBAL THEME NOTIFIER ======================
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA3iWj-m6zYUgwHMKHzESLUJx_euAh3Lrk",
      appId: "1:66255449286:android:640acf4f3fd927bdd47bc7",
      messagingSenderId: "66255449286",
      projectId: "project-iot-unw",
      databaseURL:
          "https://project-iot-unw-default-rtdb.asia-southeast1.firebasedatabase.app",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LighTInk',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.cyan,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          ),
          themeMode: currentMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ====================== HELPER: FORMAT WAKTU ======================
String formatTimeOfDay(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return "$h:$m";
}

TimeOfDay? parseTimeOfDay(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty || !timeStr.contains(":")) return null;
  final parts = timeStr.split(":");
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

// ====================== ESP32 HEARTBEAT INDICATOR ======================
class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({super.key});

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  int _lastBeat = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // 1. Dengarkan detak jantung (last_beat) dari Firebase
    FirebaseDatabase.instance.ref("system/last_beat").onValue.listen((event) {
      if (event.snapshot.value != null) {
        if (mounted) {
          setState(() {
            _lastBeat = int.tryParse(event.snapshot.value.toString()) ?? 0;
          });
        }
      }
    });

    // 2. Refresh UI setiap 2 detik untuk mengecek apakah detaknya telat
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Epoch ESP32 GMT+7 ditambahkan 25200 detik, kita samakan di Flutter
    int nowInSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 25200;
    int diff = nowInSeconds - _lastBeat;

    Color dotColor;
    String statusText;

    if (_lastBeat == 0 || diff > 11) {
      dotColor = Colors.redAccent; 
      statusText = "ESP32 Offline (Mati/Terputus)";
    } else if (diff > 6) {
      dotColor = Colors.amber; 
      statusText = "Koneksi Tidak Stabil / Timeout";
    } else {
      dotColor = Colors.greenAccent; 
      statusText = "ESP32 Online & Stabil";
    }

    return Tooltip(
      message: statusText,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          boxShadow: [
            BoxShadow(
              color: dotColor.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ]
        ),
      ),
    );
  }
}

// ====================== AESTHETIC LINES PAINTER ======================
class AestheticLinesPainter extends CustomPainter {
  final Color lineColor;

  AestheticLinesPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double spacing = 35.0;

    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ====================== FUTURISTIC BACKGROUND ======================
class FuturisticBackground extends StatelessWidget {
  final Widget child;
  const FuturisticBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? Colors.cyan.withOpacity(0.08) : Colors.blue.withOpacity(0.05);

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A), Colors.black]
                  : [Colors.white, Colors.blue.shade50, Colors.grey.shade200],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: AestheticLinesPainter(lineColor: lineColor)),
        ),
        child,
      ],
    );
  }
}

// ====================== GLASSMORPHISM CARD ======================
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.cyanAccent.withOpacity(0.08), Colors.blue.withOpacity(0.03)]
                  : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(width: 1.5, color: isDark ? Colors.cyan.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ====================== ANIMATED GRADIENT BORDER ======================
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final ColorScheme colorScheme;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.borderWidth = 4.5,
    required this.colorScheme,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              transform: GradientRotation(_controller.value * 2 * math.pi),
              colors: [
                Colors.transparent,
                widget.colorScheme.primary.withOpacity(0.5),
                Colors.cyanAccent,
                widget.colorScheme.primary,
                Colors.transparent,
              ],
              stops: const [0.35, 0.45, 0.5, 0.55, 0.65],
            ),
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

// ====================== HOME SCREEN ======================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showConfirmDialog(BuildContext context, DatabaseReference dbRef, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Material(
              color: Colors.transparent,
              child: AnimatedGradientBorder(
                colorScheme: colorScheme,
                borderRadius: 24.0,
                borderWidth: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(21.0),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_circle, color: colorScheme.primary, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Konfirmasi Sistem',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Yakin ingin menyalakan semua lampu secara bersamaan?',
                              style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  FirebaseDatabase.instance.ref().update({
                                    'lampu/relay1': 1, 'lampu/relay2': 1, 'lampu/relay3': 1, 'lampu/relay4': 1,
                                    'jadwal/relay1/nyala': "", 'jadwal/relay1/mati': "",
                                    'jadwal/relay2/nyala': "", 'jadwal/relay2/mati': "",
                                    'jadwal/relay3/nyala': "", 'jadwal/relay3/mati': "",
                                    'jadwal/relay4/nyala': "", 'jadwal/relay4/mati': "",
                                  });
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('YA', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMultiScheduleDialog(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? jamNyala;
    String? jamMati;
    List<bool> selectedLamps = [true, true, true, true];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          bool isAllSelected = selectedLamps.every((element) => element);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),
                Icon(Icons.access_time_filled, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text("Atur Jadwal Multi-Lampu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Text("Pilih lampu mana saja yang ingin diterapkan jadwal ini.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 24),

                Wrap(
                  spacing: 8.0, runSpacing: 8.0, alignment: WrapAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text("Semua", style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: isAllSelected,
                      selectedColor: colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: colorScheme.primary,
                      onSelected: (val) {
                        setModalState(() { for (int i = 0; i < 4; i++) { selectedLamps[i] = val; } });
                        HapticFeedback.selectionClick();
                      },
                    ),
                    for (int i = 0; i < 4; i++)
                      FilterChip(
                        label: Text("Lampu ${i + 1}"),
                        selected: selectedLamps[i],
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: colorScheme.primary,
                        onSelected: (val) {
                          setModalState(() { selectedLamps[i] = val; });
                          HapticFeedback.selectionClick();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.2)),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
                  title: const Text("Jam Nyala Otomatis"),
                  trailing: TextButton(
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: parseTimeOfDay(jamNyala) ?? TimeOfDay.now());
                      if (t != null) setModalState(() => jamNyala = formatTimeOfDay(t));
                    },
                    child: Text(jamNyala ?? "Pilih Jam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Divider(color: Colors.grey.withOpacity(0.2)),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nights_stay_rounded, color: Colors.indigoAccent),
                  title: const Text("Jam Mati Otomatis"),
                  trailing: TextButton(
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: parseTimeOfDay(jamMati) ?? TimeOfDay.now());
                      if (t != null) setModalState(() => jamMati = formatTimeOfDay(t));
                    },
                    child: Text(jamMati ?? "Pilih Jam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      if (!selectedLamps.contains(true)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih minimal 1 lampu untuk diterapkan!"), backgroundColor: Colors.red));
                        return;
                      }
                      final db = FirebaseDatabase.instance;
                      if (jamNyala != null) { for (int i = 0; i < 4; i++) { if (selectedLamps[i]) db.ref("jadwal/relay${i + 1}/nyala").set(jamNyala); } }
                      if (jamMati != null) { for (int i = 0; i < 4; i++) { if (selectedLamps[i]) db.ref("jadwal/relay${i + 1}/mati").set(jamMati); } }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal berhasil diterapkan ke lampu terpilih!"), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('TERAPKAN JADWAL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("lampu");
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings_remote_rounded, size: 28),
            SizedBox(width: 8),
            Text('LighTInk', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            SizedBox(width: 12),
            // INI DIA LINGKARAN STATUS ESP32-NYA
            ConnectionIndicator(), 
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<ThemeMode>(
            onSelected: (mode) => themeNotifier.value = mode,
            icon: const Icon(Icons.brightness_6_rounded),
            itemBuilder: (_) => [
              const PopupMenuItem(value: ThemeMode.light, child: ListTile(leading: Icon(Icons.light_mode, color: Colors.orange), title: Text('Light'))),
              const PopupMenuItem(value: ThemeMode.dark, child: ListTile(leading: Icon(Icons.dark_mode, color: Colors.blueGrey), title: Text('Dark'))),
              const PopupMenuItem(value: ThemeMode.system, child: ListTile(leading: Icon(Icons.brightness_auto), title: Text('System'))),
            ],
          ),
        ],
      ),
      body: FuturisticBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: dbRef.onValue,
            builder: (context, snapshot) {
              int onCount = 0;
              bool isAllOff = true;
              bool isAllOn = false;

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final data = snapshot.data!.snapshot.value as Map;
                onCount = data.values.where((v) => v == 1 || v == "1").length;
                isAllOff = onCount == 0;
                isAllOn = onCount == 4;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _summaryItem(Icons.devices_rounded, 'Total', '4', colorScheme),
                            _summaryItem(Icons.lightbulb_circle, 'Nyala', '$onCount', colorScheme, isAccent: true),
                            _summaryItem(Icons.power_off_rounded, 'Mati', '${4 - onCount}', colorScheme),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                        child: Text('SYSTEM OVERRIDE',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800, letterSpacing: 3.0, color: colorScheme.onSurface.withOpacity(0.6)))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isAllOn
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _showConfirmDialog(context, dbRef, colorScheme);
                                  },
                            icon: const Icon(Icons.flash_on_rounded),
                            label: const Text("NYALAKAN SEMUA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isAllOff
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    FirebaseDatabase.instance.ref().update({
                                      'lampu/relay1': 0, 'lampu/relay2': 0, 'lampu/relay3': 0, 'lampu/relay4': 0,
                                      'jadwal/relay1/nyala': "", 'jadwal/relay1/mati': "",
                                      'jadwal/relay2/nyala': "", 'jadwal/relay2/mati': "",
                                      'jadwal/relay3/nyala': "", 'jadwal/relay3/mati': "",
                                      'jadwal/relay4/nyala': "", 'jadwal/relay4/mati': "",
                                    });
                                  },
                            icon: const Icon(Icons.power_off_rounded),
                            label: const Text("MATIKAN SEMUA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMultiScheduleDialog(context, colorScheme),
                        icon: const Icon(Icons.access_time_filled),
                        label: const Text("ATUR JADWAL", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.cyan.withOpacity(0.2) : Colors.cyan.shade50,
                          foregroundColor: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                          elevation: 0,
                          side: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: (constraints.maxWidth / crossAxisCount) / 240,
                          children: [
                            LampButton(dbRef: dbRef, defaultLabel: "Lampu 1", relayKey: "relay1"),
                            LampButton(dbRef: dbRef, defaultLabel: "Lampu 2", relayKey: "relay2"),
                            LampButton(dbRef: dbRef, defaultLabel: "Lampu 3", relayKey: "relay3"),
                            LampButton(dbRef: dbRef, defaultLabel: "Lampu 4", relayKey: "relay4"),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String title, String value, ColorScheme scheme, {bool isAccent = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isAccent ? Colors.cyan : scheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isAccent ? Colors.cyan : scheme.onSurface)),
        ],
      ),
    );
  }
}

// ====================== FUTURISTIC REMOTE BUTTON ======================
class LampButton extends StatefulWidget {
  final DatabaseReference dbRef;
  final String defaultLabel;
  final String relayKey;
  const LampButton({super.key, required this.dbRef, required this.defaultLabel, required this.relayKey});
  
  @override
  State<LampButton> createState() => _LampButtonState();
}

class _LampButtonState extends State<LampButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150), lowerBound: 0.0, upperBound: 0.1)
      ..addListener(() => setState(() => _scale = 1 - _controller.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showIndividualSettings(BuildContext context, String currentName, ColorScheme colorScheme, bool isDark) async {
    final nameCtrl = TextEditingController(text: currentName);
    
    final snapNyala = await FirebaseDatabase.instance.ref("jadwal/${widget.relayKey}/nyala").get();
    final snapMati = await FirebaseDatabase.instance.ref("jadwal/${widget.relayKey}/mati").get();
    String? jamNyala = snapNyala.value?.toString();
    String? jamMati = snapMati.value?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),
                Text("Pengaturan ${widget.defaultLabel}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Tampilan Nama Lampu",
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
                  title: const Text("Jam Nyala Otomatis"),
                  trailing: TextButton(
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: parseTimeOfDay(jamNyala) ?? TimeOfDay.now());
                      if (t != null) setModalState(() => jamNyala = formatTimeOfDay(t));
                    },
                    child: Text(jamNyala == null || jamNyala!.isEmpty ? "Pilih Jam" : jamNyala!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nights_stay_rounded, color: Colors.indigoAccent),
                  title: const Text("Jam Mati Otomatis"),
                  trailing: TextButton(
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: parseTimeOfDay(jamMati) ?? TimeOfDay.now());
                      if (t != null) setModalState(() => jamMati = formatTimeOfDay(t));
                    },
                    child: Text(jamMati == null || jamMati!.isEmpty ? "Pilih Jam" : jamMati!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      FirebaseDatabase.instance.ref("nama/${widget.relayKey}").set(nameCtrl.text);
                      if (jamNyala != null) FirebaseDatabase.instance.ref("jadwal/${widget.relayKey}/nyala").set(jamNyala);
                      if (jamMati != null) FirebaseDatabase.instance.ref("jadwal/${widget.relayKey}/mati").set(jamMati);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SIMPAN PENGATURAN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DatabaseEvent>(
      stream: widget.dbRef.child(widget.relayKey).onValue,
      builder: (context, statusSnapshot) {
        int status = 0;
        if (statusSnapshot.hasData && statusSnapshot.data!.snapshot.value != null) {
          status = int.tryParse(statusSnapshot.data!.snapshot.value.toString()) ?? 0;
        }
        final bool isOn = status == 1;

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref("nama/${widget.relayKey}").onValue,
          builder: (context, nameSnapshot) {
            String displayName = widget.defaultLabel;
            if (nameSnapshot.hasData && nameSnapshot.data!.snapshot.value != null) {
              String fetchedName = nameSnapshot.data!.snapshot.value.toString();
              if (fetchedName.trim().isNotEmpty) displayName = fetchedName;
            }

            return LayoutBuilder(builder: (context, constraints) {
              final double buttonSize = constraints.maxWidth * 0.7 > 105 ? 105 : constraints.maxWidth * 0.7;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTapDown: (_) => _controller.forward(),
                    onTapUp: (_) => _controller.reverse(),
                    onTapCancel: () => _controller.reverse(),
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      
                      FirebaseDatabase.instance.ref().update({
                        'lampu/${widget.relayKey}': isOn ? 0 : 1,
                        'jadwal/${widget.relayKey}/nyala': "",
                        'jadwal/${widget.relayKey}/mati': "",
                      });
                      
                    },
                    child: Transform.scale(
                      scale: _scale,
                      child: Container(
                        height: buttonSize,
                        width: buttonSize,
                        decoration: ShapeDecoration(
                          shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(buttonSize * 0.26),
                              side: BorderSide(width: 2.5, color: isOn ? colorScheme.primary : (isDark ? Colors.blueGrey[800]! : Colors.grey[400]!))),
                          color: isOn ? null : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
                          gradient: isOn ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary, Colors.cyan]) : null,
                          shadows: isOn
                              ? [
                                  BoxShadow(color: colorScheme.primary.withOpacity(0.6), blurRadius: 20, spreadRadius: 4),
                                  BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 30, spreadRadius: 1),
                                ]
                              : [
                                  BoxShadow(color: isDark ? Colors.black87 : Colors.grey.shade400, offset: const Offset(6, 6), blurRadius: 12, spreadRadius: 1),
                                  BoxShadow(color: isDark ? const Color(0xFF2A3A54) : Colors.white, offset: const Offset(-6, -6), blurRadius: 12, spreadRadius: 1),
                                ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: Icon(isOn ? Icons.bolt_rounded : Icons.power_settings_new_rounded,
                                key: ValueKey<bool>(isOn), size: buttonSize * 0.5, color: isOn ? Colors.white : (isDark ? Colors.blueGrey[400] : Colors.grey[500])),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark || !isOn ? (isDark ? Colors.white : Colors.black87) : colorScheme.primary)),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isOn ? colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[300])),
                          child: Text(isOn ? "ONLINE" : "OFFLINE",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: isOn ? colorScheme.primary : (isDark ? Colors.grey[400] : Colors.grey[600])))),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => _showIndividualSettings(context, displayName, colorScheme, isDark),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.settings_suggest_rounded, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              );
            });
          }
        );
      },
    );
  }
}