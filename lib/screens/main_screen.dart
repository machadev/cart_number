import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/japan_map_widget.dart';
import '../widgets/selection_panel_widget.dart';
import '../widgets/fireworks_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<SelectionPanelWidgetState> _selectionKey =
      GlobalKey<SelectionPanelWidgetState>();

  bool _showFireworks = false;
  bool _showNationalConquest = false;
  List<String> _fireworksPlateNames = [];
  late CollectionProvider _provider;
  bool _listenerRegistered = false;
  Uint8List? _explosionBytes;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/sounds/explosion.mp3').then((data) {
      if (mounted) _explosionBytes = data.buffer.asUint8List();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerRegistered) {
      _provider = context.read<CollectionProvider>();
      _provider.addListener(_onCollectionChanged);
      _listenerRegistered = true;
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onCollectionChanged);
    super.dispose();
  }

  void _onCollectionChanged() {
    if (_provider.lastCompletedPrefecture != null && !_showFireworks) {
      final prefName = _provider.lastCompletedPrefecture!;
      setState(() {
        _showFireworks = true;
        _fireworksPlateNames =
            List<String>.from(_provider.lastCompletedPlateNames);
      });
      // 完成した都道府県へスクロール
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectionKey.currentState?.scrollToPrefecture(prefName);
      });
      _provider.clearLastCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 左: 日本地図
              Flexible(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      color: const Color(0xFFE3F2FD),
                      child: JapanMapWidget(
                        blinkEnabled: _showFireworks,
                        onPrefectureTap: (prefName) {
                          _selectionKey.currentState
                              ?.scrollToPrefecture(prefName);
                        },
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      bottom: 16,
                      child: _AuthButton(),
                    ),
                  ],
                ),
              ),
              // 区切り線
              Container(
                width: 1,
                color: Colors.grey.shade300,
              ),
              // 右: ナンバー選択
              Flexible(
                flex: 2,
                child: SelectionPanelWidget(
                  key: _selectionKey,
                ),
              ),
            ],
          ),
          // 暗転オーバーレイ（画面全体）
          AnimatedOpacity(
            opacity: _showFireworks ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: const IgnorePointer(
              child: ColoredBox(
                color: Color(0xD9000000),
                child: SizedBox.expand(),
              ),
            ),
          ),
          // 花火（画面全体）
          if (_showFireworks)
            Positioned.fill(
              child: IgnorePointer(
                child: FireworksWidget(
                  plateNames: _fireworksPlateNames,
                  explosionBytes: _explosionBytes,
                  onComplete: () {
                    if (!mounted) return;
                    final allComplete =
                        _provider.totalPlates > 0 &&
                        _provider.totalCollected == _provider.totalPlates;
                    setState(() {
                      _showFireworks = false;
                    });
                    if (allComplete) {
                      Future.delayed(
                        const Duration(milliseconds: 500),
                        () {
                          if (mounted) {
                            setState(() => _showNationalConquest = true);
                          }
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          if (_showNationalConquest)
            _NationalConquestOverlay(
              onDismiss: () => setState(() => _showNationalConquest = false),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 認証ボタン（地図右下）
// ─────────────────────────────────────────
class _AuthButton extends StatelessWidget {
  const _AuthButton();

  static const _green = Color(0xFF43A047);
  static const _grey = Color(0xFF90A4AE);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (auth.isLoggedIn) {
      final user = auth.user!;
      // ──── ログイン中：緑枠アバター＋右下に緑バッジ ────
      return Tooltip(
        message: '${user.displayName ?? user.email ?? 'ログイン中'}\n（タップでメニュー）',
        child: GestureDetector(
          onTap: () =>
              _showUserMenu(context, auth, user.displayName, user.email),
          child: Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: ClipOval(
                  child: user.photoURL != null
                      ? Image.network(user.photoURL!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.blueGrey,
                          alignment: Alignment.center,
                          child: Text(
                            (user.displayName ?? user.email ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              // 右下の緑オンラインバッジ
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ──── 未ログイン：グレー人物アイコン＋右下に×バッジ ────
    return Tooltip(
      message: 'Googleでログイン',
      child: GestureDetector(
        onTap: auth.signInWithGoogle,
        child: Stack(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _grey, width: 2),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: const Icon(Icons.person_outline, size: 28, color: _grey),
            ),
            // 右下の×バッジ
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.close, size: 9, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserMenu(
    BuildContext context,
    AuthProvider auth,
    String? name,
    String? email,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アカウント'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null)
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (email != null)
              Text(email, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}

class _NationalConquestOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const _NationalConquestOverlay({required this.onDismiss});

  @override
  State<_NationalConquestOverlay> createState() =>
      _NationalConquestOverlayState();
}

class _NationalConquestOverlayState extends State<_NationalConquestOverlay>
    with SingleTickerProviderStateMixin {
  static const _fullText = '全国制覇';
  static const _charInterval = Duration(milliseconds: 500);

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    for (int i = 0; i < _fullText.length; i++) {
      Future.delayed(_charInterval * (i + 1), () {
        if (mounted) setState(() => _visibleCount = i + 1);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _fullText.substring(0, _visibleCount);
    final invisible = _fullText.substring(_visibleCount);

    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            color: Color.fromARGB(
              (0xCC * _fadeAnim.value).round(),
              0,
              0,
              0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFF0A0),
                        Color(0xFFFFD700),
                        Color(0xFFFF8C00),
                        Color(0xFFFFD700),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: Color(0xFFFF8C00),
                              blurRadius: 24,
                              offset: Offset(0, 4),
                            ),
                            Shadow(
                              color: Color(0xFFFFD700),
                              blurRadius: 48,
                            ),
                          ],
                        ),
                        children: [
                          TextSpan(
                            text: visible,
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: invisible,
                            style: const TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _visibleCount >= _fullText.length ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: const Text(
                      '全ての都道府県を制覇しました！',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedOpacity(
                    opacity: _visibleCount >= _fullText.length ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: const Text(
                      'タップして閉じる',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
