
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';


class ChatMessage extends StatelessWidget {
  final Chatmsgobject msg;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onTapLink;
  final ValueChanged<Chatmsgobject>? onTapFile;
  final ValueChanged<String>? onTapVideo;
  final VoidCallback? onTapImage;

  const ChatMessage({
    super.key,
    required this.msg,
    this.onLongPress,
    this.onTapLink,
    this.onTapFile,
    this.onTapVideo,
    this.onTapImage,
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
      onLongPress: onLongPress,
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
                      // if (msg.objtype() == ChatmsgObjtype.video)
                      //   ChatMessageVideo(
                      //     data: msg.strDataFile,
                      //     onTap: () => onTapVideo(msg.strDataFile),
                      //   ),
                      // if (msg.objtype() == ChatmsgObjtype.image)
                      //   ChatMessageImage(
                      //     data: msg.strDataFile,
                      //     onTap: onTapImage,
                      //   ),
                      // if (_isFileType(msg.objtype()))
                      //   ChatMessageFile(
                      //     msg: msg,
                      //     onTap: () => onTapFile(msg),
                      //   ),
                      // if (msg.objtype() == ChatmsgObjtype.url)
                      //   ChatMessageUrl(
                      //     url: msg.strDataFile,
                      //     rawText: msg.Note,
                      //     onTap: () => onTapLink(msg.strDataFile),
                      //   ),
                      if (msg.Note.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: hasMediaOrFileOrLink ? 8 : 0,
                          ),
                          child: ChatMessageText(
                            text: msg.Note,
                            isRecalled: msg.isRecalled,
                            onTapLink: onTapLink,
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

    final styleLink = const TextStyle(
      fontSize: 15,
      color: Colors.blue,
      decoration: TextDecoration.underline,
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
    return RichText(text: TextSpan(children: spans));
  }
}