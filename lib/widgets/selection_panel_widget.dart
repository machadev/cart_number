import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prefecture.dart';
import '../providers/collection_provider.dart';
import 'japan_map_widget.dart';

class SelectionPanelWidget extends StatefulWidget {
  /// 花火中に強調表示する都道府県名（null = 通常表示）
  final String? fireworksHighlight;

  const SelectionPanelWidget({
    super.key,
    this.fireworksHighlight,
  });

  @override
  State<SelectionPanelWidget> createState() => SelectionPanelWidgetState();
}

class SelectionPanelWidgetState extends State<SelectionPanelWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _prefScrollController = ScrollController();
  final ScrollController _regionScrollController = ScrollController();

  // 都道府県名 → スクロールオフセット（都道府県タブ）
  final Map<String, double> _prefScrollOffsets = {};
  // 都道府県名 → スクロールオフセット（地域タブ）
  final Map<String, double> _regionScrollOffsets = {};

  static const _regionTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prefScrollController.dispose();
    _regionScrollController.dispose();
    super.dispose();
  }

  void scrollToPrefecture(String prefName) {
    final isRegionTab = _tabController.index == _regionTabIndex;
    final offsets =
        isRegionTab ? _regionScrollOffsets : _prefScrollOffsets;
    final controller =
        isRegionTab ? _regionScrollController : _prefScrollController;
    final offset = offsets[prefName];
    if (offset != null) {
      controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void registerPrefOffset(
      String name, double offset, bool isRegionTab) {
    if (isRegionTab) {
      _regionScrollOffsets[name] = offset;
    } else {
      _prefScrollOffsets[name] = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionProvider>(
      builder: (context, provider, _) {
        final total = provider.totalPlates;
        final collected = provider.totalCollected;
        final rate = (provider.globalRate * 100).toStringAsFixed(1);

        // 強調表示する都道府県を取得
        final highlightedPref = widget.fireworksHighlight != null
            ? provider.prefectures.where(
                (p) => p.name == widget.fireworksHighlight).firstOrNull
            : null;

        // リストエリア（暗転中はスクロール無効）
        final listArea = AbsorbPointer(
          absorbing: highlightedPref != null,
          child: TabBarView(
            controller: _tabController,
            children: [
              _PrefectureTab(
                provider: provider,
                scrollController: _prefScrollController,
                onRegisterOffset: (name, offset) =>
                    registerPrefOffset(name, offset, false),
              ),
              _RegionTab(
                provider: provider,
                scrollController: _regionScrollController,
                onRegisterOffset: (name, offset) =>
                    registerPrefOffset(name, offset, true),
              ),
            ],
          ),
        );

        return Column(
          children: [
            // 全国統計（暗転対象外）
            Container(
              color: Colors.blueGrey.shade700,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '全国: $collected / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '収集率: $rate%',
                    style: const TextStyle(color: Colors.white70, fontSize: 30),
                  ),
                ],
              ),
            ),
            // タブ（暗転対象外）
            Container(
              color: Colors.blueGrey.shade800,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 28),
                tabs: const [
                  Tab(text: '都道府県'),
                  Tab(text: '地域'),
                ],
              ),
            ),
            // リストエリア（暗転はここだけ）
            Expanded(
              child: Stack(
                children: [
                  listArea,
                  if (highlightedPref != null) ...[
                    // 白いコンテナ（リストを隠す）
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: Colors.white),
                      ),
                    ),
                    // 暗転コンテナ（透明度80%）
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: const Color(0xcc000000)),
                      ),
                    ),
                    // 完成した都道府県を先頭に表示
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(
                        child: _PrefectureSection(
                          prefecture: highlightedPref,
                          provider: provider,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrefectureTab extends StatelessWidget {
  final CollectionProvider provider;
  final ScrollController scrollController;
  final void Function(String name, double offset) onRegisterOffset;

  const _PrefectureTab({
    required this.provider,
    required this.scrollController,
    required this.onRegisterOffset,
  });

  @override
  Widget build(BuildContext context) {
    final prefectures = provider.prefectures;
    return _OffsetTrackingList(
      scrollController: scrollController,
      items: prefectures,
      onRegisterOffset: onRegisterOffset,
      itemBuilder: (pref) => _PrefectureSection(
        prefecture: pref,
        provider: provider,
      ),
    );
  }
}

class _RegionTab extends StatelessWidget {
  final CollectionProvider provider;
  final ScrollController scrollController;
  final void Function(String name, double offset) onRegisterOffset;

  const _RegionTab({
    required this.provider,
    required this.scrollController,
    required this.onRegisterOffset,
  });

  @override
  Widget build(BuildContext context) {
    const regions = Region.values;
    return LayoutBuilder(
      builder: (context, constraints) => ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: constraints.maxHeight),
      itemCount: regions.length,
      itemBuilder: (context, regionIndex) {
        final region = regions[regionIndex];
        final prefs = provider.getPrefecturesByRegion(region);
        if (prefs.isEmpty) return const SizedBox.shrink();

        final regionTotal =
            prefs.fold(0, (s, p) => s + p.totalPlates);
        final regionCollected =
            prefs.fold(0, (s, p) => s + p.collectedPlates);
        final regionRate = regionTotal > 0
            ? (regionCollected / regionTotal * 100).toStringAsFixed(1)
            : '0.0';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: region.baseColor.withAlpha(50),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    color: region.baseColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    region.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: region.baseColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$regionCollected/$regionTotal ($regionRate%)',
                    style: TextStyle(
                      fontSize: 24,
                      color: region.baseColor,
                    ),
                  ),
                ],
              ),
            ),
            ...prefs.map((pref) => _PrefectureSection(
                  prefecture: pref,
                  provider: provider,
                )),
          ],
        );
      },
    ),
    );
  }
}

