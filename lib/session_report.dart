import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'main_screen.dart';

class SessionReportScreen extends StatefulWidget {
  const SessionReportScreen({super.key});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isLoading = true;

  int totalMinutes = 0;
  int totalReactions = 0;
  int hairCount = 0;
  int dustCount = 0;
  int bugCount = 0;
  double avgSeconds = 0;
  String mostReacted = '';

  final Map<String, String> _typeLabels = {
    'HAIR': '머리카락',
    'DUST': '먼지',
    'BUG': '벌레',
  };

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final sessionId = await ApiService.getSessionId();
    debugPrint('sessionId: $sessionId');

    if (sessionId != null) {
      final report = await ApiService.getReport(sessionId);
      debugPrint('report response: $report');

      if (report != null && mounted) {
        setState(() {
          totalMinutes = ((report['total_duration_seconds'] ?? 0) / 60).round();
          totalReactions = report['total_reaction_count'] ?? 0;
          hairCount = report['hair_reaction_count'] ?? 0;
          dustCount = report['dust_reaction_count'] ?? 0;
          bugCount = report['bug_reaction_count'] ?? 0;
          avgSeconds = ((report['avg_reaction_time_ms'] ?? 0) / 1000);
          mostReacted = _typeLabels[report['most_reacted_type']] ?? '';
          _isLoading = false;
        });
        return;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
  }

  Future<void> _saveImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/focusbraker_result.png');
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'FocusBraker 결과',
    );
  }

  Widget _buildReactionCard({
    required String label,
    required int count,
    required String icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            '$count번',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF53FFF6),
          ),
        ),
      );
    }

    final reactions = [
      {'label': '머리카락', 'count': hairCount, 'icon': '🪱'},
      {'label': '벌레', 'count': bugCount, 'icon': '🪲'},
      {'label': '먼지', 'count': dustCount, 'icon': '🌫️'},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                      const SizedBox(height: 28),

                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                '오늘 $totalMinutes분 공부하면서',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalReactions번',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '방해에 반응했어요',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: reactions.map((entry) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: _buildReactionCard(
                                        label: entry['label'] as String,
                                        count: entry['count'] as int,
                                        icon: entry['icon'] as String,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 14),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚡ 평균 ${avgSeconds.toStringAsFixed(1)}초 만에 반응했어요',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (mostReacted.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '🔔 가장 많이 반응한 건 $mostReacted',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'FocusBraker',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _clearSession();
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MainScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF53FFF6),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '다시하기',
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
                                onPressed: _saveImage,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '저장하기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}