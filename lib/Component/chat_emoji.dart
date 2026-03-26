import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmojiCategory {
  final String label;
  final IconData icon;
  final List<String> emojis;
  const EmojiCategory({
    required this.label,
    required this.icon,
    required this.emojis,
  });
}

final kEmojiCategories = <EmojiCategory>[
  const EmojiCategory(label: "Gần đây", icon: Icons.access_time, emojis: []),
  const EmojiCategory(
    label: "Mặt cười",
    icon: Icons.emoji_emotions_outlined,
    emojis: [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
      '🤨',
      '😐',
      '😑',
      '😶',
      '😏',
      '😒',
      '🙄',
      '😬',
      '🤥',
      '😌',
      '😔',
      '😪',
      '🤤',
      '😴',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🤧',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '🤠',
      '🥳',
      '😎',
      '🤓',
      '🧐',
      '😕',
      '😟',
      '🙁',
      '☹️',
      '😮',
      '😯',
      '😲',
      '😳',
      '🥺',
      '😦',
      '😧',
      '😨',
      '😰',
      '😥',
      '😢',
      '😭',
      '😱',
      '😖',
      '😣',
      '😞',
      '😓',
      '😩',
      '😫',
      '🥱',
      '😤',
      '😡',
      '😠',
      '🤬',
      '😈',
      '👿',
      '💀',
      '☠️',
      '💩',
      '🤡',
      '👹',
      '👺',
      '👻',
      '👽',
      '👾',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👌',
      '🤌',
      '🤏',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '☝️',
      '👍',
      '👎',
      '✊',
      '👊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤝',
      '🙏',
      '💪',
      '🦾',
      '🦿',
      '🦵',
      '🦶',
      '👂',
      '🦻',
      '👃',
      '🧠',
    ],
  ),
];

class RecentEmojiManager {
  static final _recent = <String>[];
  static const _maxRecent = 32;

  static List<String> get recents => List.unmodifiable(_recent);

  static void add(String emoji) {
    _recent.remove(emoji);
    _recent.insert(0, emoji);
    if (_recent.length > _maxRecent) _recent.removeLast();
  }
}

