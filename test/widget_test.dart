import 'package:flutter_test/flutter_test.dart';
import 'package:cart_number/data/japan_data.dart';

void main() {
  test('Japan prefecture data has 47 entries', () {
    expect(japanPrefectures.length, 47);
  });

  test('Fujisan exists in both Shizuoka and Yamanashi', () {
    final shizuoka =
        japanPrefectures.firstWhere((p) => p.name == '静岡');
    final yamanashi =
        japanPrefectures.firstWhere((p) => p.name == '山梨');
    expect(shizuoka.plates.any((p) => p.name == '富士山'), isTrue);
    expect(yamanashi.plates.any((p) => p.name == '富士山'), isTrue);
  });
}
