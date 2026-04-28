import 'dart:math';
import 'package:flutter/material.dart';

class FireworksWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const FireworksWidget({super.key, required this.onComplete});

  @override
  State<FireworksWidget> createState() => _FireworksWidgetState();
}

class _FireworksWidgetState extends State<FireworksWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Firework> _fireworks = [];
  final Random _random = Random();

  static const _colorSets = [
    [Colors.red, Colors.orange],
    [Colors.blue, Colors.cyan],
    [Colors.green, Colors.lime],
    [Colors.yellow, Colors.amber],
    [Colors.purple, Colors.pink],
    [Colors.white, Colors.lightBlue],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    final shuffled = List<List<Color>>.from(_colorSets)..shuffle(_random);

    for (int i = 0; i < 6; i++) {
      _fireworks.add(_Firework(
        coreColor: shuffled[i][0],
        glowColor: shuffled[i][1],
        startDelay: i * 0.12,
        targetXRatio: 0.15 + _random.nextDouble() * 0.70,
        targetYRatio: 0.05 + _random.nextDouble() * 0.45,
        particleCount: 60 + _random.nextInt(30),
      ));
    }

    _controller.forward().then((_) {
      widget.onComplete();
    });
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
      builder: (context, _) {
        return CustomPaint(
          painter: _FireworksPainter(
            fireworks: _fireworks,
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _Firework {
  final Color coreColor;
  final Color glowColor;
  final double startDelay;
  final double targetXRatio;
  final double targetYRatio;
  final int particleCount;
  final List<double> particleAngles;
  final List<double> particleSpeeds;
  final List<double> particleSpeedVariants; // 内側と外側の2層

  _Firework({
    required this.coreColor,
    required this.glowColor,
    required this.startDelay,
    required this.targetXRatio,
    required this.targetYRatio,
    required this.particleCount,
  })  : particleAngles = List.generate(
            particleCount, (i) => i * 2 * pi / particleCount),
        particleSpeeds = List.generate(
            particleCount,
            (i) => 160.0 + Random().nextDouble() * 120.0), // 大きな爆発半径
        particleSpeedVariants = List.generate(
            particleCount,
            (i) => 80.0 + Random().nextDouble() * 60.0); // 内側の短い粒子
}

class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;
  final double progress;

  _FireworksPainter({required this.fireworks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      if (progress < fw.startDelay) continue;
      final localProgress =
          ((progress - fw.startDelay) / (1.0 - fw.startDelay)).clamp(0.0, 1.0);

      final targetX = size.width * fw.targetXRatio;
      final targetY = size.height * fw.targetYRatio;
      final startX = size.width * 0.5;
      final startY = size.height;

      // 打ち上げフェーズ (0~0.25)
      const launchEnd = 0.25;
      if (localProgress < launchEnd) {
        final t = localProgress / launchEnd;
        final x = startX + (targetX - startX) * t;
        final y = startY + (targetY - startY) * t;

        // 打ち上げ本体（太く明るい）
        final launchPaint = Paint()
          ..color = fw.coreColor.withAlpha(220)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(x, y),
          Offset(
            x - (targetX - startX) * 0.08,
            y - (targetY - startY) * 0.08,
          ),
          launchPaint,
        );

        // 打ち上げの光彩
        canvas.drawCircle(
          Offset(x, y),
          6.0,
          Paint()
            ..color = fw.glowColor.withAlpha(160)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        continue;
      }

      // 爆発フェーズ (0.25~1.0)
      final explodeProgress = (localProgress - launchEnd) / (1.0 - launchEnd);
      final alpha = (255 * (1.0 - explodeProgress * 0.85)).round().clamp(0, 255);

      // 爆発直後の中心フラッシュ
      if (explodeProgress < 0.2) {
        final flashAlpha = ((1.0 - explodeProgress / 0.2) * 230).round();
        canvas.drawCircle(
          Offset(targetX, targetY),
          30.0 * (1.0 - explodeProgress / 0.2) + 10,
          Paint()
            ..color = Colors.white.withAlpha(flashAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
        canvas.drawCircle(
          Offset(targetX, targetY),
          15.0 * (1.0 - explodeProgress / 0.2),
          Paint()..color = fw.glowColor.withAlpha(flashAlpha),
        );
      }

      // 外側リング（明るいグロー）
      _drawRing(canvas, fw, targetX, targetY, explodeProgress, alpha);

      // 火の粉（内側：短く太い）
      _drawParticles(canvas, fw, targetX, targetY, explodeProgress, alpha,
          speeds: fw.particleSpeedVariants,
          strokeWidth: 5.0,
          tipRadius: 5.0,
          trailLen: 0.08,
          gravity: 100.0,
          colorAlphaScale: 0.9,
          useGlow: true);

      // 火の粉（外側：長く細い）
      _drawParticles(canvas, fw, targetX, targetY, explodeProgress, alpha,
          speeds: fw.particleSpeeds,
          strokeWidth: 3.5,
          tipRadius: 4.0,
          trailLen: 0.12,
          gravity: 140.0,
          colorAlphaScale: 1.0,
          useGlow: false);
    }
  }

  void _drawRing(Canvas canvas, _Firework fw, double cx, double cy,
      double explodeProgress, int alpha) {
    if (explodeProgress > 0.6) return;
    final radius = 180.0 * explodeProgress;
    final ringAlpha = (alpha * (1.0 - explodeProgress / 0.6) * 0.5).round();
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = fw.glowColor.withAlpha(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawParticles(
    Canvas canvas,
    _Firework fw,
    double cx,
    double cy,
    double explodeProgress,
    int alpha, {
    required List<double> speeds,
    required double strokeWidth,
    required double tipRadius,
    required double trailLen,
    required double gravity,
    required double colorAlphaScale,
    required bool useGlow,
  }) {
    for (int i = 0; i < fw.particleCount; i++) {
      final angle = fw.particleAngles[i];
      final speed = speeds[i];
      final g = gravity * explodeProgress * explodeProgress;

      final px = cx + cos(angle) * speed * explodeProgress;
      final py = cy + sin(angle) * speed * explodeProgress + g;

      final trailProg = (explodeProgress - trailLen).clamp(0.0, 1.0);
      final tx = cx + cos(angle) * speed * trailProg;
      final ty = cy + sin(angle) * speed * trailProg + gravity * trailProg * trailProg;

      final particleAlpha = (alpha * colorAlphaScale).round().clamp(0, 255);

      // メイン軌跡
      canvas.drawLine(
        Offset(tx, ty),
        Offset(px, py),
        Paint()
          ..color = fw.coreColor.withAlpha(particleAlpha)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      // 光彩（グロー）
      if (useGlow) {
        canvas.drawLine(
          Offset(tx, ty),
          Offset(px, py),
          Paint()
            ..color = fw.glowColor.withAlpha((particleAlpha * 0.5).round())
            ..strokeWidth = strokeWidth * 2.5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // 先端の光点（大きく明るい）
      final tipSize = tipRadius * (1.0 - explodeProgress * 0.7);
      if (tipSize > 0.5) {
        canvas.drawCircle(
          Offset(px, py),
          tipSize,
          Paint()..color = Colors.white.withAlpha((particleAlpha * 0.9).round()),
        );
        canvas.drawCircle(
          Offset(px, py),
          tipSize * 2.0,
          Paint()
            ..color = fw.glowColor.withAlpha((particleAlpha * 0.4).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.progress != progress;
}
