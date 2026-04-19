import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'permission_denied.dart';
import 'main_screen.dart';

class PermissionGuideScreen extends StatefulWidget {
  const PermissionGuideScreen({super.key});

  @override
  State<PermissionGuideScreen> createState() => _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends State<PermissionGuideScreen>
    with WidgetsBindingObserver {
  bool _wentToSettings = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wentToSettings) {
      _wentToSettings = false;
      _checkPermissionAndNavigate();
    }
  }

  Future<void> _checkPermissionAndNavigate() async {
    bool? hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (hasPermission == true && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PermissionDeniedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'FocusBraker 서비스 이용을 위한\n권한 허용이 필요해요',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                '다른 앱을 사용하는 동안 방해 요소를\n띄우려면 권한이 필요해요',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 권한 없이는 유튜브 보면서 방해받기가 불가능해요',
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    _wentToSettings = true;
                    await FlutterOverlayWindow.requestPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53FFF6),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('권한 허용하러 가기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => MainScreen()),
                    );
                  },
                  child: const Text('나중에', style: TextStyle(color: Colors.white70, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}