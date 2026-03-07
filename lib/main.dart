import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptic feedback
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui'; // for ImageFilter and Paint

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
          title: 'SmartHome Pro',
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
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
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
    
    final lineColor = isDark 
        ? Colors.cyan.withOpacity(0.08) 
        : Colors.blue.withOpacity(0.05);

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
          child: CustomPaint(
            painter: AestheticLinesPainter(lineColor: lineColor),
          ),
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
                  ? [
                      Colors.cyanAccent.withOpacity(0.08),
                      Colors.blue.withOpacity(0.03),
                    ]
                  : [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1.5,
              color: isDark
                  ? Colors.cyan.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ====================== HOME SCREEN ======================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("lampu");
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings_remote_rounded, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'LightTink',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<ThemeMode>(
            onSelected: (mode) => themeNotifier.value = mode,
            icon: const Icon(Icons.brightness_6_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: ThemeMode.light,
                child: ListTile(
                    leading: Icon(Icons.light_mode, color: Colors.orange),
                    title: Text('Light')),
              ),
              const PopupMenuItem(
                value: ThemeMode.dark,
                child: ListTile(
                    leading: Icon(Icons.dark_mode, color: Colors.blueGrey),
                    title: Text('Dark')),
              ),
              const PopupMenuItem(
                value: ThemeMode.system,
                child: ListTile(
                    leading: Icon(Icons.brightness_auto), title: Text('System')),
              ),
            ],
          ),
        ],
      ),
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== SUMMARY CARD ====================
                StreamBuilder<DatabaseEvent>(
                  stream: dbRef.onValue,
                  builder: (context, snapshot) {
                    int onCount = 0;
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      final data = snapshot.data!.snapshot.value as Map;
                      onCount = data.values.where((v) => v == 1).length;
                    }

                    return GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _summaryItem(Icons.devices_rounded, 'Total', '4', colorScheme),
                            _summaryItem(Icons.lightbulb_circle, 'Nyala', '$onCount',
                                colorScheme,
                                isAccent: true),
                            _summaryItem(Icons.power_off_rounded, 'Mati',
                                '${4 - onCount}', colorScheme),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Center(
                  child: FittedBox(
                    child: Text(
                      'SYSTEM OVERRIDE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== GRID REMOTE BUTTONS ====================
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    // Menghitung aspect ratio secara dinamis agar tinggi grid menyesuaikan
                    final double spacing = 20.0;
                    final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                    final double itemHeight = 220.0; // Minimal ruang aman untuk widget LampButton
                    final double childAspectRatio = itemWidth / itemHeight;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: childAspectRatio, 
                      children: [
                        LampButton(dbRef: dbRef, label: "Lampu 1", relayKey: "relay1"),
                        LampButton(dbRef: dbRef, label: "Lampu 2", relayKey: "relay2"),
                        LampButton(dbRef: dbRef, label: "Lampu 3", relayKey: "relay3"),
                        LampButton(dbRef: dbRef, label: "Lampu 4", relayKey: "relay4"),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String title, String value, ColorScheme scheme,
      {bool isAccent = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isAccent ? Colors.cyan : scheme.primary),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isAccent ? Colors.cyan : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== FUTURISTIC REMOTE BUTTON ======================
class LampButton extends StatefulWidget {
  final DatabaseReference dbRef;
  final String label;
  final String relayKey;

  const LampButton({
    super.key,
    required this.dbRef,
    required this.label,
    required this.relayKey,
  });

  @override
  State<LampButton> createState() => _LampButtonState();
}

class _LampButtonState extends State<LampButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {
          _scale = 1 - _controller.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DatabaseEvent>(
      stream: widget.dbRef.child(widget.relayKey).onValue,
      builder: (context, snapshot) {
        int status = 0;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          status = int.tryParse(snapshot.data!.snapshot.value.toString()) ?? 0;
        }
        final bool isOn = status == 1;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Skala responsif: Batasi maksimum ukuran tombol 105
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
                    widget.dbRef.child(widget.relayKey).set(isOn ? 0 : 1);
                  },
                  child: Transform.scale(
                    scale: _scale,
                    child: Container(
                      height: buttonSize,
                      width: buttonSize,
                      decoration: ShapeDecoration(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonSize * 0.26), // Skala dinamis
                          side: BorderSide(
                            width: 2.5,
                            color: isOn
                                ? colorScheme.primary
                                : (isDark ? Colors.blueGrey[800]! : Colors.grey[400]!),
                          ),
                        ),
                        color: isOn
                            ? null
                            : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
                        gradient: isOn
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  Colors.cyan,
                                ],
                              )
                            : null,
                        shadows: isOn
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: Colors.cyan.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: isDark ? Colors.black87 : Colors.grey.shade400,
                                  offset: const Offset(6, 6),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: isDark ? const Color(0xFF2A3A54) : Colors.white,
                                  offset: const Offset(-6, -6),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => 
                            ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isOn ? Icons.bolt_rounded : Icons.power_settings_new_rounded,
                            key: ValueKey<bool>(isOn),
                            size: buttonSize * 0.5, // Icon size dinamis
                            color: isOn
                                ? Colors.white
                                : (isDark ? Colors.blueGrey[400] : Colors.grey[500]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                Flexible(child: const SizedBox(height: 16)),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: isOn
                        ? Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [colorScheme.primary, Colors.cyanAccent],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                            )
                        : Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                  ),
                ),
                
                const SizedBox(height: 8),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOn ? Colors.cyan : Colors.transparent,
                        width: 1.5,
                      ),
                      color: isOn
                          ? Colors.cyan.withOpacity(0.15)
                          : (isDark ? Colors.grey[800] : Colors.grey[300]),
                    ),
                    child: Text(
                      isOn ? "ONLINE" : "OFFLINE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: isOn 
                            ? Colors.cyanAccent 
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}