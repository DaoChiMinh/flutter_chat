import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Component/chat_audio.dart';
import 'package:flutter_chat/Component/chat_message_action_menu.dart';
import 'package:flutter_chat/Component/chat_message_type.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
import 'package:flutter_chat/Component/chat_view_page.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
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

    return ScrollablePositionedList.builder(
      itemScrollController: widget.itemScrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: widget.msgs.length,
      itemBuilder: (context, index) {
        final msg = widget.msgs[widget.msgs.length - 1 - index];

        return _MessageBubble(
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
        );
      },
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
  });

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();

    // Kiểm tra xem tin nhắn URL có kèm text riêng không
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
                  maxWidth: MediaQuery.of(context).size.width * 0.70,
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
      onLongPress: () => _showMessageActions(context),
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

                          if (_isFileType(type))
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

                          if (type == ChatmsgObjtype.url &&
                              extraText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ChatMessageText(
                                text: extraText,
                                isRecalled: msg.isRecalled,
                                onTapLink: (url) => _openLink(context, url),
                              ),
                            ),

                          if (type == ChatmsgObjtype.url)
                            ChatMessageUrl(
                              msg: msg,
                              onTap: () => _openLink(context, msg.file),
                            ),

                          if (_shouldShowNoteText(type) &&
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
                                _formatDate(msg.Send_Date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (msg.hasReaction) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  if (_shouldShowForwardIcon(type))
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

  bool _shouldShowForwardIcon(ChatmsgObjtype type) {
    return [
      ChatmsgObjtype.image,
      ChatmsgObjtype.video,
      ChatmsgObjtype.pdf,
      ChatmsgObjtype.doc,
      ChatmsgObjtype.excel,
      ChatmsgObjtype.file,
      ChatmsgObjtype.url,
      ChatmsgObjtype.audio,
    ].contains(type);
  }

  bool _isFileType(ChatmsgObjtype type) {
    return [
      ChatmsgObjtype.pdf,
      ChatmsgObjtype.doc,
      ChatmsgObjtype.excel,
      ChatmsgObjtype.file,
    ].contains(type);
  }

  /// Các loại tin nhắn nên hiển thị Note text bên dưới media
  bool _shouldShowNoteText(ChatmsgObjtype type) {
    return type == ChatmsgObjtype.tex ||
        type == ChatmsgObjtype.image ||
        type == ChatmsgObjtype.video;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "";
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  //snack bar nho o giua man hinh
  void _showSnackBar(BuildContext context, String text) {
    final height = MediaQuery.of(context).size.height;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: height * 0.4, // đẩy lên giữa màn hình
            left: 80,
            right: 80,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
          elevation: 0,
        ),
      );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final raw = url.trim();
    if (raw.isEmpty) {
      _showSnackBar(context, "Liên kết trống");
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
        page = ChatDocViewerPage(path: path, title: _buildTitle(type));
        break;
      default:
        page = ChatUnsupportedFilePage(path: path, title: _buildTitle(type));
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _buildTitle(String type) {
    switch (type) {
      case "pdf":
        return "PDF";
      case "doc":
      case "docx":
        return "Word";
      case "xls":
      case "xlsx":
        return "Excel";
      case "ppt":
      case "pptx":
        return "PowerPoint";
      default:
        return "Tệp";
    }
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
        _showSnackBar(context, 'Xử lí chuyển tiếp');
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
        //msg.isMe ? Matrix4.identity() :
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: const Icon(Icons.reply, size: 16, color: Color(0xFF6E7682)),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xóa tin nhắn?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bạn có chắc muốn xóa tin nhắn này không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  void _showMessageActions(BuildContext context) async {
    final result = await showChatMessageActionMenu(context, msg: msg);
    if (result == null || !context.mounted) return;

    switch (result.type) {
      case 'reaction':
        onReaction?.call(msg, result.reactionEmoji!);
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: msg.Note));
        _showSnackBar(context, 'Đã sao chép');
        break;
      case 'pin':
        onPin?.call(msg);
        _showSnackBar(context, msg.isPinned ? 'Đã ghim' : 'Đã bỏ ghim');
        break;
      case 'reply':
        onReply?.call(msg);
        break;
      case 'forward':
        onForward?.call(msg);
        _showSnackBar(context, 'Xử lí chuyển tiếp');
        break;
      case 'recall':
        onRecall?.call(msg);
        //_showSnackBar(context, 'Đã thu hồi tin nhắn');
        break;
      case 'delete':
        final ok = await _confirmDelete(context);
        if (ok) {
          onDelete?.call(msg);
          _showSnackBar(context, 'Đã xóa tin nhắn');
        }
        break;
    }
  }
}

class ChatMediaGrid extends StatelessWidget {
  final List<String> files;
  final ChatmsgObjtype type;
  final ValueChanged<int> onTapItem;

  const ChatMediaGrid({
    super.key,
    required this.files,
    required this.type,
    required this.onTapItem,
  });

  static const _gap = 2.0;
  static const _radius = 10.0;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final count = files.length;
    final maxW = MediaQuery.of(context).size.width * 0.68;

    if (count == 1) {
      return _cell(0, maxW, 180, borderRadius: BorderRadius.circular(_radius));
    }

    if (count == 2) {
      final w = (maxW - _gap) / 2;
      final h = w;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(
            0,
            w,
            h,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
            ),
          ),
          const SizedBox(width: _gap),
          _cell(
            1,
            w,
            h,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(_radius),
              bottomRight: Radius.circular(_radius),
            ),
          ),
        ],
      );
    }

    if (count == 3) {
      final bigW = maxW * 0.6;
      final smallW = maxW - bigW - _gap;
      final totalH = maxW * 0.75;
      final smallH = (totalH - _gap) / 2;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(
            0,
            bigW,
            totalH,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
            ),
          ),
          const SizedBox(width: _gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cell(
                1,
                smallW,
                smallH,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(_radius),
                ),
              ),
              const SizedBox(height: _gap),
              _cell(
                2,
                smallW,
                smallH,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(_radius),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return _buildDynamicGrid(maxW);
  }

  List<int> _distributeRows(int count) {
    final numRows = (count + 2) ~/ 3;
    final base = count ~/ numRows;
    final extra = count % numRows;
    final rows = List<int>.filled(numRows, base);
    final start = (numRows - extra) ~/ 2;
    for (int i = 0; i < extra; i++) {
      rows[start + i]++;
    }
    return rows;
  }

  Widget _buildDynamicGrid(double maxW) {
    final rowSizes = _distributeRows(files.length);
    final numRows = rowSizes.length;
    const cellH = 120.0;
    int fileIdx = 0;
    final rowWidgets = <Widget>[];

    for (int r = 0; r < numRows; r++) {
      final cols = rowSizes[r];
      final cellW = (maxW - _gap * (cols - 1)) / cols;
      final cells = <Widget>[];
      for (int c = 0; c < cols; c++) {
        final br = BorderRadius.only(
          topLeft: r == 0 && c == 0
              ? const Radius.circular(_radius)
              : Radius.zero,
          topRight: r == 0 && c == cols - 1
              ? const Radius.circular(_radius)
              : Radius.zero,
          bottomLeft: r == numRows - 1 && c == 0
              ? const Radius.circular(_radius)
              : Radius.zero,
          bottomRight: r == numRows - 1 && c == cols - 1
              ? const Radius.circular(_radius)
              : Radius.zero,
        );
        cells.add(_cell(fileIdx, cellW, cellH, borderRadius: br));
        fileIdx++;
        if (c < cols - 1) cells.add(const SizedBox(width: _gap));
      }
      rowWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
      if (r < numRows - 1) rowWidgets.add(const SizedBox(height: _gap));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rowWidgets);
  }

  Widget _cell(
    int index,
    double w,
    double h, {
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return GestureDetector(
      onTap: () => onTapItem(index),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: w,
          height: h,
          child: type == ChatmsgObjtype.video
              ? ChatVideoThumb(path: files[index])
              : _buildImage(files[index]),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final bytes = _decodeBase64(path);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final raw = value.contains(',') ? value.split(',').last : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF1F3F5),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class ChatImageGalleryPage extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const ChatImageGalleryPage({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  @override
  State<ChatImageGalleryPage> createState() => _ChatImageGalleryPageState();
}

class _ChatImageGalleryPageState extends State<ChatImageGalleryPage> {
  late final PageController _pageCtrl;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Widget _buildPageImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.contain);
    }
    if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    try {
      final raw = path.contains(',') ? path.split(',').last : path;
      final bytes = base64Decode(raw);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (_) {}
    return const Icon(Icons.broken_image, color: Colors.white, size: 48);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentPage + 1} / ${widget.paths.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: _buildPageImage(widget.paths[i]),
            ),
          );
        },
      ),
    );
  }
}

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
      MapEntry('all', 'Tất cả'),
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
                separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                separatorBuilder: (_, __) =>
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
