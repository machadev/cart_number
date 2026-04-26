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

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionProvider>(
      builder: (context, provider, _) {
        // 完成チェック
        if (provider.lastCompletedPrefecture != null && !_showFireworks) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _showFireworks = true);
            provider.clearLastCompleted();
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              Row(
                children: [
                  // 左: 日本地図
                  Flexible(
                    flex: 4,
                    child: Container(
                      color: const Color(0xFFE3F2FD),
                      child: JapanMapWidget(
                        blinkEnabled: _showFireworks,
                        onPrefectureTap: (prefName) {
                          _selectionKey.currentState
                              ?.scrollToPrefecture(prefName);
                        },
                      ),
                    ),
                  ),
                  // 区切り線
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // 右: ナンバー選択
                  Flexible(
                    flex: 5,
                    child: SelectionPanelWidget(key: _selectionKey),
                  ),
                ],
              ),
              // 花火オーバーレイ
              if (_showFireworks)
                Positioned.fill(
                  child: IgnorePointer(
                    child: FireworksWidget(
                      onComplete: () {
                        setState(() => _showFireworks = false);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