class ChatEmojiPanel extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<Sticker>? onStickerSelected;

  const ChatEmojiPanel({
    super.key,
    required this.onEmojiSelected,
    this.onStickerSelected,
  });

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final List<StickerPack> _stickerPacks;

  // Total tabs = emoji categories + sticker packs
  int get _totalTabs => kEmojiCategories.length + _stickerPacks.length;

  final List<String> _stickerUrls = [
    "http://mauiapidms.cybersoft.com.vn/stickers/bugcat_capoo",
    "http://mauiapidms.cybersoft.com.vn/stickers/milk_mocha",
    "http://mauiapidms.cybersoft.com.vn/stickers/peach_cat",
    "http://mauiapidms.cybersoft.com.vn/stickers/tonton_friends",
  ];

  @override
  void initState() {
    super.initState();
    _stickerPacks = _buildStickerPacks();
    _tabCtrl = TabController(length: _totalTabs, vsync: this);
  }

  List<StickerPack> _buildStickerPacks() {
    final packs = <StickerPack>[];
    for (final url in _stickerUrls) {
      final segments = Uri.parse(url).pathSegments;
      final packId = segments.last;
      final prefix = _initialsFromSegment(packId);

      final stickers = <Sticker>[];
      for (int j = 0; j < 100; j++) {
        final stickerUrl = "$url/$prefix${j + 1}.gif";
        stickers.add(
          Sticker(id: "${prefix}_${j + 1}", packId: packId, url: stickerUrl),
        );
      }
      packs.add(
        StickerPack(
          id: packId,
          name: packId,
          thumbnail: "$url/${prefix}1.gif",
          stickers: stickers,
        ),
      );
    }
    return packs;
  }

  String _initialsFromSegment(String segment) {
    final parts = segment.split('_');
    return parts
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onEmojiTap(String emoji) {
    RecentEmojiManager.add(emoji);
    widget.onEmojiSelected(emoji);
  }

  void _onStickerTap(Sticker sticker) {
    RecentStickerManager.add(sticker);
    HapticFeedback.lightImpact();
    widget.onStickerSelected?.call(sticker);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          // ── Unified tab bar ──────────────────────────────
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xff009EF9),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey.shade200,
            tabs: [
              // Emoji category tabs (icons)
              ...kEmojiCategories.map(
                (c) => Tab(height: 38, child: Icon(c.icon, size: 20)),
              ),
              // Divider tab (visual separator)
              // Sticker pack tabs (thumbnail images)
              ..._stickerPacks.map(
                (pack) => Tab(
                  height: 38,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      pack.thumbnail,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.sticky_note_2_outlined, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Tab content ──────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Emoji grids
                ...kEmojiCategories.map((cat) {
                  final emojis = cat.label == 'Gần đây'
                      ? RecentEmojiManager.recents
                      : cat.emojis;

                  if (emojis.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có emoji nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(6),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: emojis.length,
                    itemBuilder: (_, i) => _AnimatedEmojiCell(
                      emoji: emojis[i],
                      onTap: () => _onEmojiTap(emojis[i]),
                    ),
                  );
                }),

                // Sticker grids
                ..._stickerPacks.map((pack) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: pack.stickers.length,
                    itemBuilder: (_, i) => _AnimatedStickerCell(
                      sticker: pack.stickers[i],
                      onTap: () => _onStickerTap(pack.stickers[i]),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEmojiCell extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _AnimatedEmojiCell({required this.emoji, required this.onTap});

  @override
  State<_AnimatedEmojiCell> createState() => _AnimatedEmojiCellState();
}

class _AnimatedEmojiCellState extends State<_AnimatedEmojiCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _AnimatedStickerCell extends StatefulWidget {
  final Sticker sticker;
  final VoidCallback onTap;

  const _AnimatedStickerCell({required this.sticker, required this.onTap});

  @override
  State<_AnimatedStickerCell> createState() => _AnimatedStickerCellState();
}

class _AnimatedStickerCellState extends State<_AnimatedStickerCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  OverlayEntry? _preview;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.75,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.75,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _removePreview();
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    _showPreview(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _removePreview();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  void _showPreview(Offset pos) {
    _removePreview();
    _preview = OverlayEntry(
      builder: (_) =>
          _StickerPreviewBubble(url: widget.sticker.url, anchor: pos),
    );
    Overlay.of(context).insert(_preview!);
  }

  void _removePreview() {
    _preview?.remove();
    _preview = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          padding: const EdgeInsets.all(4),
          child: Image.network(
            widget.sticker.url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _StickerPreviewBubble extends StatefulWidget {
  final String url;
  final Offset anchor;

  const _StickerPreviewBubble({required this.url, required this.anchor});

  @override
  State<_StickerPreviewBubble> createState() => _StickerPreviewBubbleState();
}

class _StickerPreviewBubbleState extends State<_StickerPreviewBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween(
      begin: 0.3,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_ctrl);
    _opacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 160.0;
    final screenW = MediaQuery.of(context).size.width;
    final dx = (widget.anchor.dx - size / 2).clamp(8.0, screenW - size - 8);
    final dy = (widget.anchor.dy - size - 20).clamp(40.0, double.infinity);

    return Positioned(
      left: dx,
      top: dy,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class ChatStickerBubble extends StatefulWidget {
  final String url;
  final double size;

  const ChatStickerBubble({super.key, required this.url, this.size = 140});

  @override
  State<ChatStickerBubble> createState() => _ChatStickerBubbleState();
}

class _ChatStickerBubbleState extends State<ChatStickerBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale;
  late final Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _enterScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_enterCtrl);

    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_enterCtrl);

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enterCtrl,
      builder: (_, child) => SlideTransition(
        position: _enterSlide,
        child: Transform.scale(scale: _enterScale.value, child: child),
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      ),
    );
  }
}

class StickerPack {
  final String id;
  final String name;
  final String thumbnail;
  final List<Sticker> stickers;

  const StickerPack({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.stickers,
  });
}

class Sticker {
  final String id;
  final String packId;
  final String url;
  final StickerType type;

  const Sticker({
    required this.id,
    required this.packId,
    required this.url,
    this.type = StickerType.gif,
  });
}

enum StickerType { gif, lottie }

class RecentStickerManager {
  static final _recent = <Sticker>[];
  static const _maxRecent = 20;

  static List<Sticker> get recents => List.unmodifiable(_recent);

  static void add(Sticker sticker) {
    _recent.removeWhere((s) => s.id == sticker.id);
    _recent.insert(0, sticker);
    if (_recent.length > _maxRecent) _recent.removeLast();
  }
}
