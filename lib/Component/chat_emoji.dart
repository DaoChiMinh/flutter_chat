import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// DATA
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
  const EmojiCategory(
    label: "Đồ vật",
    icon: Icons.lightbulb_outline,
    emojis: [
      '🎉',
      '🎊',
      '🎈',
      '🎁',
      '🎀',
      '🏆',
      '🥇',
      '🥈',
      '🥉',
      '⚽',
      '🏀',
      '🎮',
      '🎯',
      '🎲',
      '🧩',
      '🎭',
      '🎨',
      '🎬',
      '🎤',
      '🎧',
      '🎵',
      '🎶',
      '📱',
      '💻',
      '⌨️',
      '🖥️',
      '📷',
      '📸',
      '📹',
      '🔑',
    ],
  ),
];

// ============================================================
// RECENT EMOJI MANAGER
// ============================================================

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
// EMOJI PANEL
// ============================================================

class ChatEmojiPanel extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;

  const ChatEmojiPanel({super.key, required this.onEmojiSelected});

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kEmojiCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEmojiTap(String emoji) {
    RecentEmojiManager.add(emoji);
    widget.onEmojiSelected(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xff009EF9),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey.shade200,
            tabs: kEmojiCategories
                .map((c) => Tab(height: 42, child: Icon(c.icon, size: 22)))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
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
                    onTap: () => _onEmojiTap(emojis[i]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANIMATED EMOJI CELL — Zalo-style bounce + long-press preview
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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  OverlayEntry? _previewEntry;

  @override
  void initState() {
    super.initState();

    // Bounce: 1.0 → 1.4 → 1.0  (overshoot curve)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnim = TweenSequence<double>([
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
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _removePreview();
    _controller.dispose();
    super.dispose();
  }

  // ── Tap: bounce + send ──────────────────────────────────

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);
    widget.onTap();
  }

  // ── Long press: floating preview ────────────────────────

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    _showPreview(details.globalPosition);
  }

  void _handleLongPressEnd(LongPressEndDetails _) {
    _removePreview();
    // Cũng gửi emoji khi nhả long-press
    _controller.forward(from: 0);
    widget.onTap();
  }

  void _showPreview(Offset position) {
    _removePreview();

    _previewEntry = OverlayEntry(
      builder: (_) =>
          _EmojiPreviewBubble(emoji: widget.emoji, anchor: position),
    );

    Overlay.of(context).insert(_previewEntry!);
  }

  void _removePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
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
// FLOATING PREVIEW BUBBLE  (long-press)
// ============================================================

class _EmojiPreviewBubble extends StatefulWidget {
  final String emoji;
  final Offset anchor;

  const _EmojiPreviewBubble({required this.emoji, required this.anchor});

  @override
  State<_EmojiPreviewBubble> createState() => _EmojiPreviewBubbleState();
}

class _EmojiPreviewBubbleState extends State<_EmojiPreviewBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
    // Bubble xuất hiện phía trên ngón tay
    const bubbleSize = 72.0;
    final dx = widget.anchor.dx - bubbleSize / 2;
    final dy = widget.anchor.dy - bubbleSize - 24;

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
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(widget.emoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}
