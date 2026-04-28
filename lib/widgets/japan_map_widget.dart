import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prefecture.dart';
import '../providers/collection_provider.dart';

// 地図の地理的範囲
const _lonMin = 129.0;
const _lonMax = 146.5;
const _latMin = 30.0;
const _latMax = 46.0;

// 沖縄インセットの地理的範囲
const _okinawaLonMin = 122.5;
const _okinawaLonMax = 131.5;
const _okinawaLatMin = 23.5;
const _okinawaLatMax = 27.5;

class JapanMapWidget extends StatefulWidget {
  final void Function(String prefectureName)? onPrefectureTap;
  final bool blinkEnabled;

  const JapanMapWidget({
    super.key,
    this.onPrefectureTap,
    this.blinkEnabled = true,
  });

  @override
  State<JapanMapWidget> createState() => _JapanMapWidgetState();
}

class _JapanMapWidgetState extends State<JapanMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(JapanMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinkEnabled == oldWidget.blinkEnabled) return;
    if (widget.blinkEnabled) {
      _blinkController.repeat(reverse: true);
    } else {
      _blinkController.stop();
      _blinkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionProvider>(
      builder: (context, provider, _) {
        return AnimatedBuilder(
          animation: _blinkController,
          builder: (context, _) {
            return GestureDetector(
              onTapDown: (details) => _handleTap(
                details.localPosition,
                provider,
                context,
              ),
              child: CustomPaint(
                painter: _JapanMapPainter(
                  prefectures: provider.prefectures,
                  blinkValue: _blinkController.value,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        );
      },
    );
  }

  void _handleTap(
    Offset pos,
    CollectionProvider provider,
    BuildContext context,
  ) {
    final size = context.size;
    if (size == null) return;

    // 沖縄インセットのチェック
    final insetRect = _okinawaInsetRect(size);
    if (insetRect.contains(pos)) {
      final okinawa = provider.getPrefecture('沖縄');
      if (okinawa != null) {
        widget.onPrefectureTap?.call('沖縄');
      }
      return;
    }

    for (final pref in provider.prefectures) {
      if (pref.name == '沖縄') continue;
      for (final ring in pref.polygons) {
        final screenPoly =
            ring.map((p) => _geoToScreen(p[0], p[1], size)).toList();
        if (_pointInPolygon(pos, screenPoly)) {
          widget.onPrefectureTap?.call(pref.name);
          return;
        }
      }
    }
  }
}

Rect _okinawaInsetRect(Size size) {
  const insetW = 130.0;
  const insetH = 60.0;
  const margin = 8.0;
  return Rect.fromLTWH(margin, size.height - insetH - margin, insetW, insetH);
}

Offset _geoToScreen(double lon, double lat, Size size) {
  final x = (lon - _lonMin) / (_lonMax - _lonMin) * size.width;
  final y = (_latMax - lat) / (_latMax - _latMin) * size.height;
  return Offset(x, y);
}

Offset _okinawaGeoToScreen(double lon, double lat, Rect inset) {
  final x = inset.left +
      (lon - _okinawaLonMin) /
          (_okinawaLonMax - _okinawaLonMin) *
          inset.width;
  final y = inset.top +
      (_okinawaLatMax - lat) /
          (_okinawaLatMax - _okinawaLatMin) *
          inset.height;
  return Offset(x, y);
}

bool _pointInPolygon(Offset point, List<Offset> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].dx, yi = polygon[i].dy;
    final xj = polygon[j].dx, yj = polygon[j].dy;
    if (((yi > point.dy) != (yj > point.dy)) &&
        (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

class _JapanMapPainter extends CustomPainter {
  final List<Prefecture> prefectures;
  final double blinkValue;

  _JapanMapPainter({
    required this.prefectures,
    required this.blinkValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE3F2FD),
    );

    final insetRect = _okinawaInsetRect(size);

    // 都道府県を描画
    for (final pref in prefectures) {
      if (pref.name == '沖縄') {
        _drawOkinawa(canvas, pref, insetRect);
        continue;
      }
      _drawPrefecture(canvas, pref, size);
    }

    // 沖縄インセットの枠
    canvas.drawRect(
      insetRect,
      Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 沖縄ラベル（非表示）
    // const textStyle = TextStyle(fontSize: 8, color: Colors.black54);
    // final tp = TextPainter(
    //   text: const TextSpan(text: '沖縄', style: textStyle),
    //   textDirection: TextDirection.ltr,
    // )..layout();
    // tp.paint(
    //   canvas,
    //   Offset(insetRect.left + 2, insetRect.top + 2),
    // );
  }

  void _drawPrefecture(Canvas canvas, Prefecture pref, Size size) {
    if (pref.polygons.isEmpty) return;

    Color fillColor = pref.fillColor;
    if (pref.isComplete) {
      final alpha = (40 + blinkValue * 215).round();
      fillColor = pref.region.baseColor.withAlpha(alpha);
    }
    final borderPaint = Paint()
      ..color = pref.region.baseColor.withAlpha(180)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    List<Offset>? largestRing;
    for (final ring in pref.polygons) {
      final points =
          ring.map((p) => _geoToScreen(p[0], p[1], size)).toList();
      if (points.length < 3) continue;

      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      canvas.drawPath(path, Paint()..color = fillColor);
      _drawDottedPath(canvas, path, borderPaint);

      if (largestRing == null || points.length > largestRing.length) {
        largestRing = points;
      }
    }
    // if (largestRing != null) _drawLabel(canvas, pref.name, largestRing);
  }

  void _drawOkinawa(Canvas canvas, Prefecture pref, Rect inset) {
    if (pref.polygons.isEmpty) return;

    Color fillColor = pref.fillColor;
    if (pref.isComplete) {
      final alpha = (40 + blinkValue * 215).round();
      fillColor = pref.region.baseColor.withAlpha(alpha);
    }
    final borderPaint = Paint()
      ..color = pref.region.baseColor.withAlpha(180)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final ring in pref.polygons) {
      final points =
          ring.map((p) => _okinawaGeoToScreen(p[0], p[1], inset)).toList();
      if (points.length < 3) continue;

      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      canvas.drawPath(path, Paint()..color = fillColor);
      _drawDottedPath(canvas, path, borderPaint);
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    const dotLen = 3.0;
    const gapLen = 4.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0.0;
      while (dist < metric.length) {
        final end = min(dist + dotLen, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dotLen + gapLen;
      }
    }
  }

  void _drawLabel(Canvas canvas, String name, List<Offset> points) {
    if (points.isEmpty) return;
    double cx = 0, cy = 0;
    for (final p in points) {
      cx += p.dx;
      cy += p.dy;
    }
    cx /= points.length;
    cy /= points.length;

    final fontSize = name.length <= 2 ? 7.0 : 6.5;
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_JapanMapPainter old) =>
      old.blinkValue != blinkValue ||
      old.prefectures != prefectures;
}
