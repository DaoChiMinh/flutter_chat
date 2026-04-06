
import 'package:flutter/services.dart';
import 'package:flutter_chat/chat_frame.dart';

class MessageBubble extends StatelessWidget {
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
  final String searchKeyword;
  final List<String> matchedMessageIds;
  final String? currentMatchedMessageId;

  const MessageBubble({
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
    this.searchKeyword = '',
    this.matchedMessageIds = const [],
    this.currentMatchedMessageId,
  });

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();
    final extraText = type == ChatmsgObjtype.url ? _getExtraText(msg) : '';

    if (msg.isRecalled) {
      return GestureDetector(
        onLongPress: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          await _showMessageActions(context);
        },
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
        FocusManager.instance.primaryFocus?.unfocus();
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
                                keyword: searchKeyword,
                                isCurrentMatch:
                                    currentMatchedMessageId == msg.IdMsg,
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
                                keyword: searchKeyword,
                                isCurrentMatch:
                                    currentMatchedMessageId == msg.IdMsg,
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
                                formatTime(msg.Send_Date),
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
      case 'reply':
        onReply?.call(msg);
        break;

      case 'reaction':
        FocusManager.instance.primaryFocus?.unfocus();
        onReaction?.call(msg, result.reactionEmoji!);
        break;

      case 'approved':
        FocusManager.instance.primaryFocus?.unfocus();
        onApproveStatus?.call(msg, 'approved');
        break;

      case 'rejected':
        FocusManager.instance.primaryFocus?.unfocus();
        onApproveStatus?.call(msg, 'rejected');
        break;

      case 'copy':
        FocusManager.instance.primaryFocus?.unfocus();
        await Clipboard.setData(ClipboardData(text: msg.Note));
        showSnackBar(context, 'Đã sao chép');
        break;

      case 'pin':
        FocusManager.instance.primaryFocus?.unfocus();
        onPin?.call(msg);
        showSnackBar(context, msg.isPinned ? 'Đã ghim' : 'Đã bỏ ghim');
        break;

      case 'forward':
        FocusManager.instance.primaryFocus?.unfocus();
        onForward?.call(msg);
        showSnackBar(context, 'Xử lí chuyển tiếp');
        break;

      case 'recall':
        FocusManager.instance.primaryFocus?.unfocus();
        onRecall?.call(msg);
        break;

      case 'delete':
        FocusManager.instance.primaryFocus?.unfocus();
        final ok = await confirmDelete(context);
        if (ok) {
          onDelete?.call(msg);
          showSnackBar(context, 'Đã xóa tin nhắn');
        }
        break;
    }
  }
}
