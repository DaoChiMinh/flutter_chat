import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Module/chatobj.dart';

// ═══════════════════════════════════════════════════════════
// ★ Reaction Emoji Data
// ═══════════════════════════════════════════════════════════

class _ReactionEmoji {
  final String emoji;
  final String id;
  const _ReactionEmoji({required this.emoji, required this.id});
}

const _kReactions = <_ReactionEmoji>[
  _ReactionEmoji(emoji: '❤️', id: 'heart'),
  _ReactionEmoji(emoji: '👍', id: 'like'),
  _ReactionEmoji(emoji: '😆', id: 'haha'),
  _ReactionEmoji(emoji: '😮', id: 'wow'),
  _ReactionEmoji(emoji: '😢', id: 'sad'),
  _ReactionEmoji(emoji: '😡', id: 'angry'),
];

// ═══════════════════════════════════════════════════════════
// ★ Action Menu Item Data
// ═══════════════════════════════════════════════════════════

class ChatMenuAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isNew; // badge "MỚI"
  final bool isDestructive;

  const ChatMenuAction({
    required this.id,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF555555),
    this.isNew = false,
    this.isDestructive = false,
  });
}

// ═══════════════════════════════════════════════════════════
// ★ Menu Result
// ═══════════════════════════════════════════════════════════

class ChatMenuResult {
  /// "reaction" hoặc action id
  final String type;

  /// Nếu type == "reaction" → emoji string (❤️, 👍, ...)
  final String? reactionEmoji;

  const ChatMenuResult({required this.type, this.reactionEmoji});
}

List<ChatMenuAction> buildDefaultActions(Chatmsgobject msg) {
  final actions = <ChatMenuAction>[
    const ChatMenuAction(
      id: 'reply',
      label: 'Trả lời',
      icon: Icons.reply,
      color: Color(0xFF6C63FF),
    ),
    const ChatMenuAction(
      id: 'forward',
      label: 'Chuyển tiếp',
      icon: Icons.shortcut,
      color: Color(0xFF3498DB),
    ),
    const ChatMenuAction(
      id: 'save',
      label: 'Lưu My\nDocuments',
      icon: Icons.save_alt,
      color: Color(0xFF2196F3),
    ),
    const ChatMenuAction(
      id: 'copy',
      label: 'Sao chép',
      icon: Icons.copy,
      color: Color(0xFF607D8B),
    ),
    ChatMenuAction(
      id: 'pin',
      label: msg.isPinned ? 'Bỏ ghim' : 'Ghim',
      icon: msg.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
      color: const Color(0xFFFF6B35),
    ),
    // const ChatMenuAction(
    //   id: 'reminder',
    //   label: 'Nhắc hẹn',
    //   icon: Icons.access_time,
    //   color: const Color(0xFFE74C3C),
    // ),
    // const ChatMenuAction(
    //   id: 'multi_select',
    //   label: 'Chọn nhiều',
    //   icon: Icons.checklist,
    //   color: Color(0xFF00BCD4),
    // ),
    // const ChatMenuAction(
    //   id: 'quick_msg',
    //   label: 'Tạo tin\nnhắn nhanh',
    //   icon: Icons.quickreply_outlined,
    //   color: Color(0xFF009688),
    // ),
    // const ChatMenuAction(
    //   id: 'translate',
    //   label: 'Dịch',
    //   icon: Icons.translate,
    //   color: Color(0xFF7C4DFF),
    //   isNew: true,
    // ),
    // const ChatMenuAction(
    //   id: 'read_aloud',
    //   label: 'Đọc văn bản',
    //   icon: Icons.record_voice_over_outlined,
    //   color: Color(0xFF7C4DFF),
    //   isNew: true,
    // ),
    // const ChatMenuAction(
    //   id: 'detail',
    //   label: 'Chi tiết',
    //   icon: Icons.info_outline,
    //   color: Color(0xFF78909C),
    // ),
  ];

  // Chỉ hiện Xóa + Thu hồi cho tin nhắn của mình
  if (msg.isMe && !msg.isRecalled) {
    actions.add(
      const ChatMenuAction(
        id: 'recall',
        label: 'Thu hồi',
        icon: Icons.undo,
        color: Color(0xFFFF9800),
      ),
    );
  }

  actions.add(
    const ChatMenuAction(
      id: 'delete',
      label: 'Xóa',
      icon: Icons.delete_outline,
      color: Color(0xFFE53935),
      isDestructive: true,
    ),
  );

  return actions;
}

// ═══════════════════════════════════════════════════════════
// ★ PUBLIC API — Gọi từ _MessageBubble.onLongPress
// ═══════════════════════════════════════════════════════════

/// Hiển thị menu hành động kiểu Zalo.
/// Trả về [ChatMenuResult] hoặc null nếu dismiss.
Future<ChatMenuResult?> showChatMessageActionMenu(
  BuildContext context, {
  required Chatmsgobject msg,
  List<ChatMenuAction>? actions,
}) {
  HapticFeedback.mediumImpact();

  final menuActions = actions ?? buildDefaultActions(msg);

  return showGeneralDialog<ChatMenuResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (ctx, anim, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(
            begin: 0.92,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, anim, anim2) {
      return _ChatMessageActionMenuDialog(msg: msg, actions: menuActions);
    },
  );
}

// ═══════════════════════════════════════════════════════════
// ★ Dialog Widget
// ═══════════════════════════════════════════════════════════

class _ChatMessageActionMenuDialog extends StatelessWidget {
  final Chatmsgobject msg;
  final List<ChatMenuAction> actions;

