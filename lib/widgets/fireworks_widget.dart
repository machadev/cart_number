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

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // カラーをシャッフル
    final shuffled = List<Color>.from(_colors)..shuffle(_random);

    // 5発の花火を設定
    for (int i = 0; i < 5; i++) {
      _fireworks.add(_Firework(
        color: shuffled[i],
        startDelay: i * 0.15,
        targetXRatio: 0.3 + _random.nextDouble() * 0.4,
        targetYRatio: 0.1 + _random.nextDouble() * 0.4,
        particleCount: 20 + _random.nextInt(16),
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
  final Color color;
  final double startDelay;
  final double targetXRatio;
  final double targetYRatio;
  final int particleCount;
  final List<double> particleAngles;
  final List<double> particleSpeeds;

  _Firework({
    required this.color,
    required this.startDelay,
    required this.targetXRatio,
    required this.targetYRatio,
    required this.particleCount,
  })  : particleAngles = List.generate(
            particleCount, (i) => i * 2 * pi / particleCount),
        particleSpeeds = List.generate(
            particleCount, (i) => 60.0 + Random().nextDouble() * 60.0);
}

class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;
  final double progress;

  _FireworksPainter({required this.fireworks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      // このFireworkのローカル進行度
      if (progress < fw.startDelay) continue;
      final localProgress =
          ((progress - fw.startDelay) / (1.0 - fw.startDelay)).clamp(0.0, 1.0);

      final targetX = size.width * fw.targetXRatio;
      final targetY = size.height * fw.targetYRatio;
      final startX = size.width * 0.5;
      final startY = size.height;

      // 打ち上げフェーズ (0.0 ~ 0.3)
      const launchEnd = 0.3;
      if (localProgress < launchEnd) {
        final t = localProgress / launchEnd;
        final x = startX + (targetX - startX) * t;
        final y = startY + (targetY - startY) * t;
        final paint = Paint()
          ..color = fw.color.withAlpha(200)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(x, y),
          Offset(
            x - (targetX - startX) * 0.05,
            y - (targetY - startY) * 0.05,
          ),
          paint,
        );
        return;
      }

      // 爆発フェーズ (0.3 ~ 1.0)
      final explodeProgress = (localProgress - launchEnd) / (1.0 - launchEnd);
      final alpha =
          (255 * (1.0 - explodeProgress)).round().clamp(0, 255);

      for (int i = 0; i < fw.particleCount; i++) {
        final angle = fw.particleAngles[i];
        final speed = fw.particleSpeeds[i];
        // 重力効果
        final gravity = 80.0 * explodeProgress * explodeProgress;
        final px = targetX + cos(angle) * speed * explodeProgress;
        final py = targetY + sin(angle) * speed * explodeProgress + gravity;

        final paint = Paint()
          ..color = fw.color.withAlpha(alpha)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

        // 粒子の軌跡
        final trailX =
            targetX + cos(angle) * speed * (explodeProgress - 0.05).clamp(0, 1);
        final trailY =
            targetY + sin(angle) * speed * (explodeProgress - 0.05).clamp(0, 1) +
                gravity * 0.8;

        canvas.drawLine(Offset(trailX, trailY), Offset(px, py), paint);

        // 火花の先端
        canvas.drawCircle(
          Offset(px, py),
          2.5 * (1.0 - explodeProgress),
          Paint()..color = Colors.white.withAlpha((alpha * 0.7).round()),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.progress != progress;
}
