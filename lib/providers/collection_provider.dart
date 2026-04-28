import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/japan_data.dart';
import '../models/prefecture.dart';

class CollectionProvider extends ChangeNotifier {
  late List<Prefecture> _prefectures;
  // 最後に完成した都道府県名（花火エフェクト用）
  String? _lastCompletedPrefecture;
  // 完成した都道府県の全収集地名リスト（花火用）
  List<String> _lastCompletedPlateNames = [];

  List<Prefecture> get prefectures => _prefectures;
  String? get lastCompletedPrefecture => _lastCompletedPrefecture;
  List<String> get lastCompletedPlateNames =>
      List.unmodifiable(_lastCompletedPlateNames);

  int get totalPlates =>
      _prefectures.fold(0, (sum, p) => sum + p.totalPlates);
  int get totalCollected =>
      _prefectures.fold(0, (sum, p) => sum + p.collectedPlates);
  double get globalRate =>
      totalPlates > 0 ? totalCollected / totalPlates : 0.0;

  Prefecture? getPrefecture(String name) {
    try {
      return _prefectures.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  List<Prefecture> getPrefecturesByRegion(Region region) =>
      _prefectures.where((p) => p.region == region).toList();

  Future<void> loadData() async {
    _prefectures = japanPrefectures;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('collection_data');
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        for (final pref in _prefectures) {
          final prefData = data[pref.name] as List<dynamic>?;
          if (prefData != null) {
            for (final plate in pref.plates) {
              final found = prefData.firstWhere(
                (p) => p['name'] == plate.name,
                orElse: () => null,
              );
              if (found != null) {
                plate.collected = found['collected'] as bool? ?? false;
              }
            }
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final pref in _prefectures) {
        data[pref.name] =
            pref.plates.map((p) => p.toJson()).toList();
      }
      await prefs.setString('collection_data', jsonEncode(data));
    } catch (_) {}
  }

  void togglePlate(String prefName, String plateName) {
    final pref = getPrefecture(prefName);
    if (pref == null) return;

    final plate = pref.plates.firstWhere(
      (p) => p.name == plateName,
      orElse: () => throw Exception('plate not found'),
    );
    final wasComplete = pref.isComplete;
    plate.collected = !plate.collected;

    // 富士山の特殊処理
    if (plateName == '富士山') {
      _syncFujisan(plate.collected);
    }

    // 完成チェック
    if (!wasComplete && pref.isComplete) {
      _lastCompletedPrefecture = prefName;
      // 完成した都道府県の全収集地名を記録
      _lastCompletedPlateNames =
          pref.plates.where((p) => p.collected).map((p) => p.name).toList();
    } else {
      _lastCompletedPrefecture = null;
      _lastCompletedPlateNames = [];
    }

    _saveData();
    notifyListeners();
  }

  void _syncFujisan(bool collected) {
    // 静岡・山梨の富士山を同期
    for (final prefName in ['静岡', '山梨']) {
      final pref = getPrefecture(prefName);
      if (pref == null) continue;
      try {
        final plate = pref.plates.firstWhere((p) => p.name == '富士山');
        plate.collected = collected;
      } catch (_) {}
    }
  }

  void clearLastCompleted() {
    _lastCompletedPrefecture = null;
  }
}
