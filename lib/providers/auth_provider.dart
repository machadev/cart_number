import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  static const _allowedDomain = 'monstar-lab.com';

  Future<void> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    _errorMessage = null;
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        final email = result.user?.email ?? '';
        if (!email.endsWith('@$_allowedDomain')) {
          await _auth.signOut();
          _errorMessage = '$_allowedDomain のアカウントでログインしてください。';
        }
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      _errorMessage = 'ログインに失敗しました。もう一度お試しください。';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