  const _ChatMessageActionMenuDialog({
    required this.msg,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tap ngoài để dismiss ──
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // ── Message preview bubble ──
          _MessagePreviewBubble(msg: msg),

          const SizedBox(height: 8),

          // ── Reaction emoji row ──
          _ReactionRow(
            onReactionTap: (emoji) {
              HapticFeedback.lightImpact();
              Navigator.pop(
                context,
                ChatMenuResult(type: 'reaction', reactionEmoji: emoji),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Action grid ──
          _ActionGrid(
            actions: actions,
            onActionTap: (action) {
              HapticFeedback.lightImpact();
              Navigator.pop(context, ChatMenuResult(type: action.id));
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ★ Message Preview Bubble
// ═══════════════════════════════════════════════════════════

class _MessagePreviewBubble extends StatelessWidget {
  final Chatmsgobject msg;

  const _MessagePreviewBubble({required this.msg});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get _previewText {
    if (msg.Note.trim().isNotEmpty) return msg.Note.trim();
    final type = msg.objtype();
    switch (type) {
      case ChatmsgObjtype.image:
        return '[Hình ảnh]';
      case ChatmsgObjtype.video:
        return '[Video]';
      case ChatmsgObjtype.audio:
        return '[Tin nhắn thoại]';
      case ChatmsgObjtype.pdf:
        return '[PDF]';
      case ChatmsgObjtype.doc:
        return '[Tài liệu]';
      case ChatmsgObjtype.excel:
        return '[Bảng tính]';
      case ChatmsgObjtype.file:
        return '[Tệp đính kèm]';
      case ChatmsgObjtype.url:
        return msg.file.isNotEmpty ? msg.file : '[Liên kết]';
      case ChatmsgObjtype.stiker:
        return '[Sticker]';
      default:
        return '';
    }
  }

  String getExtraText(Chatmsgobject msg) {
    var text = msg.Note.trim();
    if (text.isEmpty) return '';

    for (final url in msg.strDataFile) {
      text = text.replaceAll(url, '');
    }

    final urlRegex = RegExp(
      r'(https?://[^\s]+)|(www\.[^\s]+)|((?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[/?#][^\s]*)?)',
      caseSensitive: false,
    );
    text = text.replaceAll(urlRegex, '');

    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();
    final extraText = type == ChatmsgObjtype.url ? getExtraText(msg) : '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == ChatmsgObjtype.image)
            ChatMediaGrid(
              files: msg.strDataFile,
              type: ChatmsgObjtype.image,
              onTapItem: (index) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatImageGalleryPage(
                    paths: msg.strDataFile,
                    initialIndex: index,
                  ),
                ),
              ),
            ),
          if (type == ChatmsgObjtype.stiker)
            Image.network(msg.Note, height: 120),

          if (type == ChatmsgObjtype.url)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Image.network(
                    msg.ImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF0F2F5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.language,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF0F2F5),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayDomain(msg.file),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                          decoration: TextDecoration.none,
                          height: 1.35,
                        ),
                        // style: TextStyle(
                        //   fontSize: 12,
                        //   color: Colors.green.shade700,
                        //   fontWeight: FontWeight.w500,
                        // ),
                      ),

                      if (msg.titleUrl != null && msg.titleUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            msg.titleUrl!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  decoration: TextDecoration.none,
                                  height: 1.35,
                                ),
                            // style: const TextStyle(
                            //   fontSize: 14,
                            //   fontWeight: FontWeight.w600,
                            //   color: Colors.black87,
                            //   height: 1.3,
                            // ),
                          ),
                        ),

                      if (msg.descriptioneUrl != null &&
                          msg.descriptioneUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            msg.descriptioneUrl!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                  decoration: TextDecoration.none,
                                  height: 1.35,
                                ),
                            // style: TextStyle(
                            //   fontSize: 13,
                            //   color: Colors.grey.shade700,
                            //   height: 1.3,
                            // ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

          if (type != ChatmsgObjtype.stiker &&
              type != ChatmsgObjtype.url &&
              msg.Note.trim().isNotEmpty)
            Text(
              _previewText,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                decoration: TextDecoration.none,
                height: 1.35,
              ),
            ),

          const SizedBox(height: 8),
          Text(
            _formatTime(msg.Send_Date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _displayDomain(String _url) {
    final uri = Uri.tryParse(_url);
    return uri?.host ?? _url;
  }
}

class _ReactionRow extends StatelessWidget {
  final ValueChanged<String> onReactionTap;

  const _ReactionRow({required this.onReactionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _kReactions.map((r) {
          return _ReactionEmojiButton(
            emoji: r.emoji,
            onTap: () => onReactionTap(r.emoji),
          );
        }).toList(),
      ),
    );
  }
}

class _ReactionEmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionEmojiButton({required this.emoji, required this.onTap});

  @override
  State<_ReactionEmojiButton> createState() => _ReactionEmojiButtonState();
}

class _ReactionEmojiButtonState extends State<_ReactionEmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

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
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.9,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            widget.emoji,
            style: const TextStyle(
              fontSize: 24,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<ChatMenuAction> actions;
  final ValueChanged<ChatMenuAction> onActionTap;

  const _ActionGrid({required this.actions, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 0.82,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _ActionCell(action: action, onTap: () => onActionTap(action));
        },
      ),
    );
  }
}

class _ActionCell extends StatefulWidget {
  final ChatMenuAction action;
  final VoidCallback onTap;

  const _ActionCell({required this.action, required this.onTap});

  @override
  State<_ActionCell> createState() => _ActionCellState();
}

class _ActionCellState extends State<_ActionCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 28, color: action.color),
            const SizedBox(height: 6),

            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
