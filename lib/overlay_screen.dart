import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

class FloatingDustOverlay extends StatefulWidget {
  const FloatingDustOverlay({super.key});

  @override
  State<FloatingDustOverlay> createState() => _FloatingDustOverlayState();
}

class _FloatingDustOverlayState extends State<FloatingDustOverlay> {
  final Random _random = Random();
  final List<_FloatingItemData> _items = [];
  Timer? _timer;

  final int itemCount = 8;
  final double topSafeGap = 90;
  final double bottomSafeGap = 120;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _clearEventFile();
      _initItems();
      _startFloating();
    });
  }

  Future<void> _clearEventFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/events.json');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('events 파일 초기화 오류: $e');
    }
  }

  Future<void> _runAway(int index) async {
    final size = MediaQuery.of(context).size;
    final item = _items[index];

    debugPrint('터치됨: ${item.type.name}, index: $index');

    final minY = topSafeGap;
    final maxY = size.height - bottomSafeGap;

    final events = await ApiService.getOverlayEventsFromFile();
    final now = DateTime.now().toUtc();

    events.add({
      "distraction_type": item.type.name.toUpperCase(), // BUG / HAIR / DUST
      "appeared_at": now.toIso8601String(),
      "reacted_at": now.toIso8601String(),
      "reaction_time_ms": 1, // 서버에서 양수 요구
    });

    await ApiService.saveOverlayEventsToFile(events);
    debugPrint('저장된 events 개수: ${events.length}');

    setState(() {
      item.x = (item.x + (_random.nextBool() ? 40 : -40))
          .clamp(0.0, size.width - item.size);
      item.y = (item.y + (_random.nextBool() ? 30 : -30))
          .clamp(minY, maxY - item.size);
      item.angle += (_random.nextDouble() * 1.2) - 0.6;
    });
  }

  void _initItems() {
    final size = MediaQuery.of(context).size;

    _items.clear();
    for (int i = 0; i < itemCount; i++) {
      _items.add(_createRandomItem(size));
    }

    setState(() {});
  }

  _FloatingItemData _createRandomItem(Size size) {
    final rand = _random.nextInt(10);

    final type = rand < 3
        ? FloatingType.dust
        : rand < 6
        ? FloatingType.hair
        : FloatingType.bug;

    final minY = topSafeGap;
    final maxY = size.height - bottomSafeGap;

    return _FloatingItemData(
      type: type,
      x: _random.nextDouble() * (size.width - 80),
      y: minY + _random.nextDouble() * (maxY - minY),
      size: type == FloatingType.dust
          ? 28 + _random.nextDouble() * 32
          : type == FloatingType.hair
          ? 55 + _random.nextDouble() * 45
          : 60 + _random.nextDouble() * 40,
      angle: _random.nextDouble() * pi,
      opacity: type == FloatingType.dust
          ? 0.85 + _random.nextDouble() * 0.15
          : type == FloatingType.hair
          ? 0.80 + _random.nextDouble() * 0.20
          : 0.95,
    );
  }

  void _startFloating() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;

      final size = MediaQuery.of(context).size;
      final minY = topSafeGap;
      final maxY = size.height - bottomSafeGap;

      setState(() {
        for (final item in _items) {
          final maxX = size.width - item.size;
          final maxYClamped = maxY - item.size;

          item.x = (item.x + (_random.nextBool() ? 60 : -60))
              .clamp(0.0, maxX > 0 ? maxX : 0.0);

          item.y = (item.y + (_random.nextBool() ? 50 : -50)).clamp(
            minY,
            maxYClamped > minY ? maxYClamped : minY,
          );

          item.angle += (_random.nextDouble() * 0.6) - 0.3;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: List.generate(_items.length, (index) {
          final item = _items[index];

          return AnimatedPositioned(
            duration: Duration(
              milliseconds: 1600 + _random.nextInt(1200),
            ),
            curve: Curves.easeInOut,
            left: item.x,
            top: item.y,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _runAway(index),
              onPanStart: (_) => _runAway(index),
              child: SizedBox(
                width: item.size + 40,
                height: item.size + 40,
                child: Center(
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 1500),
                    turns: item.angle / (2 * pi),
                    child: Opacity(
                      opacity: item.opacity,
                      child: item.type == FloatingType.dust
                          ? _DustItem(size: item.size)
                          : item.type == FloatingType.hair
                          ? _HairItem(size: item.size)
                          : _BugItem(
                        size: item.size,
                        assetPath: 'assets/bug2.png',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum FloatingType { dust, hair, bug }

class _FloatingItemData {
  FloatingType type;
  double x;
  double y;
  double size;
  double angle;
  double opacity;

  _FloatingItemData({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    required this.opacity,
  });
}

class _DustItem extends StatelessWidget {
  final double size;

  const _DustItem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/dust.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
class _HairItem extends StatelessWidget {
  final double size;

  const _HairItem({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.55),
      painter: _HairPainter(),
    );
  }
}

class _BugItem extends StatelessWidget {
  final double size;
  final String assetPath;

  const _BugItem({
    required this.size,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _HairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.08, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.05,
      size.width * 0.7,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.7,
      size.width * 0.96,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}