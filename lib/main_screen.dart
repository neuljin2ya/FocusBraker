import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'api_service.dart';
import 'session_report.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Map<String, bool> _disturbTypes = {
    '머리카락': true,
    '벌레': true,
    '먼지': true,
  };

  double _level = 3;

  Future<void> _startOverlay() async {
    try {
      final hasPermission =
      await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission != true) {
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      await ApiService.clearOverlayEvents();

      final userId = await ApiService.getUserId();
      if (userId != null) {
        final sessionId = await ApiService.startSession(
          userId: userId,
          intensityLevel: _level.round(),
          hairEnabled: _disturbTypes['머리카락'] ?? true,
          dustEnabled: _disturbTypes['먼지'] ?? true,
          bugEnabled: _disturbTypes['벌레'] ?? true,
          fakeNotiEnabled: false,
        );

        if (sessionId != null) {
          await ApiService.saveSessionId(sessionId);
        }
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: 'FocusBraker',
        overlayContent: '방해 중...',
        flag: OverlayFlag.focusPointer,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await const MethodChannel('app/background')
          .invokeMethod('moveToBackground');
    } catch (e) {
      debugPrint('오버레이 시작 오류: $e');
    }
  }

  Future<void> _goToReport() async {
    try {
      final sessionId = await ApiService.getSessionId();
      final isOverlayActive = await FlutterOverlayWindow.isActive();

      // 👇 여기 추가
      debugPrint('sessionId: $sessionId');
      debugPrint('isOverlayActive: $isOverlayActive');

      if (isOverlayActive == true) {
        final events = await ApiService.getOverlayEvents();

        // 👇 이것도 추가
        debugPrint('events: $events');

        if (sessionId != null) {
          await ApiService.endSession(
            sessionId: sessionId,
            events: events,
          );
        }

        await FlutterOverlayWindow.closeOverlay();
        await ApiService.clearOverlayEvents();
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SessionReportScreen(),
        ),
      );
    } catch (e) {
      debugPrint('리포트 보기 처리 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'FocusBraker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '방해 종류',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _disturbTypes.entries.map((entry) {
                    final isLast = entry.key == _disturbTypes.keys.last;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Checkbox(
                            value: entry.value,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _disturbTypes[entry.key] = val;
                              });
                            },
                            activeColor: const Color(0xFF53FFF6),
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            color: Colors.white12,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '방해 강도',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Slider(
                  value: _level,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (val) {
                    setState(() {
                      _level = val;
                    });
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startOverlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF53FFF6),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '방해 받기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _goToReport,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFF53FFF6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '리포트 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}