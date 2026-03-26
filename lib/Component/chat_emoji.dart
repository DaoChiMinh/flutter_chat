import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Component/chat_sticker.dart';

// ============================================================
// DATA — Emoji categories
// ============================================================

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
    ],
  ),
  const EmojiCategory(
    label: "Cử chỉ",
    icon: Icons.back_hand_outlined,
    emojis: [
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
  const EmojiCategory(
    label: "Trái tim",
    icon: Icons.favorite_border,
    emojis: [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '♥️',
      '🔥',
      '✨',
      '⭐',
      '🌟',
      '💫',
      '💥',
      '💢',
      '💦',
      '💨',
      '🕊️',
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

// ============================================================
// MAIN PANEL — 2 top-level tabs: Emoji | Sticker
// ============================================================

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

class _ChatEmojiPanelState extends State<ChatEmojiPanel> {
  int _topTab = 0; // 0 = emoji, 1 = sticker

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          _TopSegment(
            selected: _topTab,
            onChanged: (i) => setState(() => _topTab = i),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _topTab == 0
                  ? _EmojiTabBody(
                      key: const ValueKey('emoji'),
                      onEmojiSelected: widget.onEmojiSelected,
                    )
                  : _StickerTabBody(
                      key: const ValueKey('sticker'),
                      onStickerSelected: widget.onStickerSelected,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOP SEGMENT
// ============================================================

class _TopSegment extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TopSegment({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _SegBtn(
            icon: Icons.emoji_emotions_outlined,
            label: 'Emoji',
            active: selected == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 4),
          _SegBtn(
            icon: Icons.sticky_note_2_outlined,
            label: 'Sticker',
            active: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xff009EF9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMOJI TAB BODY
// ============================================================

class _EmojiTabBody extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;

  const _EmojiTabBody({super.key, required this.onEmojiSelected});

  @override
  State<_EmojiTabBody> createState() => _EmojiTabBodyState();
}

class _EmojiTabBodyState extends State<_EmojiTabBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: kEmojiCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTap(String emoji) {
    RecentEmojiManager.add(emoji);
    widget.onEmojiSelected(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xff009EF9),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.grey.shade200,
          tabs: kEmojiCategories
              .map((c) => Tab(height: 38, child: Icon(c.icon, size: 20)))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: kEmojiCategories.map((cat) {
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: emojis.length,
                itemBuilder: (_, i) => _AnimatedEmojiCell(
                  emoji: emojis[i],
                  onTap: () => _onTap(emojis[i]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STICKER TAB BODY
// ============================================================

class _StickerTabBody extends StatefulWidget {
  final ValueChanged<Sticker>? onStickerSelected;

  const _StickerTabBody({super.key, this.onStickerSelected});

  @override
  State<_StickerTabBody> createState() => _StickerTabBodyState();
}

class _StickerTabBodyState extends State<_StickerTabBody> {
  int _selectedPack = 0;

  List<StickerPack>? _packs = [];
  List<String> urlStikker = [
    "http://mauiapidms.cybersoft.com.vn/stickers/bugcat_capoo",
    "http://mauiapidms.cybersoft.com.vn/stickers/milk_mocha",
    "http://mauiapidms.cybersoft.com.vn/stickers/peach_cat",
    "http://mauiapidms.cybersoft.com.vn/stickers/tonton_friends",
  ];
  @override
  void initState() {
    _packs = [];
    for (int i = 0; i < urlStikker.length; i++) {
      String packId = getInitialsFromUrl(urlStikker[i]);
      String Id = getInitialsFromUrl2ChuCuoi(urlStikker[i]);

      List<Sticker> listSticker = [];
      for (int j = 0; j < 100; j++) {
        String _url = "${urlStikker[i]}/${Id}${j + 1}.gif";
        listSticker.add(
          Sticker(id: "${Id}_{j + 1}", packId: packId, url: _url),
        );
      }
      _packs!.add(
        StickerPack(
          id: packId,
          name: packId,
          thumbnail: "thumbnail",
          stickers: listSticker,
        ),
      );
    }
    super.initState();
  }

  String getInitialsFromUrl2ChuCuoi(String url) {
    // Lấy param cuối
    final lastSegment = Uri.parse(url).pathSegments.last;

    // Tách theo _
    final parts = lastSegment.split('_');

    // Lấy chữ cái đầu mỗi phần
    final initials = parts
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .join();

    return initials;
  }

  String getInitialsFromUrl(String url) {
    // Lấy param cuối
    final lastSegment = Uri.parse(url).pathSegments.last;

    return lastSegment;
  }

  @override
  Widget build(BuildContext context) {
    final stickers = _selectedPack < 0
        ? RecentStickerManager.recents
        : _packs![_selectedPack].stickers;

    return Column(
      children: [
        // ── Pack selector bar ─────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _packs!.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              if (i == 0) {
                final isActive = _selectedPack < 0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPack = -1),
                  child: _PackIcon(
                    isActive: isActive,
                    child: Icon(
                      Icons.access_time,
                      size: 20,
                      color: isActive ? const Color(0xff009EF9) : Colors.grey,
                    ),
                  ),
                );
              }

              final idx = i - 1;
              final pack = _packs![idx];
              final isActive = _selectedPack == idx;

              return GestureDetector(
                onTap: () => setState(() => _selectedPack = idx),
                child: _PackIcon(
                  isActive: isActive,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.network(
                      pack.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Divider(height: 1, color: Colors.grey.shade200),

        // ── Sticker grid ──────────────────────────────────
        Expanded(
          child: stickers.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có sticker nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: stickers.length,
                  itemBuilder: (_, i) => _AnimatedStickerCell(
                    sticker: stickers[i],
                    onTap: () {
                      RecentStickerManager.add(stickers[i]);
                      HapticFeedback.lightImpact();
                      widget.onStickerSelected?.call(stickers[i]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _PackIcon extends StatelessWidget {
  final bool isActive;
  final Widget child;

  const _PackIcon({required this.isActive, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xffE3F2FD) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: const Color(0xff009EF9), width: 1.5)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ============================================================
// ANIMATED EMOJI CELL — bounce on tap
// ============================================================

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

// ============================================================
// ANIMATED STICKER CELL — bounce + long-press preview
// ============================================================

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

// ============================================================
// STICKER PREVIEW BUBBLE (long-press overlay)
// ============================================================

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

// ============================================================
// STICKER BUBBLE — hiển thị sticker động trong chat message
// Zalo-style: bay vào + scale bounce khi xuất hiện
// ============================================================

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

    // Scale: 0 → 1.15 → 0.95 → 1.0 (bounce)
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

    // Slide lên từ dưới
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
