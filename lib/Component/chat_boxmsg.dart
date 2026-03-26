import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatMessage extends StatefulWidget {
  final List<Chatmsgobject> msgs;

  const ChatMessage({super.key, required this.msgs});

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  final ScrollController scrollController = ScrollController();

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

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: widget.msgs.length,
      itemBuilder: (context, index) {
        final msg = widget.msgs[widget.msgs.length - 1 - index];
        return _MessageBubble(key: ValueKey(msg.IdMsg), msg: msg);
      },
    );
  }
}

// =========================
// MESSAGE BUBBLE
// =========================

class _MessageBubble extends StatelessWidget {
  final Chatmsgobject msg;

  const _MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();

    final hasMediaOrFileOrLink =
        type == ChatmsgObjtype.image ||
        type == ChatmsgObjtype.video ||
        type == ChatmsgObjtype.pdf ||
        type == ChatmsgObjtype.doc ||
        type == ChatmsgObjtype.excel ||
        type == ChatmsgObjtype.file ||
        type == ChatmsgObjtype.url;

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
                  color: msg.isMe ? const Color(0xFFD7FBE8) : Colors.white,
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
                      if (type == ChatmsgObjtype.image)
                        ChatMediaGrid(
                          files: msg.strDataFile,
                          type: ChatmsgObjtype.image,
                          onTapItem: (path) => _openImagePath(context, path),
                        ),

                      if (type == ChatmsgObjtype.video)
                        ChatMediaGrid(
                          files: msg.strDataFile,
                          type: ChatmsgObjtype.video,
                          onTapItem: (path) => _openVideoPath(context, path),
                        ),

                      if (_isFileType(type))
                        ChatMessageFile(
                          msg: msg,
                          onTap: () => _openFile(context),
                        ),

                      if (type == ChatmsgObjtype.url)
                        ChatMessageUrl(
                          url: msg.file,
                          rawText: msg.Note,
                          onTap: () => _openLink(context, msg.file),
                        ),

