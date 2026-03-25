import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ChatMessage extends StatelessWidget {
  final Chatmsgobject msg;

  const ChatMessage({
    super.key,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    final hasMediaOrFileOrLink =
        msg.objtype() == ChatmsgObjtype.image ||
        msg.objtype() == ChatmsgObjtype.video ||
        msg.objtype() == ChatmsgObjtype.pdf ||
        msg.objtype() == ChatmsgObjtype.doc ||
        msg.objtype() == ChatmsgObjtype.excel ||
        msg.objtype() == ChatmsgObjtype.file ||
        msg.objtype() == ChatmsgObjtype.url;

    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      if (msg.replyMsg != null) _ReplyPreview(reply: msg.replyMsg!),

                      if (msg.objtype() == ChatmsgObjtype.image)
                        ChatMessageImage(
                          data: msg.strDataFile,
                          onTap: () => _handleImageTap(context),
                        ),

                      if (msg.objtype() == ChatmsgObjtype.video)
                        ChatMessageVideo(
                          data: msg.strDataFile,
                          onTap: () => _handleVideoTap(context),
                        ),

                      if (_isFileType(msg.objtype()))
                        ChatMessageFile(
                          msg: msg,
                          onTap: () => _handleFileTap(context),
                        ),

                      if (msg.objtype() == ChatmsgObjtype.url)
                        ChatMessageUrl(
                          url: msg.strDataFile,
                          rawText: msg.Note,
                          onTap: () => _handleOpenUrl(context, msg.strDataFile),
                        ),

                      if (msg.Note.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: hasMediaOrFileOrLink ? 8 : 0,
                          ),
                          child: ChatMessageText(
                            text: msg.Note,
                            isRecalled: msg.isRecalled,
                            onTapLink: (url) => _handleOpenUrl(context, url),
                          ),
                        ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (msg.isPinned) ...[
                            const Icon(Icons.push_pin, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _formatDate(msg.Send_Date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          if (msg.isMe) ...[
                            const SizedBox(width: 6),
                            _StatusIcon(status: msg.status),
                          ],
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

  void _handleLongPress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              if (msg.Note.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text("Sao chép tin nhắn"),
                  onTap: () async {
                    Navigator.pop(context);
                    await Clipboard.setData(ClipboardData(text: msg.Note));
                    _showSnackBar(context, "Đã sao chép nội dung");
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: const Text("Trả lời"),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, "Bạn chọn Trả lời");
                },
              ),
              ListTile(
                leading: Icon(
                  msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(msg.isPinned ? "Bỏ ghim" : "Ghim tin nhắn"),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(
                    context,
                    msg.isPinned ? "Bạn chọn Bỏ ghim" : "Bạn chọn Ghim tin nhắn",
                  );
                },
              ),
              if (msg.isMe)
                ListTile(
                  leading: const Icon(Icons.undo_outlined),
                  title: const Text("Thu hồi"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(context, "Bạn chọn Thu hồi");
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Xóa phía bạn"),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, "Bạn chọn Xóa phía bạn");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleOpenUrl(BuildContext context, String url) {
    if (url.trim().isEmpty) {
      _showSnackBar(context, "Liên kết không hợp lệ");
      return;
    }

    final finalUrl =
        url.startsWith("http://") || url.startsWith("https://")
            ? url
            : "https://$url";

    _showDialog(
      context: context,
      title: "Mở liên kết",
      content: finalUrl,
    );
  }

  void _handleFileTap(BuildContext context) {
    final filePath = msg.strDataFile?.toString() ?? "";
    _showDialog(
      context: context,
      title: "Mở tệp",
      content: filePath.isEmpty ? "Không có dữ liệu tệp" : filePath,
    );
  }

  void _handleVideoTap(BuildContext context) {
    final videoPath = msg.strDataFile?.toString() ?? "";
    _showDialog(
      context: context,
      title: "Phát video",
      content: videoPath.isEmpty ? "Không có dữ liệu video" : videoPath,
    );
  }

  void _handleImageTap(BuildContext context) {
    final imagePath = msg.strDataFile?.toString() ?? "";
    _showDialog(
      context: context,
      title: "Xem hình ảnh",
      content: imagePath.isEmpty ? "Không có dữ liệu hình ảnh" : imagePath,
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  void _showDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(content),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnackBar(context, "Đã sao chép");
                }
              },
              child: const Text("Sao chép"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final Chatmsgobject reply;

  const _ReplyPreview({required this.reply});

  @override
  Widget build(BuildContext context) {
    String preview = "Tin nhắn";

    if (reply.isRecalled) {
      preview = "Tin nhắn đã được thu hồi";
    } else if (reply.Note.trim().isNotEmpty) {
      preview = reply.Note.trim();
    } else {
      switch (reply.objtype()) {
        case ChatmsgObjtype.image:
          preview = "[Hình ảnh]";
          break;
        case ChatmsgObjtype.video:
          preview = "[Video]";
          break;
        case ChatmsgObjtype.pdf:
        case ChatmsgObjtype.doc:
        case ChatmsgObjtype.excel:
        case ChatmsgObjtype.file:
          preview = "[Tệp đính kèm]";
          break;
        case ChatmsgObjtype.url:
          preview = "[Liên kết]";
          break;
        default:
          preview = "Tin nhắn";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF00D287), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.isMe ? "Bạn" : reply.User_Name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case "sending":
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        );
      case "sent":
        return const Icon(Icons.check, size: 16, color: Colors.grey);
      case "received":
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case "read":
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }
}

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
      r'((https?:\/\/|www\.)[^\s]+)|(@[a-zA-Z0-9À-ỹ_]+)',
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

      if (token.startsWith("@")) {
        spans.add(TextSpan(text: token, style: styleMention));
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: styleLink,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final url =
                    token.startsWith("http://") || token.startsWith("https://")
                        ? token
                        : "https://$token";
                onTapLink?.call(url);
              },
          ),
        );
      }

      current = m.end;
    }

    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current), style: styleNormal));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class ChatMessageUrl extends StatelessWidget {
  final String? url;
  final String? rawText;
  final VoidCallback onTap;

  const ChatMessageUrl({
    super.key,
    required this.url,
    this.rawText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final display = (rawText != null && rawText!.trim().isNotEmpty)
        ? rawText!.trim()
        : (url ?? "");

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                display,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
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

  const ChatMessageFile({
    super.key,
    required this.msg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = _getFileName(msg.strDataFile?.toString() ?? "");
    final icon = _getFileIcon(msg.objtype());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName.isEmpty ? "Tệp đính kèm" : fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    if (path.trim().isEmpty) return "";
    final normalized = path.replaceAll("\\", "/");
    return normalized.split("/").last;
  }

  IconData _getFileIcon(ChatmsgObjtype type) {
    switch (type) {
      case ChatmsgObjtype.pdf:
        return Icons.picture_as_pdf_outlined;
      case ChatmsgObjtype.doc:
        return Icons.description_outlined;
      case ChatmsgObjtype.excel:
        return Icons.table_chart_outlined;
      default:
        return Icons.attach_file_outlined;
    }
  }
}

class ChatMessageVideo extends StatelessWidget {
  final String? data;
  final VoidCallback onTap;

  const ChatMessageVideo({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                (data ?? "").isEmpty ? "Video" : data!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageImage extends StatelessWidget {
  final String? data;
  final VoidCallback onTap;

  const ChatMessageImage({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = data?.trim() ?? "";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 180,
          width: double.infinity,
          color: Colors.black12,
          child: imagePath.isEmpty
              ? const Center(
                  child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 48, color: Colors.grey),
                        );
                      },
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 34),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}