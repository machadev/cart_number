import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/japan_data.dart';
import '../models/prefecture.dart';

class CollectionProvider extends ChangeNotifier {
  late List<Prefecture> _prefectures;
  String? _currentUid;
  bool _initialized = false;
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

  CollectionProvider() {
    _prefectures = japanPrefectures;
    _resetAll();
  }

  Prefecture? getPrefecture(String name) {
    try {
      return _prefectures.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  List<Prefecture> getPrefecturesByRegion(Region region) =>
      _prefectures.where((p) => p.region == region).toList();

  // AuthProvider の変化を受け取る（ProxyProvider から呼ばれる）
  void onAuthChanged(User? user) {
    final newUid = user?.uid;
    if (_initialized && _currentUid == newUid) return;
    _initialized = true;
    _loadForUser(user);
  }

  void _resetAll() {
    for (final pref in _prefectures) {
      for (final plate in pref.plates) {
        plate.collected = false;
      }
    }
  }

  Future<void> _loadForUser(User? user) async {
    _resetAll();
    _lastCompletedPrefecture = null;
    _lastCompletedPlateNames = [];

    if (user != null) {
      _currentUid = user.uid;
      await _loadFromFirestore(user.uid);
    } else {
      _currentUid = null;
      // 未ログイン: クリア状態のまま・保存なし
    }
    notifyListeners();
  }

  Future<void> _loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('cart_number')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        for (final pref in _prefectures) {
          final prefData = data[pref.name] as Map<String, dynamic>?;
          if (prefData != null) {
            for (final plate in pref.plates) {
              plate.collected = prefData[plate.name] as bool? ?? false;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore load error: $e');
    }
  }

  Future<void> _saveToFirestore() async {
    if (_currentUid == null) return;
    try {
      final data = <String, dynamic>{};
      for (final pref in _prefectures) {
        data[pref.name] = {
          for (final p in pref.plates) p.name: p.collected,
        };
      }
      await FirebaseFirestore.instance
          .collection('cart_number')
          .doc(_currentUid)
          .set(data);
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
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

    _saveToFirestore();
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

  Future<void> clearAll() async {
    _resetAll();
    _lastCompletedPrefecture = null;
    _lastCompletedPlateNames = [];
    await _saveToFirestore();
    notifyListeners();
  }
}