class _OffsetTrackingList extends StatefulWidget {
  final List<Prefecture> items;
  final ScrollController scrollController;
  final void Function(String name, double offset) onRegisterOffset;
  final Widget Function(Prefecture) itemBuilder;

  const _OffsetTrackingList({
    required this.items,
    required this.scrollController,
    required this.onRegisterOffset,
    required this.itemBuilder,
  });

  @override
  State<_OffsetTrackingList> createState() => _OffsetTrackingListState();
}

class _OffsetTrackingListState extends State<_OffsetTrackingList> {
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _keys[i] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureOffsets());
    widget.scrollController.addListener(_measureOffsets);
  }

  void _measureOffsets() {
    for (int i = 0; i < widget.items.length; i++) {
      final key = _keys[i];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      final listCtx = context;
      final listBox = listCtx.findRenderObject() as RenderBox?;
      if (listBox == null) continue;
      final listPos = listBox.localToGlobal(Offset.zero);
      final relativeY = pos.dy - listPos.dy;
      final scrollOffset = widget.scrollController.hasClients
          ? widget.scrollController.offset
          : 0.0;
      widget.onRegisterOffset(
          widget.items[i].name, scrollOffset + relativeY);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          controller: widget.scrollController,
          // 最後のアイテムでも最上部にスクロールできるよう底部にビューポート分のパディングを追加
          padding: EdgeInsets.only(bottom: constraints.maxHeight),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            return KeyedSubtree(
              key: _keys[index],
              child: widget.itemBuilder(widget.items[index]),
            );
          },
        );
      },
    );
  }
}

class _PrefectureSection extends StatelessWidget {
  final Prefecture prefecture;
  final CollectionProvider provider;

  const _PrefectureSection({
    required this.prefecture,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final pref = prefecture;
    final rate = (pref.collectionRate * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: pref.region.baseColor.withAlpha(80),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: pref.isComplete
            ? pref.region.baseColor.withAlpha(30)
            : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pref.region.baseColor.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            child: Row(
              children: [
                PrefectureShapeIcon(
                  prefectureName: pref.name,
                  color: Colors.white,
                  strokeColor: pref.region.baseColor,
                  size: 36,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 96,
                  child: Text(
                    pref.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: pref.region.baseColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.workspace_premium,
                  color: pref.isComplete ? Colors.amber : Colors.transparent,
                  size: 28,
                ),
                const Spacer(),
                Text(
                  '${pref.collectedPlates}/${pref.totalPlates}  $rate%',
                  style: TextStyle(
                    fontSize: 20,
                    color: pref.region.baseColor,
                  ),
                ),
              ],
            ),
          ),
          // プレートボタン
          Padding(
            padding: const EdgeInsets.all(5),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pref.plates
                  .map((plate) => _PlateButton(
                        plate: plate,
                        prefecture: pref,
                        provider: provider,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateButton extends StatelessWidget {
  final NumberPlate plate;
  final Prefecture prefecture;
  final CollectionProvider provider;

  const _PlateButton({
    required this.plate,
    required this.prefecture,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final color = prefecture.region.baseColor;
    final isCollected = plate.collected;
    // 固定幅: padding(8)*2 + star(20) + gap(2) + fontSize20*5文字(100) = 138
    const double buttonWidth = 138;
    return GestureDetector(
      onTap: () => provider.togglePlate(prefecture.name, plate.name),
      child: SizedBox(
        width: buttonWidth,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isCollected ? color : Colors.white,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCollected ? Icons.star : Icons.star_border,
                size: 20,
                color: isCollected ? Colors.amber : color,
              ),
              const SizedBox(width: 2),
              Text(
                plate.name,
                style: TextStyle(
                  fontSize: 20,
                  color: isCollected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
