import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
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
  final List<Chatmsgobject> msgs;
  final ValueChanged<Chatmsgobject>? onReply;
  final ValueChanged<Chatmsgobject>? onRecall;
  final ValueChanged<Chatmsgobject>? onDelete;
  final ValueChanged<String>? onTapReplyPreview;
  final ItemScrollController? itemScrollController;
  final Map<String, GlobalKey>? messageKeys;
  const ChatMessage({
    super.key,
    required this.msgs,
    this.onReply,
    this.onRecall,
    this.onDelete,
    this.onTapReplyPreview,
    this.itemScrollController,
    this.messageKeys,
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
          msg: msg,
          onReply: widget.onReply,
          onRecall: widget.onRecall,
          onDelete: widget.onDelete,
          onTapReplyPreview: widget.onTapReplyPreview,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Chatmsgobject msg;
  final ValueChanged<Chatmsgobject>? onReply;
  final ValueChanged<Chatmsgobject>? onRecall;
  final ValueChanged<Chatmsgobject>? onDelete;
  final ValueChanged<String>? onTapReplyPreview;

  const _MessageBubble({
    super.key,
    required this.msg,
    this.onDelete,
    this.onRecall,
    this.onReply,
    this.onTapReplyPreview,
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
      onLongPress: () => _showMessageActions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
                margin: const EdgeInsets.only(right: 6),
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
              child: Container(
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
                            onTap: () =>
                                onTapReplyPreview?.call(msg.replyMsg!.IdMsg),
                          ),
                        ),
                      // ── Image grid ──
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

                      // ── Sticker ──
                      if (type == ChatmsgObjtype.stiker)
                        Image.network(msg.Note, height: 120),

                      // ── Video grid ──
                      if (type == ChatmsgObjtype.video)
                        ChatMediaGrid(
                          files: msg.strDataFile,
                          type: ChatmsgObjtype.video,
                          onTapItem: (index) {
                            _openVideoPath(context, msg.strDataFile[index]);
                          },
                        ),

                      // ── File attachment ──
                      if (_isFileType(type))
                        ChatMessageFile(
                          msg: msg,
                          onTap: () => _openFile(context),
                        ),

                      // ── ★ Audio message ──
                      if (type == ChatmsgObjtype.audio)
                        ChatAudioBubble(
                          audioData: msg.file,
                          durationSeconds: msg.audioDurationSeconds > 0
                              ? msg.audioDurationSeconds
                              : null,
                        ),

                      // ── ★ URL: text ngoài URL trước ──
                      if (type == ChatmsgObjtype.url && extraText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChatMessageText(
                            text: extraText,
                            isRecalled: msg.isRecalled,
                            onTapLink: (url) => _openLink(context, url),
                          ),
                        ),

                      // ── ★ URL: link preview card ──
                      if (type == ChatmsgObjtype.url)
                        ChatMessageUrl(
                          msg: msg,
                          onTap: () => _openLink(context, msg.file),
                        ),

                      // ── Text message ──
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

                      // ── Timestamp + pin ──
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
                    ],
                  ),
                ),
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

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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

  void _showMessageActions(BuildContext context) async {
    final result = await showChatMessageActionMenu(context, msg: msg);
    if (result == null || !context.mounted) return;

    switch (result.type) {
      case 'reaction':
        // Xử lý reaction: result.reactionEmoji
        
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: msg.Note));
        _showSnackBar(context, 'Đã sao chép');
        break;
      case 'pin':
        msg.isPinned = !msg.isPinned;
        _showSnackBar(context, msg.isPinned ? 'Đã ghim' : 'Đã bỏ ghim');
        break;
      case 'reply':
        onReply?.call(msg);
        break;
      case 'forward':
      case 'recall':
        onRecall?.call(msg);
        break;
      case 'delete':
        onDelete?.call(msg);
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Các widget còn lại (giữ nguyên từ bản gốc)
// ═══════════════════════════════════════════════════════════

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
