import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class _ReplyInputPreview extends StatelessWidget {
  final Chatmsgobject msg;

  const _ReplyInputPreview({required this.msg});

  @override
  Widget build(BuildContext context) {
    final type = msg.objtype();

    return Row(
      children: [
        if (type == ChatmsgObjtype.image ||
            type == ChatmsgObjtype.video ||
            type == ChatmsgObjtype.url)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: _buildThumb(type, msg),
            ),
          )
        else if (type == ChatmsgObjtype.file ||
            type == ChatmsgObjtype.pdf ||
            type == ChatmsgObjtype.doc ||
            type == ChatmsgObjtype.excel)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.insert_drive_file),
          ),

        if (type != ChatmsgObjtype.tex) const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.isMe ? "Bạn" : msg.User_Name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _replyText(msg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumb(ChatmsgObjtype type, Chatmsgobject msg) {
    final path = type == ChatmsgObjtype.url
        ? (msg.ImageUrl ?? "")
        : msg.file;

    Widget image;
    if (path.startsWith("http://") || path.startsWith("https://")) {
      image = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.image),
        ),
      );
    } else {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.image),
        ),
      );
    }

    if (type == ChatmsgObjtype.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          image,
          Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const Icon(Icons.play_circle_fill, color: Colors.white),
          ),
        ],
      );
    }

    return image;
  }

  String _replyText(Chatmsgobject msg) {
    if (msg.Note.trim().isNotEmpty) return msg.Note.trim();

    switch (msg.objtype()) {
      case ChatmsgObjtype.image:
        return "Hình ảnh";
      case ChatmsgObjtype.video:
        return "Video";
      case ChatmsgObjtype.url:
        return msg.titleUrl?.isNotEmpty == true ? msg.titleUrl! : "Liên kết";
      case ChatmsgObjtype.file:
      case ChatmsgObjtype.pdf:
      case ChatmsgObjtype.doc:
      case ChatmsgObjtype.excel:
        return msg.file.split('/').last;
      default:
        return "Tin nhắn";
    }
  }
}