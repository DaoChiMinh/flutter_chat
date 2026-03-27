import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Component/chat_input.dart';
import 'package:flutter_chat/Module/chatData.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> {
  bool _showEmoji = false;
  bool _showGallery = false;
  bool _showAttachMenu = false; // ★ NEW
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  final _msgsNotifier = ValueNotifier<List<Chatmsgobject>>(
    List.from(Chatmsgobjects),
  );

  Chatmsgobject? _replyingMsg;
  void CloseAll() {
    setState(() {
      _showEmoji = false;
      _showGallery = false;
      _showAttachMenu = false; // ★
    });
  }

  void _scrollToMessage(String idMsg) {
    final key = _messageKeys[idMsg];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  void _handleReply(Chatmsgobject msg) {
    setState(() {
      _replyingMsg = msg;
    });
  }

  void _handleRecall(Chatmsgobject msg) {
    final list = [..._msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;

    list[i].isRecalled = true;
    list[i].Note = "Tin nhắn đã được thu hồi";
    list[i].strDataFile = [];
    list[i].strTypeFile = "";
    list[i].replyMsg = null;

    _msgsNotifier.value = list;
  }

  void _handleDelete(Chatmsgobject msg) {
    _msgsNotifier.value = _msgsNotifier.value
        .where((e) => e.IdMsg != msg.IdMsg)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Chat", style: TextStyle(color: Colors.white)),
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: const Color(0xffE4E8F3),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  CloseAll();
                },
                behavior: HitTestBehavior.translucent,
                child: ValueListenableBuilder<List<Chatmsgobject>>(
                  valueListenable: _msgsNotifier,
                  builder: (context, msgs, _) {
                    return ChatMessage(
                      msgs: msgs,
                      onReply: _handleReply,
                      onRecall: _handleRecall,
                      onDelete: _handleDelete,
                      onTapReplyPreview: _scrollToMessage,
                      scrollController: _scrollController,
                      messageKeys: _messageKeys,
                    );
                  },
                ),
              ),
            ),
            if (_replyingMsg != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(width: 3, height: 40, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: ReplyInputPreview(msg: _replyingMsg!)),
                    IconButton(
                      onPressed: () => setState(() => _replyingMsg = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ChatInput(
              showEmoji: _showEmoji,
              showGallery: _showGallery,
              showAttachMenu: _showAttachMenu, // ★ NEW
              onShowEmojiChanged: (v) => setState(() => _showEmoji = v),
              onShowGalleryChanged: (v) => setState(() => _showGallery = v),
              onShowAttachMenuChanged: (v) =>
                  setState(() => _showAttachMenu = v), // ★ NEW
              onSend: (msg) {
                //set id message
                msg.IdMsg = 'msg_${DateTime.now().microsecondsSinceEpoch}';
                msg.replyMsg = _replyingMsg;
                _msgsNotifier.value = [..._msgsNotifier.value, msg];
                setState(() {
                  _replyingMsg = null; // gửi xong ẩn ô reply
                });
                CloseAll();
              },
            ),
          ],
        ),
      ),
    );
  }
}
