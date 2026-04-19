import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'onboarding.dart';
import 'overlay_screen.dart';
import 'session_report.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const OverlayApp());
}

void main() {
  runApp(const MyApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusBraker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00E5CC)),
      ),
      home: const StartRouter(),
    );
  }
}

class StartRouter extends StatefulWidget {
  const StartRouter({super.key});

  @override
  State<StartRouter> createState() => _StartRouterState();
}

class _StartRouterState extends State<StartRouter> {
  @override
  void initState() {
    super.initState();
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (!mounted) return;

    if (isActive == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SessionReportScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
    );
  }
}

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: const Stack(
        children: [
          Positioned.fill(
            child: FloatingDustOverlay(),
          ),
        ],
      ),
    );
  }
}