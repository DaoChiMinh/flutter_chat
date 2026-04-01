import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ReplyInputPreview extends StatelessWidget {
  final Chatmsgobject msg;

  const ReplyInputPreview({super.key, required this.msg});

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
        if (type == ChatmsgObjtype.stiker)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ReplyPreview._buildStickerThumb(msg.Note),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "[Sticker]",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        if (type != ChatmsgObjtype.stiker)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.isMe ? "Bạn" : msg.Comment,
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
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThumb(ChatmsgObjtype type, Chatmsgobject msg) {
    final path = type == ChatmsgObjtype.url ? (msg.ImageUrl ?? "") : msg.file;

    Widget image;
    if (path.startsWith("http://") || path.startsWith("https://")) {
      image = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
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
      return Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam, color: Colors.grey, size: 18),
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

class ReplyPreview extends StatelessWidget {
  final Chatmsgobject reply;
  final VoidCallback? onTap;

  const ReplyPreview({super.key, required this.reply, this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = reply.objtype();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 45,
              decoration: BoxDecoration(
                color: reply.isMe ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.isMe ? "Bạn" : reply.Comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(child: _buildReplyContent(type)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReplyContent(ChatmsgObjtype type) {
    if (reply.isRecalled) {
      return const Text(
        "Tin nhắn đã được thu hồi",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.black54),
      );
    }

    switch (type) {
      case ChatmsgObjtype.image:
        return _replyMediaPreview(
          child: _buildImageThumb(reply.file),
          text: reply.Note.isNotEmpty ? reply.Note : "Hình ảnh",
        );

      case ChatmsgObjtype.video:
        return _replyMediaPreview(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.videocam, color: Colors.grey, size: 18),
          ),
          text: reply.Note.isNotEmpty ? reply.Note : "Video",
        );

      case ChatmsgObjtype.pdf:
      case ChatmsgObjtype.doc:
      case ChatmsgObjtype.excel:
      case ChatmsgObjtype.file:
        return _replyFilePreview(reply.file);

      case ChatmsgObjtype.url:
        return _replyLinkPreview();

      case ChatmsgObjtype.audio:
        return const Text(
          "Tin nhắn thoại",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        );

      case ChatmsgObjtype.tex:
      case ChatmsgObjtype.stiker:
        if (reply.Note.startsWith("http") ||
            (reply.Note.contains(".png") || reply.Note.contains(".jpg"))) {
          return _replyMediaPreview(
            child: _buildStickerThumb(reply.Note),
            text: "Sticker",
          );
        }
        return Text(
          reply.Note.isNotEmpty ? reply.Note : "Tin nhắn",
          style: TextStyle(color: Colors.blueGrey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
    
  Widget _replyMediaPreview({required Widget child, required String text}) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(width: 30, height: 36, child: child),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyFilePreview(String path) {
    final fileName = path.split('/').last;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.insert_drive_file, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyLinkPreview() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: reply.ImageUrl != null && reply.ImageUrl!.isNotEmpty
                  ? Image.network(reply.ImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withOpacity(0.15),
                      alignment: Alignment.center,
                      child: const Icon(Icons.link),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reply.titleUrl?.isNotEmpty == true
                  ? reply.titleUrl!
                  : (reply.file.isNotEmpty ? reply.file : "Liên kết"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumb(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image),
      ),
    );
  }

  static Widget _buildStickerThumb(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.emoji_emotions),
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.emoji_emotions),
      ),
    );
  }
}
