import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Component/chat_approved.dart';
import 'package:flutter_chat/Component/chat_audio.dart';
import 'package:flutter_chat/Component/chat_image_gallery.dart';
import 'package:flutter_chat/Component/chat_media_grid.dart';
import 'package:flutter_chat/Component/chat_message_action_menu.dart';
import 'package:flutter_chat/Component/chat_message_type.dart';
import 'package:flutter_chat/Component/chat_react.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
import 'package:flutter_chat/Component/chat_view_page.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_chat/utils.dart';

class ChatMessage extends StatefulWidget {
  final String currentUser;
  final List<Chatmsgobject> msgs;
  final ValueChanged<Chatmsgobject>? onReply;
  final ValueChanged<Chatmsgobject>? onRecall;
  final ValueChanged<Chatmsgobject>? onDelete;
  final ValueChanged<String>? onTapReplyPreview;
  final ValueChanged<Chatmsgobject>? onRemoveMyReaction;
  final ValueChanged<Chatmsgobject>? onPin;
  final ValueChanged<Chatmsgobject>? onForward;
  final ItemScrollController? itemScrollController;
  final void Function(Chatmsgobject msg, String emoji)? onReaction;
  final void Function(Chatmsgobject msg, String status)? onApproveStatus;

  const ChatMessage({
    super.key,
    required this.currentUser,
    required this.msgs,
    this.onReply,
    this.onRecall,
    this.onDelete,
    this.onTapReplyPreview,
    this.onPin,
    this.onForward,
    this.itemScrollController,
    this.onReaction,
    this.onRemoveMyReaction,
    this.onApproveStatus,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  String? _longPressedApproveMsgId;

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateOnly(DateTime? dt) {
    if (dt == null) return '';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }

  void _clearApproveActions() {
    if (_longPressedApproveMsgId != null) {
      setState(() {
        _longPressedApproveMsgId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.msgs.isEmpty) {
      return const Center(
        child: Text(
          "Hãy khởi đầu cuộc trò chuyện bằng một tin nhắn 😀",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        _clearApproveActions();
      },
      child: ScrollablePositionedList.builder(
        itemScrollController: widget.itemScrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: widget.msgs.length,
        itemBuilder: (context, index) {
          final originalIndex = widget.msgs.length - 1 - index;
          final msg = widget.msgs[originalIndex];

          final Chatmsgobject? prevMsgInTime = originalIndex > 0
              ? widget.msgs[originalIndex - 1]
              : null;

          final bool showDateHeader =
              prevMsgInTime == null ||
              !_isSameDay(msg.Send_Date, prevMsgInTime.Send_Date);

          return Column(
            children: [
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _formatDateOnly(msg.Send_Date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              _MessageBubble(
                key: ValueKey(msg.IdMsg),
                currentUser: widget.currentUser,
                msg: msg,
                onReply: widget.onReply,
                onRecall: widget.onRecall,
                onDelete: widget.onDelete,
                onTapReplyPreview: widget.onTapReplyPreview,
                onReaction: widget.onReaction,
                onRemoveMyReaction: widget.onRemoveMyReaction,
                onPin: widget.onPin,
                onForward: widget.onForward,
                onApproveStatus: (targetMsg, status) {
                  widget.onApproveStatus?.call(targetMsg, status);
                  setState(() {
                    _longPressedApproveMsgId = null;
                  });
                },
                showApproveActions: _longPressedApproveMsgId == msg.IdMsg,
                onToggleApproveActions: () {
                  setState(() {
                    if (_longPressedApproveMsgId == msg.IdMsg) {
                      _longPressedApproveMsgId = null;
                    } else {
                      _longPressedApproveMsgId = msg.IdMsg;
                    }
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Chatmsgobject msg;
  final String currentUser;
  final ValueChanged<Chatmsgobject>? onReply;
  final ValueChanged<Chatmsgobject>? onRecall;
  final ValueChanged<Chatmsgobject>? onDelete;
  final ValueChanged<String>? onTapReplyPreview;
  final void Function(Chatmsgobject msg, String emoji)? onReaction;
  final ValueChanged<Chatmsgobject>? onRemoveMyReaction;
  final ValueChanged<Chatmsgobject>? onPin;
  final ValueChanged<Chatmsgobject>? onForward;
  final void Function(Chatmsgobject msg, String status)? onApproveStatus;
  final bool showApproveActions;
  final VoidCallback? onToggleApproveActions;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.currentUser,
    this.onDelete,
    this.onRecall,
    this.onReply,
    this.onTapReplyPreview,
    this.onReaction,
    this.onRemoveMyReaction,
    this.onPin,
    this.onForward,
    this.onApproveStatus,
    this.showApproveActions = false,
    this.onToggleApproveActions,
  });

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();
    final extraText = type == ChatmsgObjtype.url ? _getExtraText(msg) : '';

    if (msg.isRecalled) {
      return GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: msg.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMe ? const Color(0xFFD7FBE8) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                    ),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: const Text(
                    "Tin nhắn đã được thu hồi",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () async {
        await _showMessageActions(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: msg.isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!msg.isMe)
              Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(
                  right: 6,
                  bottom: msg.hasReaction ? 14 : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDADADA)),
                ),
                child: const Icon(Icons.person, size: 17, color: Colors.grey),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: type == ChatmsgObjtype.stiker
                          ? Colors.transparent
                          : (type == ChatmsgObjtype.tex ||
                                    type == ChatmsgObjtype.audio
                                ? (msg.isMe
                                      ? const Color(0xFFD7FBE8)
                                      : Colors.white)
                                : (msg.Note.isNotEmpty
                                      ? (msg.isMe
                                            ? const Color(
                                                0xFFD7FBE8,
                                              ).withOpacity(0.5)
                                            : Colors.white)
                                      : Colors.transparent)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                      ),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                    ),
                    child: Opacity(
                      opacity: msg.isRecalled ? 0.7 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.replyMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ReplyPreview(
                                reply: msg.replyMsg!,
                                onTap: () => onTapReplyPreview?.call(
                                  msg.replyMsg!.IdMsg,
                                ),
                              ),
                            ),

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

                          if (type == ChatmsgObjtype.video)
                            ChatMediaGrid(
                              files: msg.strDataFile,
                              type: ChatmsgObjtype.video,
                              onTapItem: (index) {
                                _openVideoPath(context, msg.strDataFile[index]);
                              },
                            ),

                          if (isFileType(type))
                            ChatMessageFile(
                              msg: msg,
                              onTap: () => _openFile(context),
                            ),

                          if (type == ChatmsgObjtype.audio)
                            ChatAudioBubble(
                              audioData: msg.file,
                              durationSeconds: msg.audioDurationSeconds > 0
                                  ? msg.audioDurationSeconds
                                  : null,
                            ),

                          if (type == ChatmsgObjtype.url)
                            ChatMessageUrl(
                              msg: msg,
                              onTap: () => _openLink(context, msg.file),
                            ),

                          if (type == ChatmsgObjtype.url &&
                              extraText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: ChatMessageText(
                                text: extraText,
                                isRecalled: msg.isRecalled,
                                onTapLink: (url) => _openLink(context, url),
                              ),
                            ),

                          if (shouldShowNoteText(type) &&
                              msg.Note.trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top:
                                    (type == ChatmsgObjtype.image ||
                                        type == ChatmsgObjtype.video)
                                    ? 8
                                    : 0,
                              ),
                              child: ChatMessageText(
                                text: msg.Note,
                                isRecalled: msg.isRecalled,
                                onTapLink: (url) => _openLink(context, url),
                              ),
                            ),

                          const SizedBox(height: 4),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (msg.isPinned) ...[
                                const Icon(
                                  Icons.push_pin,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                formatDate(msg.Send_Date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (msg.approvedStatus.trim().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                buildApprovedStatusBadge(msg.approvedStatus),
                              ],
                            ],
                          ),
                          if (msg.hasReaction) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  if (shouldShowForwardIcon(type))
                    Positioned(
                      left: msg.isMe ? -32 : null,
                      right: msg.isMe ? null : -32,
                      top: 0,
                      bottom: msg.hasReaction ? 18 : 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: _buildForwardIcon(context),
                      ),
                    ),

                  if (msg.hasReaction)
                    Positioned(
                      right: 6,
                      bottom: -10,
                      child: GestureDetector(
                        onTap: () => _showReactionUsersBottomSheet(context),
                        child: ChatReactionBadge(msg: msg),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExtraText(Chatmsgobject msg) {
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

  Future<void> _openLink(BuildContext context, String url) async {
    final raw = url.trim();
    if (raw.isEmpty) {
      showSnackBar(context, "Liên kết trống");
      return;
    }
    final fixedUrl = raw.startsWith("http://") || raw.startsWith("https://")
        ? raw
        : "https://$raw";
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatWebViewerPage(url: fixedUrl)),
    );
  }

  void _openVideoPath(BuildContext context, String path) {
    if (path.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatVideoViewerPage(path: path)),
    );
  }

  void _openFile(BuildContext context) {
    final path = msg.file.trim();
    if (path.isEmpty) return;

    final type = msg.strTypeFile.trim().toLowerCase();
    Widget page;

    switch (type) {
      case "pdf":
        page = ChatPdfViewerPage(path: path);
        break;
      case "jpg":
      case "jpeg":
      case "png":
      case "gif":
      case "webp":
      case "bmp":
        page = ChatImageViewerPage(path: path);
        break;
      case "doc":
      case "docx":
      case "xls":
      case "xlsx":
      case "ppt":
      case "pptx":
        page = ChatDocViewerPage(path: path, title: buildTitle(type));
        break;
      default:
        page = ChatUnsupportedFilePage(path: path, title: buildTitle(type));
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showReactionUsersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ReactionUsersSheet(
        msg: msg,
        onRemoveReaction: (userName) {
          if (userName == currentUser) {
            onRemoveMyReaction?.call(msg);
          }
        },
      ),
    );
  }

  Widget _buildForwardIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onForward?.call(msg);
        showSnackBar(context, 'Xử lí chuyển tiếp');
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E5EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: const Icon(Icons.reply, size: 16, color: Color(0xFF6E7682)),
        ),
      ),
    );
  }

  Future<void> _showMessageActions(BuildContext context) async {
    final result = await showChatMessageActionMenu(context, msg: msg);
    if (result == null || !context.mounted) return;

    switch (result.type) {
      case 'reaction':
        onReaction?.call(msg, result.reactionEmoji!);
        break;

      case 'approved':
        onApproveStatus?.call(msg, 'approved');
        break;

      case 'rejected':
        onApproveStatus?.call(msg, 'rejected');
        break;

      case 'copy':
        await Clipboard.setData(ClipboardData(text: msg.Note));
        showSnackBar(context, 'Đã sao chép');
        break;

      case 'pin':
        onPin?.call(msg);
        showSnackBar(context, msg.isPinned ? 'Đã ghim' : 'Đã bỏ ghim');
        break;

      case 'reply':
        onReply?.call(msg);
        break;

      case 'forward':
        onForward?.call(msg);
        showSnackBar(context, 'Xử lí chuyển tiếp');
        break;

      case 'recall':
        onRecall?.call(msg);
        break;

      case 'delete':
        final ok = await confirmDelete(context);
        if (ok) {
          onDelete?.call(msg);
          showSnackBar(context, 'Đã xóa tin nhắn');
        }
        break;
    }
  }
}
