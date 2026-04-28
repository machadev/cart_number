import 'dart:math';
import 'package:flutter/material.dart';

class FireworksWidget extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> plateNames;

  const FireworksWidget({
    super.key,
    required this.onComplete,
    this.plateNames = const [],
  });

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

    // ── タイミング設計（ms） ──
    const regularIntervalMs = 500;  // 通常花火の間隔
    const plateStartMs = 2000;      // プレート花火の開始
    const plateIntervalMs = 1000;   // プレート花火の間隔
    const tailMs = 2800;            // 最後の花火が消えるまでの余裕

    final numPlates = widget.plateNames.length;
    final totalMs = (plateStartMs + numPlates * plateIntervalMs + tailMs)
        .clamp(5000, 30000);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    final shuffled = List<List<Color>>.from(_colorSets)..shuffle(_random);

    // ── 最初の3発：通常花火 ──
    for (int i = 0; i < 3; i++) {
      final delayMs = i * regularIntervalMs;
      _fireworks.add(_Firework(
        coreColor: shuffled[i][0],
        glowColor: shuffled[i][1],
        startDelay: delayMs / totalMs,
        launchXRatio: 0.5,
        targetXRatio: 0.10 + _random.nextDouble() * 0.80,
        targetYRatio: 0.06 + _random.nextDouble() * 0.46,
        particleCount: 60 + _random.nextInt(30),
        isTextFirework: false,
        plateName: '',
      ));
    }

    // ── 収集地名ごとにナンバープレート花火 ──
    for (int i = 0; i < numPlates; i++) {
      final delayMs = plateStartMs + i * plateIntervalMs;
      final targetX = 0.5 + (_random.nextDouble() - 0.5) * 0.30;
      _fireworks.add(_Firework(
        coreColor: const Color(0xFF006400),
        glowColor: const Color(0xFF00C853),
        startDelay: delayMs / totalMs,
        launchXRatio: 0.5,
        targetXRatio: targetX.clamp(0.15, 0.85),
        targetYRatio: 0.15 + _random.nextDouble() * 0.28,
        particleCount: 80,
        isTextFirework: true,
        plateName: widget.plateNames[i],
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
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
  final double launchXRatio;
  final double targetXRatio;
  final double targetYRatio;
  final int particleCount;
  final bool isTextFirework;
  final String plateName;
  final List<double> particleAngles;
  final List<double> particleSpeeds;
  final List<double> particleSpeedVariants;

  _Firework({
    required this.coreColor,
    required this.glowColor,
    required this.startDelay,
    required this.launchXRatio,
    required this.targetXRatio,
    required this.targetYRatio,
    required this.particleCount,
    required this.isTextFirework,
    required this.plateName,
  })  : particleAngles = List.generate(
            particleCount, (i) => i * 2 * pi / particleCount),
        particleSpeeds = List.generate(
            particleCount,
            (i) => 160.0 + Random().nextDouble() * 120.0),
        particleSpeedVariants = List.generate(
            particleCount,
            (i) => 80.0 + Random().nextDouble() * 60.0);
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
      final startX = size.width * fw.launchXRatio;
      final startY = size.height;

      // 打ち上げフェーズ (0~0.25)
      const launchEnd = 0.25;
      if (localProgress < launchEnd) {
        final t = localProgress / launchEnd;
        final x = startX + (targetX - startX) * t;
        final y = startY + (targetY - startY) * t;
        canvas.drawLine(
          Offset(x, y),
          Offset(x - (targetX - startX) * 0.08, y - (targetY - startY) * 0.08),
          Paint()
            ..color = fw.coreColor.withAlpha(220)
            ..strokeWidth = fw.isTextFirework ? 7.0 : 5.0
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(x, y),
          fw.isTextFirework ? 9.0 : 6.0,
          Paint()
            ..color = fw.glowColor.withAlpha(160)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        continue;
      }

      // 爆発フェーズ (0.25~1.0)
      final explodeProgress = (localProgress - launchEnd) / (1.0 - launchEnd);
      final alpha =
          (255 * (1.0 - explodeProgress * 0.85)).round().clamp(0, 255);

      // 爆発フラッシュ
      if (explodeProgress < 0.2) {
        final flashAlpha = ((1.0 - explodeProgress / 0.2) * 230).round();
        canvas.drawCircle(Offset(targetX, targetY),
            30.0 * (1.0 - explodeProgress / 0.2) + 10,
            Paint()
              ..color = Colors.white.withAlpha(flashAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
        canvas.drawCircle(Offset(targetX, targetY),
            15.0 * (1.0 - explodeProgress / 0.2),
            Paint()..color = fw.glowColor.withAlpha(flashAlpha));
      }

      if (fw.isTextFirework) {
        _drawPlateSparks(canvas, fw, targetX, targetY, explodeProgress, alpha);
        _drawLicensePlate(canvas, fw, targetX, targetY, explodeProgress, size);
      } else {
        _drawRing(canvas, fw, targetX, targetY, explodeProgress, alpha);
        _drawParticles(canvas, fw, targetX, targetY, explodeProgress, alpha,
            speeds: fw.particleSpeedVariants,
            strokeWidth: 5.0, tipRadius: 5.0,
            trailLen: 0.08, gravity: 100.0,
            colorAlphaScale: 0.9, useGlow: true);
        _drawParticles(canvas, fw, targetX, targetY, explodeProgress, alpha,
            speeds: fw.particleSpeeds,
            strokeWidth: 3.5, tipRadius: 4.0,
            trailLen: 0.12, gravity: 140.0,
            colorAlphaScale: 1.0, useGlow: false);
      }
    }
  }

  void _drawRing(Canvas canvas, _Firework fw, double cx, double cy,
      double explodeProgress, int alpha) {
    if (explodeProgress > 0.6) return;
    canvas.drawCircle(
      Offset(cx, cy),
      180.0 * explodeProgress,
      Paint()
        ..color = fw.glowColor
            .withAlpha((alpha * (1.0 - explodeProgress / 0.6) * 0.5).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawParticles(Canvas canvas, _Firework fw, double cx, double cy,
      double explodeProgress, int alpha,
      {required List<double> speeds,
      required double strokeWidth,
      required double tipRadius,
      required double trailLen,
      required double gravity,
      required double colorAlphaScale,
      required bool useGlow}) {
    for (int i = 0; i < fw.particleCount; i++) {
      final angle = fw.particleAngles[i];
      final speed = speeds[i];
      final g = gravity * explodeProgress * explodeProgress;
      final px = cx + cos(angle) * speed * explodeProgress;
      final py = cy + sin(angle) * speed * explodeProgress + g;
      final trailProg = (explodeProgress - trailLen).clamp(0.0, 1.0);
      final tx = cx + cos(angle) * speed * trailProg;
      final ty = cy + sin(angle) * speed * trailProg + gravity * trailProg * trailProg;
      final pa = (alpha * colorAlphaScale).round().clamp(0, 255);
      canvas.drawLine(Offset(tx, ty), Offset(px, py),
          Paint()
            ..color = fw.coreColor.withAlpha(pa)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
      if (useGlow) {
        canvas.drawLine(Offset(tx, ty), Offset(px, py),
            Paint()
              ..color = fw.glowColor.withAlpha((pa * 0.5).round())
              ..strokeWidth = strokeWidth * 2.5
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
      final tipSize = tipRadius * (1.0 - explodeProgress * 0.7);
      if (tipSize > 0.5) {
        canvas.drawCircle(Offset(px, py), tipSize,
            Paint()..color = Colors.white.withAlpha((pa * 0.9).round()));
        canvas.drawCircle(Offset(px, py), tipSize * 2.0,
            Paint()
              ..color = fw.glowColor.withAlpha((pa * 0.4).round())
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    }
  }

  void _drawPlateSparks(Canvas canvas, _Firework fw, double cx, double cy,
      double explodeProgress, int alpha) {
    for (int i = 0; i < fw.particleCount; i++) {
      final angle = fw.particleAngles[i];
      final speed = fw.particleSpeeds[i] * 1.1;
      final g = 130.0 * explodeProgress * explodeProgress;
      final px = cx + cos(angle) * speed * explodeProgress;
      final py = cy + sin(angle) * speed * explodeProgress + g;
      final trailProg = (explodeProgress - 0.10).clamp(0.0, 1.0);
      final tx = cx + cos(angle) * speed * trailProg;
      final ty = cy + sin(angle) * speed * trailProg + 130.0 * trailProg * trailProg;
      final a = alpha.clamp(0, 255);
      canvas.drawLine(Offset(tx, ty), Offset(px, py),
          Paint()
            ..color = Colors.amber.withAlpha(a)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round);
      final tipSize = 4.0 * (1.0 - explodeProgress * 0.7);
      if (tipSize > 0.5) {
        canvas.drawCircle(Offset(px, py), tipSize,
            Paint()..color = Colors.white.withAlpha(a));
        canvas.drawCircle(Offset(px, py), tipSize * 2.0,
            Paint()
              ..color = Colors.orange.withAlpha((a * 0.4).round())
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    }
  }

  void _drawLicensePlate(Canvas canvas, _Firework fw, double cx, double cy,
      double explodeProgress, Size size) {
    if (explodeProgress < 0.05 || explodeProgress > 0.92) return;

    double fadeAlpha;
    if (explodeProgress < 0.18) {
      fadeAlpha = (explodeProgress - 0.05) / 0.13;
    } else if (explodeProgress < 0.62) {
      fadeAlpha = 1.0;
    } else {
      fadeAlpha = 1.0 - (explodeProgress - 0.62) / 0.30;
    }
    fadeAlpha = fadeAlpha.clamp(0.0, 1.0);
    if (fadeAlpha <= 0) return;

    final int a = (fadeAlpha * 255).round();

    final plateW = (size.width * 0.32).clamp(180.0, 300.0);
    final plateH = plateW * (165.0 / 330.0);
    final left = cx - plateW / 2;
    final top = cy - plateH / 2;
    final plateRect = Rect.fromLTWH(left, top, plateW, plateH);
    const cornerR = Radius.circular(8);

    const darkGreen = Color(0xFF006400);
    const brightGreen = Color(0xFF00C853);
    final dotColor = darkGreen.withAlpha(a);
    final dotGlow = brightGreen.withAlpha((a * 0.8).round());
    const double dotR = 2.2;
    const double dotSpacing = 7.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(plateRect.inflate(14), const Radius.circular(16)),
      Paint()
        ..color = brightGreen.withAlpha((a * 0.25).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    _drawDottedRRect(canvas, RRect.fromRectAndRadius(plateRect, cornerR),
        dotR, dotSpacing, Paint()..color = dotColor);
    _drawDottedRRect(
        canvas, RRect.fromRectAndRadius(plateRect.deflate(5), cornerR),
        dotR * 0.7, dotSpacing * 1.2, Paint()..color = dotGlow);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = dotColor;
    final strokePaintGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = dotGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final pad = plateW * 0.06;
    final innerLeft = left + pad;
    final innerWidth = plateW - pad * 2;

    final topText = '・${fw.plateName.isNotEmpty ? fw.plateName : '地名'}599・';
    _drawStrokeText(canvas, topText, plateH * 0.28,
        left: innerLeft, top: top + plateH * 0.06, width: innerWidth,
        align: TextAlign.center,
        mainPaint: strokePaint, glowPaint: strokePaintGlow);

    const kanaText = 'さ';
    const numText = '20-27';

    _drawStrokeText(canvas, kanaText, plateH * 0.28,
        left: innerLeft, top: top + plateH * 0.44, width: innerWidth * 0.3,
        align: TextAlign.left,
        mainPaint: strokePaint, glowPaint: strokePaintGlow);

    _drawStrokeText(canvas, numText, plateH * 0.50,
        left: innerLeft + innerWidth * 0.25, top: top + plateH * 0.38,
        width: innerWidth * 0.75,
        align: TextAlign.center,
        mainPaint: strokePaint, glowPaint: strokePaintGlow);
  }

  void _drawDottedRRect(Canvas canvas, RRect rrect, double dotRadius,
      double spacing, Paint paint) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final tangent = metric.getTangentForOffset(dist);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dotRadius, paint);
        }
        dist += spacing;
      }
    }
  }

  void _drawStrokeText(Canvas canvas, String text, double fontSize,
      {required double left, required double top, required double width,
      required TextAlign align, required Paint mainPaint, required Paint glowPaint}) {
    void draw(Paint p) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold,
                foreground: p, height: 1.0)),
        textAlign: align,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final dx = align == TextAlign.center
          ? left + (width - tp.width) / 2
          : align == TextAlign.right
              ? left + width - tp.width
              : left;
      tp.paint(canvas, Offset(dx, top));
    }
    draw(glowPaint);
    draw(mainPaint);
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.progress != progress;
}
