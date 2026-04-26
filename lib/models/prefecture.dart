import 'package:flutter/material.dart';

enum Region {
  hokkaido,
  tohoku,
  kanto,
  chubu,
  kinki,
  chugoku,
  shikoku,
  kyushuOkinawa,
}

extension RegionExtension on Region {
  String get displayName {
    switch (this) {
      case Region.hokkaido:
        return '北海道';
      case Region.tohoku:
        return '東北';
      case Region.kanto:
        return '関東';
      case Region.chubu:
        return '中部';
      case Region.kinki:
        return '近畿';
      case Region.chugoku:
        return '中国';
      case Region.shikoku:
        return '四国';
      case Region.kyushuOkinawa:
        return '九州・沖縄';
    }
  }

  Color get baseColor {
    switch (this) {
      case Region.hokkaido:
        return const Color(0xFF43A047);
      case Region.tohoku:
        return const Color(0xFF1E88E5);
      case Region.kanto:
        return const Color(0xFFE53935);
      case Region.chubu:
        return const Color(0xFF8E24AA);
      case Region.kinki:
        return const Color(0xFFFB8C00);
      case Region.chugoku:
        return const Color(0xFF00897B);
      case Region.shikoku:
        return const Color(0xFFD81B60);
      case Region.kyushuOkinawa:
        return const Color(0xFF3949AB);
    }
  }
}

class NumberPlate {
  final String name;
  bool collected;

  NumberPlate({required this.name, this.collected = false});

  Map<String, dynamic> toJson() => {'name': name, 'collected': collected};

  factory NumberPlate.fromJson(Map<String, dynamic> json) {
    return NumberPlate(
      name: json['name'] as String,
      collected: (json['collected'] as bool?) ?? false,
    );
  }
}

class Prefecture {
  final String name;
  final Region region;
  final List<NumberPlate> plates;
  // Geographic polygon [[lon, lat], ...]
  final List<List<double>> polygon;

  Prefecture({
    required this.name,
    required this.region,
    required this.plates,
    required this.polygon,
  });

  int get totalPlates => plates.length;
  int get collectedPlates => plates.where((p) => p.collected).length;
  double get collectionRate =>
      totalPlates > 0 ? collectedPlates / totalPlates : 0.0;
  bool get isComplete => totalPlates > 0 && collectedPlates == totalPlates;

  Color get fillColor {
    final base = region.baseColor;
    if (collectedPlates == 0) {
      return base.withAlpha(40);
    }
    final alpha = (40 + (collectionRate * 200)).round().clamp(40, 240);
    return base.withAlpha(alpha);
  }
}
