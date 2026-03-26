import 'package:flutter/material.dart';

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
  EmojiCategory(label: "Gần đây", icon: Icons.access_time, emojis: []),
  EmojiCategory(
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
];

class RecentEmojiManager {
  static final _recent = <String>[];
  static const _maxRecent = 32;

  static List<String> get recents => List.unmodifiable(_recent);

  static void add(String emoji) {
    _recent.remove(emoji); // bỏ nếu đã có
    _recent.insert(0, emoji); // thêm vào đầu
    if (_recent.length > _maxRecent) {
      _recent.removeLast();
    }
  }
}

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
          // ── Tab bar categories ────────────────────────────
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xff009EF9),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey.shade200,
            tabs: kEmojiCategories.map((cat) {
              return Tab(height: 42, child: Icon(cat.icon, size: 22));
            }).toList(),
          ),

          // ── Emoji grid ────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: kEmojiCategories.map((cat) {
                // Tab "Gần đây" dùng RecentEmojiManager
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
                  itemBuilder: (context, i) {
                    return _EmojiCell(
                      emoji: emojis[i],
                      onTap: () => _onEmojiTap(emojis[i]),
                    );
                  },
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
// EMOJI CELL
// ============================================================

class _EmojiCell extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiCell({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
