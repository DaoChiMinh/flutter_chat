import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Component/chat_input.dart';
import 'package:flutter_chat/Module/chatData.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> {
  bool _showEmoji = false;
  bool _showGallery = false;
  bool _showAttachMenu = false; // ★ NEW
  final ItemScrollController _itemScrollController = ItemScrollController();
  final currentUser =
      "Nguyen Quang Minh"; // user hiện tại, thay bằng account login thật
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

  void _handleReaction(Chatmsgobject msg, String emoji) {
    final list = [..._msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;
    list[i].setReaction(currentUser, emoji);
    _msgsNotifier.value = list;
  }

  void _handleRemoveMyReaction(Chatmsgobject msg) {
    final list = [..._msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;

    const currentUser = 'Nguyen Quang Minh';
    list[i].removeReactionOfUser(currentUser);
    _msgsNotifier.value = list;
  }

  void _scrollToMessage(String idMsg) {
    final list = _msgsNotifier.value;

    final index = list.indexWhere((e) => e.IdMsg == idMsg);
    if (index == -1) return;

    //đang để reverse list
    final reverseIndex = list.length - 1 - index;

    _itemScrollController.scrollTo(
      index: reverseIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
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
                      currentUser: currentUser,
                      onReply: _handleReply,
                      onRecall: _handleRecall,
                      onDelete: _handleDelete,
                      onTapReplyPreview: _scrollToMessage,
                      itemScrollController: _itemScrollController,
                      onReaction: _handleReaction,
                      onRemoveMyReaction: _handleRemoveMyReaction,
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  //if (!_itemScrollController.hasClients) return;
                  _itemScrollController.scrollTo(
                    index: 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
