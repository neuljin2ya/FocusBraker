import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';


class FloatingDustOverlay extends StatefulWidget {
  const FloatingDustOverlay({super.key});

  @override
  State<FloatingDustOverlay> createState() => _FloatingDustOverlayState();
}

class _FloatingDustOverlayState extends State<FloatingDustOverlay> {
  final Random _random = Random();
  final List<_FloatingItemData> _items = [];
  Timer? _timer;

  // 개수
  final int itemCount = 8;

  // 맨 위 / 맨 아래 제외 영역
  final double topSafeGap = 90;
  final double bottomSafeGap = 120;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initItems();
      _startFloating();
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
    final type = _random.nextInt(10) < 3
        ? FloatingType.dust
        : FloatingType.hair;
    final minY = topSafeGap;
    final maxY = size.height - bottomSafeGap;

    return _FloatingItemData(
      type: type,
      x: _random.nextDouble() * (size.width - 80),
      y: minY + _random.nextDouble() * (maxY - minY),
      size: type == FloatingType.dust
          ? 28 + _random.nextDouble() * 32 // 먼지: 더 크게
          : 55 + _random.nextDouble() * 45, // 머리카락: 훨씬 크게
      angle: _random.nextDouble() * pi,
      opacity: type == FloatingType.dust
          ? 0.85 + _random.nextDouble() * 0.15
          : 0.80 + _random.nextDouble() * 0.20, // 진하게
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
          final dx = (_random.nextDouble() * 24) - 12;
          final dy = (_random.nextDouble() * 20) - 10;

          final maxX = (size.width - item.size);
          final maxYClamped = (maxY - item.size);

          item.x = (item.x + (_random.nextBool() ? 120 : -120))
              .clamp(0.0, maxX > 0 ? maxX : 0.0);

          item.y = (item.y + (_random.nextBool() ? 100 : -100))
              .clamp(
            minY,
            maxYClamped > minY ? maxYClamped : minY,
          );
        }
      });
    });
  }

  void _runAway(int index) {
    final size = MediaQuery.of(context).size;
    final item = _items[index];

    final minY = topSafeGap;
    final maxY = size.height - bottomSafeGap;

    setState(() {
      // 손으로 치우면 확 튀어가게
      item.x = (item.x + (_random.nextBool() ? 120 : -120))
          .clamp(0.0, size.width - item.size);
      item.y = (item.y + (_random.nextBool() ? 100 : -100))
          .clamp(minY, maxY - item.size);
      item.angle += (_random.nextDouble() * 1.2) - 0.6;
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
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => _runAway(index),
              onTapDown: (_) => _runAway(index),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 1500),
                turns: item.angle / (2 * pi),
                child: Opacity(
                  opacity: item.opacity,
                  child: item.type == FloatingType.dust
                      ? _DustItem(size: item.size)
                      : _HairItem(size: item.size),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum FloatingType { dust, hair }

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.95),
            shape: BoxShape.circle,
          ),
        ),
      ),
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