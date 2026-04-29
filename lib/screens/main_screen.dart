import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
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
  List<String> _fireworksPlateNames = [];
  late CollectionProvider _provider;
  bool _listenerRegistered = false;

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
      setState(() {
        _showFireworks = true;
        _fireworksPlateNames =
            List<String>.from(_provider.lastCompletedPlateNames);
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
              // 左: 日本地図（暗転・花火は地図エリア内のみ）
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
                    // 暗転オーバーレイ（かすかに地図が見える程度）
                    AnimatedOpacity(
                      opacity: _showFireworks ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: const IgnorePointer(
                        child: ColoredBox(
                          color: Color(0xD9000000), // 黒 85% 不透明
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
                    // 花火（地図エリア内のみ）
                    if (_showFireworks)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FireworksWidget(
                            plateNames: _fireworksPlateNames,
                            onComplete: () {
                              // 全花火の描画完了後に暗転を解除
                              if (mounted) {
                                setState(() => _showFireworks = false);
                              }
                            },
                          ),
                        ),
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
                child: SelectionPanelWidget(key: _selectionKey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
