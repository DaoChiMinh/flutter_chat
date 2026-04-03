import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ChatReactionBadge extends StatelessWidget {
  final Chatmsgobject msg;

  const ChatReactionBadge({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final emojis = msg.getEmojiList;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...emojis.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(e, style: const TextStyle(fontSize: 13, height: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class ReactionUsersSheet extends StatefulWidget {
  final Chatmsgobject msg;
  final void Function(String userName)? onRemoveReaction;

  const ReactionUsersSheet({
    super.key,
    required this.msg,
    this.onRemoveReaction,
  });

  @override
  State<ReactionUsersSheet> createState() => _ReactionUsersSheetState();
}

class _ReactionUsersSheetState extends State<ReactionUsersSheet> {
  String _selected = 'all';

  @override
  Widget build(BuildContext context) {
    final summary = widget.msg.reactionSummary;
    final byUser = widget.msg.reactionByUser;

    final tabs = <MapEntry<String, String>>[
      const MapEntry('all', 'Tất cả'),
      ...summary.keys.map((e) => MapEntry(e, e)),
    ];

    final entries = byUser.entries.where((e) {
      if (_selected == 'all') return true;
      return e.value.contains(_selected);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.42,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD6D6D6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final key = tabs[i].key;
                  final label = tabs[i].value;
                  final selected = _selected == key;

                  final count = key == 'all'
                      ? widget.msg.reactionCount
                      : (summary[key] ?? 0);

                  return GestureDetector(
                    onTap: () => setState(() => _selected = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF232323),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF707070),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (_, i) {
                  final user = entries[i].key;
                  final emojis = entries[i].value;

                  return InkWell(
                    onTap: () {
                      widget.onRemoveReaction?.call(user);
                      Navigator.pop(context);
                    },
                    child: Container(
                      color: const Color(0xFFEAF6FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFE0E0E0),
                            child: Text(
                              user.isNotEmpty ? user[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Ấn vào để gỡ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...emojis.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${emojis.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