                      if (msg.Note.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: hasMediaOrFileOrLink ? 8 : 0,
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

  bool _isFileType(ChatmsgObjtype type) {
    return [
      ChatmsgObjtype.pdf,
      ChatmsgObjtype.doc,
      ChatmsgObjtype.excel,
      ChatmsgObjtype.file,
    ].contains(type);
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

  void _openImagePath(BuildContext context, String path) {
    if (path.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatImageViewerPage(path: path)),
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

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              if (msg.Note.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text(
                    "Trả lời",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () => Navigator.pop(context, "reply"),
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text(
                  "Sao chép nội dung",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                iconColor: Colors.blueGrey,
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: msg.Note));
                  _showSnackBar(context, "Đã sao chép nội dung");
                },
              ),
              ListTile(
                leading: Icon(
                  msg.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(
                  msg.isPinned ? "Bỏ ghim" : "Ghim",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                iconColor: Colors.cyan,
                onTap: () {
                  msg.isPinned = !msg.isPinned;
                  _showSnackBar(
                    context,
                    msg.isPinned ? "Đã ghim" : "Đã bỏ ghim",
                  );
                  Navigator.pop(context, "pin");
                },
              ),
              if (msg.objtype() == ChatmsgObjtype.url)
                ListTile(
                  leading: const Icon(Icons.link),
                  iconColor: Colors.blue,
                  title: const Text(
                    "Mở liên kết",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openLink(context, msg.file);
                  },
                ),
              if (msg.objtype() == ChatmsgObjtype.image)
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  iconColor: Colors.blue,
                  title: const Text(
                    "Xem ảnh",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final path = msg.strDataFile.isNotEmpty
                        ? msg.strDataFile.first
                        : msg.file;
                    _openImagePath(context, path);
                  },
                ),
              if (msg.objtype() == ChatmsgObjtype.video)
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  iconColor: Colors.blue,
                  title: const Text(
                    "Xem video",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final path = msg.strDataFile.isNotEmpty
                        ? msg.strDataFile.first
                        : msg.file;
                    _openVideoPath(context, path);
                  },
                ),
              if (_isFileType(msg.objtype()))
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  iconColor: Colors.blue,
                  title: const Text(
                    "Mở tệp",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openFile(context);
                  },
                ),
              if (msg.isMe && !msg.isRecalled)
                ListTile(
                  leading: const Icon(Icons.undo),
                  iconColor: Colors.orange,
                  title: const Text(
                    "Thu hồi",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () => Navigator.pop(context, "recall"),
                ),
              if (msg.isMe && !msg.isRecalled)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    "Xóa",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () => Navigator.pop(context, "delete"),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ChatMediaGrid extends StatelessWidget {
  final List<String> files;
  final ChatmsgObjtype type;
  final ValueChanged<String> onTapItem;

  const ChatMediaGrid({
    super.key,
    required this.files,
    required this.type,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final count = files.length;
    final maxWidth = MediaQuery.of(context).size.width * 0.68;
    const spacing = 4.0;

    if (count == 1) {
      return _item(files[0], maxWidth, maxWidth * 0.78);
    }

    if (count == 2) {
      final size = (maxWidth - spacing) / 2;
      return Row(
        children: [
          _item(files[0], size, size),
          const SizedBox(width: spacing),
          _item(files[1], size, size),
        ],
      );
    }

    if (count == 3) {
      final size = (maxWidth - spacing * 2) / 3;
      return Row(
        children: [
          _item(files[0], size, size),
          const SizedBox(width: spacing),
          _item(files[1], size, size),
          const SizedBox(width: spacing),
          _item(files[2], size, size),
        ],
      );
    }

    if (count == 4) {
      final size = (maxWidth - spacing) / 2;
      return Column(
        children: [
          Row(
            children: [
              _item(files[0], size, size),
              const SizedBox(width: spacing),
              _item(files[1], size, size),
            ],
          ),
          const SizedBox(height: spacing),
          Row(
            children: [
              _item(files[2], size, size),
              const SizedBox(width: spacing),
              _item(files[3], size, size),
            ],
          ),
        ],
      );
    }

    final size = (maxWidth - spacing * 2) / 3;
    final rows = <List<String>>[];
    for (int i = 0; i < files.length; i += 3) {
      rows.add(files.sublist(i, (i + 3 > files.length) ? files.length : i + 3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows.length, (rowIndex) {
        final row = rows[rowIndex];
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rows.length - 1 ? 0 : spacing),
          child: Row(
            children: List.generate(row.length, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == row.length - 1 ? 0 : spacing),
                child: _item(row[index], size, size),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _item(String path, double w, double h) {
    return GestureDetector(
      onTap: () => onTapItem(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: w,
          height: h,
          child: type == ChatmsgObjtype.video
              ? _buildVideoThumb()
              : _buildImage(path),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final bytes = _decodeBase64(path);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
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

  Widget _buildVideoThumb() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: const Color(0xFFE8ECEF),
          alignment: Alignment.center,
          child: const Icon(Icons.videocam, color: Colors.grey, size: 30),
        ),
        Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 34,
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF1F3F5),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final String path;
  final ChatmsgObjtype type;
  final VoidCallback onTap;

  const _MediaGridItem({
    required this.path,
    required this.type,
    required this.onTap,
  });

  bool get _isNetwork =>
      path.startsWith("http://") ||
      path.startsWith("https://") ||
      path.startsWith("ftp://");

  @override
  Widget build(BuildContext context) {
    if (type == ChatmsgObjtype.image) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildImage(),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoThumb(),
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(Icons.broken_image),
      );
    }

    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(Icons.broken_image),
      );
    }

    return _fallback(Icons.broken_image);
  }

  Widget _buildVideoThumb() {
    return Container(
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: const Icon(Icons.videocam, color: Colors.grey, size: 30),
    );
  }

  Widget _fallback(IconData icon) {
    return Container(
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey),
    );
  }
}

// class _ReplyPreview extends StatelessWidget {
//   final Chatmsgobject reply;

//   const _ReplyPreview({required this.reply});

//   @override
//   Widget build(BuildContext context) {
//     String preview = "Tin nhắn";
//     if (reply.isRecalled) {
//       preview = "Tin nhắn đã được thu hồi";
//     } else if (reply.Note.trim().isNotEmpty) {
//       preview = reply.Note.trim();
//     } else {
//       switch (reply.objtype()) {
//         case ChatmsgObjtype.image:
//           preview = "[Hình ảnh]";
//           break;
//         case ChatmsgObjtype.video:
//           preview = "[Video]";
//           break;
//         case ChatmsgObjtype.pdf:
//         case ChatmsgObjtype.doc:
//         case ChatmsgObjtype.excel:
//         case ChatmsgObjtype.file:
//           preview = "[Tệp đính kèm]";
//           break;
//         case ChatmsgObjtype.url:
//           preview = "[Liên kết]";
//           break;
//         default:
//           preview = "Tin nhắn";
//       }
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.only(left: 8),
//       decoration: const BoxDecoration(
//         border: Border(left: BorderSide(color: Color(0xFF00D287), width: 3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             reply.isMe ? "Bạn" : reply.User_Name,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
//           ),
//           Text(
//             preview,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatusIcon extends StatelessWidget {
//   final String status;

//   const _StatusIcon({required this.status});

//   @override
//   Widget build(BuildContext context) {
//     switch (status) {
//       case "sending":
//         return const SizedBox(
//           width: 14,
//           height: 14,
//           child: CircularProgressIndicator(strokeWidth: 1.6),
//         );
//       case "sent":
//         return const Icon(Icons.check, size: 16, color: Colors.grey);
//       case "received":
//         return const Icon(Icons.done_all, size: 16, color: Colors.grey);
//       case "read":
//         return const Icon(Icons.done_all, size: 16, color: Colors.blue);
//       default:
//         return const SizedBox.shrink();
//     }
//   }
// }

class ChatMessageText extends StatelessWidget {
  final String text;
  final bool isRecalled;
  final ValueChanged<String>? onTapLink;

  const ChatMessageText({
    super.key,
    required this.text,
    this.isRecalled = false,
    this.onTapLink,
  });

  bool _isProbablyUrl(String value) {
    final v = value.trim().toLowerCase();

    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.') ||
        RegExp(
          r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}([\/?#][^\s]*)?$',
          caseSensitive: false,
        ).hasMatch(v);
  }

  String _normalizeUrl(String value) {
    final v = value.trim();

    if (v.startsWith('http://') || v.startsWith('https://')) {
      return v;
    }
    return 'https://$v';
  }

  @override
  Widget build(BuildContext context) {
    final styleNormal = TextStyle(
      fontSize: 15,
      color: Colors.black87,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );

    final styleMention = TextStyle(
      fontSize: 15,
      color: Colors.blue.shade700,
      fontWeight: FontWeight.w600,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );

    final styleLink = TextStyle(
      fontSize: 15,
      color: Colors.blue.shade700,
      decoration: TextDecoration.underline,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );

    final tokenReg = RegExp(
      r'((https?:\/\/[^\s]+)|(www\.[^\s]+)|((?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[\/?#][^\s]*)?)|(@[a-zA-Z0-9À-ỹ_]+))',
      caseSensitive: false,
    );

    final matches = tokenReg.allMatches(text).toList(growable: false);

    if (matches.isEmpty) {
      return Text(text, style: styleNormal);
    }

    final spans = <InlineSpan>[];
    int current = 0;

    for (final m in matches) {
      if (m.start > current) {
        spans.add(
          TextSpan(text: text.substring(current, m.start), style: styleNormal),
        );
      }

      final token = text.substring(m.start, m.end);

      if (token.startsWith('@')) {
        spans.add(TextSpan(text: token, style: styleMention));
      } else if (_isProbablyUrl(token)) {
        spans.add(
          TextSpan(
            text: token,
            style: styleLink,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onTapLink?.call(_normalizeUrl(token)),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: styleNormal));
      }

      current = m.end;
    }

    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current), style: styleNormal));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class ChatMessageImage extends StatelessWidget {
  final String data;
  final VoidCallback? onTap;

  const ChatMessageImage({super.key, required this.data, this.onTap});

  bool get _isNetwork =>
      data.startsWith("http://") ||
      data.startsWith("https://") ||
      data.startsWith("ftp://");

  bool get _isBase64 {
    if (data.isEmpty) return false;
    if (_isNetwork) return false;
    if (File(data).existsSync()) return false;
    return data.startsWith("data:image/") || _looksLikeBase64(data);
  }

  bool _looksLikeBase64(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 40) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(cleaned);
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final raw = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isNetwork) {
      child = Image.network(
        data,
        fit: BoxFit.cover,
        height: 200,
        errorBuilder: (_, _, _) => _buildError(),
      );
    } else if (File(data).existsSync()) {
      child = Image.file(
        File(data),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildError(),
      );
    } else if (_isBase64) {
      final bytes = _decodeBase64(data);
      child = bytes == null
          ? _buildError()
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildError(),
            );
    } else {
      child = _buildError();
    }

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 240,
          maxHeight: 260,
          minHeight: 120,
        ),
        child: child,
      ),
    );

    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }

  Widget _buildError() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class ChatMessageUrl extends StatelessWidget {
  final String url;
  final String rawText;
  final VoidCallback onTap;

  const ChatMessageUrl({
    super.key,
    required this.url,
    required this.rawText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E5EA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rawText.trim().isNotEmpty)
                    Text(
                      rawText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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
}

class ChatMessageFile extends StatelessWidget {
  final Chatmsgobject msg;
  final VoidCallback onTap;

  const ChatMessageFile({super.key, required this.msg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.insert_drive_file_outlined;
    Color iconColor = Colors.grey;

    switch (msg.strTypeFile.toLowerCase()) {
      case "pdf":
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case "doc":
      case "docx":
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case "xls":
      case "xlsx":
        icon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case "ppt":
      case "pptx":
        icon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E4E4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.Note.isNotEmpty ? msg.Note : "Tệp đính kèm",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    msg.strTypeFile.isEmpty
                        ? "FILE"
                        : msg.strTypeFile.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ChatMessageVideo extends StatelessWidget {
  final String data;
  final VoidCallback onTap;
  final String durationText;
  final ImageProvider? thumbnail;

  const ChatMessageVideo({
    super.key,
    required this.data,
    required this.onTap,
    this.durationText = "Video",
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 220,
              child: thumbnail != null
                  ? Image(
                      image: thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(),
                    )
                  : _fallback(),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: const Icon(Icons.videocam, color: Colors.grey, size: 36),
    );
  }
}

class ChatVideoViewerPage extends StatefulWidget {
  final String path;

  const ChatVideoViewerPage({super.key, required this.path});

  @override
  State<ChatVideoViewerPage> createState() => _ChatVideoViewerPageState();
}

class _ChatVideoViewerPageState extends State<ChatVideoViewerPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isDragging = false;
  Timer? _hideTimer;

  bool get _isNetwork {
    final value = widget.path.trim();
    return value.startsWith("http://") || value.startsWith("https://");
  }

  bool get _isBase64 {
    final value = widget.path.trim();
    if (value.isEmpty) return false;
    if (_isNetwork) return false;
    if (value.startsWith("data:video/")) return true;
    if (value.length < 100) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final source = widget.path.trim();
      if (source.isEmpty) {
        throw Exception("Empty video source");
      }

      if (_isNetwork) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(source));
      } else if (_isBase64) {
        final file = await _writeTempVideo(source);
        _controller = VideoPlayerController.file(file);
      } else {
        _controller = VideoPlayerController.file(File(source));
      }

      await _controller!.initialize();
      _controller!.addListener(_onTick);

      setState(() {
        _ready = true;
        _hasError = false;
      });

      _startAutoHide();
    } catch (_) {
      setState(() {
        _ready = false;
        _hasError = true;
      });
    }
  }

  Future<File> _writeTempVideo(String base64Value) async {
    final raw = base64Value.contains(',')
        ? base64Value.substring(base64Value.indexOf(',') + 1)
        : base64Value;

    final normalized = raw.replaceAll('\n', '').replaceAll('\r', '');
    final hash = normalized.hashCode;
    final file = File('${Directory.systemTemp.path}/chat_video_$hash.mp4');

    if (await file.exists()) return file;

    final bytes = base64Decode(normalized);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _onTick() {
    if (mounted && !_isDragging) {
      setState(() {});
    }
  }

  void _startAutoHide() {
    _hideTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        _showControls = true;
      });
      _hideTimer?.cancel();
    } else {
      controller.play();
      setState(() {
        _showControls = true;
      });
      _startAutoHide();
    }
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _controller;
    if (controller == null) return;

    final current = controller.value.position;
    final total = controller.value.duration;

    var target = current + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;

    await controller.seekTo(target);
    setState(() {
      _showControls = true;
    });
    _startAutoHide();
  }

  String _format(Duration d) {
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Xem video"),
      ),
      body: Center(
        child: _hasError
            ? const Text(
                "Không mở được video",
                style: TextStyle(color: Colors.white),
              )
            : !_ready || controller == null
            ? const CircularProgressIndicator()
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                  if (_showControls) _startAutoHide();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                    if (_showControls)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: Column(
                            children: [
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => _seekRelative(
                                      const Duration(seconds: -10),
                                    ),
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: _togglePlayPause,
                                    icon: Icon(
                                      controller.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 68,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () => _seekRelative(
                                      const Duration(seconds: 10),
                                    ),
                                    icon: const Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _format(controller.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 2.4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                        ),
                                        child: Slider(
                                          value:
                                              controller
                                                      .value
                                                      .duration
                                                      .inMilliseconds <=
                                                  0
                                              ? 0
                                              : controller
                                                    .value
                                                    .position
                                                    .inMilliseconds
                                                    .clamp(
                                                      0,
                                                      controller
                                                          .value
                                                          .duration
                                                          .inMilliseconds,
                                                    )
                                                    .toDouble(),
                                          min: 0,
                                          max:
                                              controller
                                                      .value
                                                      .duration
                                                      .inMilliseconds <=
                                                  0
                                              ? 1
                                              : controller
                                                    .value
                                                    .duration
                                                    .inMilliseconds
                                                    .toDouble(),
                                          onChangeStart: (_) {
                                            _isDragging = true;
                                            _hideTimer?.cancel();
                                          },
                                          onChanged: (value) async {
                                            final target = Duration(
                                              milliseconds: value.toInt(),
                                            );
                                            await controller.seekTo(target);
                                            if (mounted) setState(() {});
                                          },
                                          onChangeEnd: (_) {
                                            _isDragging = false;
                                            _startAutoHide();
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _format(controller.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ChatWebViewerPage extends StatefulWidget {
  final String url;

  const ChatWebViewerPage({super.key, required this.url});

  @override
  State<ChatWebViewerPage> createState() => _ChatWebViewerPageState();
}

class _ChatWebViewerPageState extends State<ChatWebViewerPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trình duyệt'),
        actions: [
          IconButton(
            onPressed: () async {
              final uri = Uri.tryParse(widget.url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class ChatImageViewerPage extends StatelessWidget {
  final String path;

  const ChatImageViewerPage({super.key, required this.path});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  bool get _isBase64 {
    if (path.isEmpty) return false;
    if (_isNetwork) return false;
    if (File(path).existsSync()) return false;
    return path.startsWith("data:image/") ||
        RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(path.trim());
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final raw = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_isNetwork) {
      imageWidget = Image.network(path, fit: BoxFit.contain);
    } else if (File(path).existsSync()) {
      imageWidget = Image.file(File(path), fit: BoxFit.contain);
    } else if (_isBase64) {
      final bytes = _decodeBase64(path);
      imageWidget = bytes == null
          ? const Icon(Icons.broken_image, color: Colors.white, size: 48)
          : Image.memory(bytes, fit: BoxFit.contain);
    } else {
      imageWidget = const Icon(
        Icons.broken_image,
        color: Colors.white,
        size: 48,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hình ảnh')),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: imageWidget,
        ),
      ),
    );
  }
}

class ChatPdfViewerPage extends StatelessWidget {
  final String path;

  const ChatPdfViewerPage({super.key, required this.path});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF')),
      body: _isNetwork
          ? SfPdfViewer.network(path)
          : SfPdfViewer.file(File(path)),
    );
  }
}

class ChatDocViewerPage extends StatelessWidget {
  final String path;
  final String title;

  const ChatDocViewerPage({super.key, required this.path, required this.title});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _open(BuildContext context) async {
    if (_isNetwork) {
      final googleViewerUrl =
          'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(path)}';

      final uri = Uri.parse(googleViewerUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else {
      final result = await OpenFilex.open(path);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở tệp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Mở tệp'),
        ),
      ),
    );
  }
}

class ChatUnsupportedFilePage extends StatelessWidget {
  final String path;
  final String title;

  const ChatUnsupportedFilePage({
    super.key,
    required this.path,
    required this.title,
  });

  Future<void> _openExternal(BuildContext context) async {
    final result = await OpenFilex.open(path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _openExternal(context),
          icon: const Icon(Icons.insert_drive_file_outlined),
          label: const Text('Mở bằng ứng dụng khác'),
        ),
      ),
    );
  }
}
