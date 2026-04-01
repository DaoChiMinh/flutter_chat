import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Component/chat_input.dart';
import 'package:flutter_chat/Component/chat_pin_message.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
import 'package:flutter_chat/Component/chat_search.dart';
import 'package:flutter_chat/Module/chatData.dart';
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
  bool _showAttachMenu = false;
  final FocusNode _inputFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final String currentUser = "Nguyen Quang Minh";

  final ValueNotifier<List<Chatmsgobject>> _msgsNotifier =
      ValueNotifier<List<Chatmsgobject>>(List.from(Chatmsgobjects));

  Chatmsgobject? _replyingMsg;
  final ChatPinController _pinController = ChatPinController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchMatchedIds = [];
  int _searchCurrentIndex = -1;
  String _searchKeyword = '';

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _pinController.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void CloseAll() {
    setState(() {
      _showEmoji = false;
      _showGallery = false;
      _showAttachMenu = false;
    });
  }

  //xử lí duyệt
  void _handleApproveStatus(Chatmsgobject msg, String status) {
    final list = [..._msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;

    list[i].approvedStatus = status;
    _msgsNotifier.value = list;
  }

  // ================= PIN =================
  void _handlePin(Chatmsgobject msg) {
    _pinController.togglePin(
      msg: msg,
      msgsNotifier: _msgsNotifier,
      onStateChanged: () => setState(() {}),
    );
  }

  // ================= REACTION =================
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

    list[i].removeReactionOfUser(currentUser);
    _msgsNotifier.value = list;
  }

  // ================= SCROLL =================
  void _scrollToMessage(String idMsg) {
    final list = _msgsNotifier.value;
    final index = list.indexWhere((e) => e.IdMsg == idMsg);
    if (index == -1) return;

    final reverseIndex = list.length - 1 - index;

    _itemScrollController.scrollTo(
      index: reverseIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  // ================= REPLY =================
  void _handleReply(Chatmsgobject msg) {
    setState(() {
      _replyingMsg = msg;
    });
    CloseAll();
    Future.delayed(const Duration(milliseconds: 50), () {
      _inputFocusNode.requestFocus();
    });
  }

  // ================= RECALL =================
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

  // ================= DELETE =================
  void _handleDelete(Chatmsgobject msg) {
    _msgsNotifier.value = _msgsNotifier.value
        .where((e) => e.IdMsg != msg.IdMsg)
        .toList();

    _pinController.removeDeletedMessage(
      msg.IdMsg,
      onStateChanged: () => setState(() {}),
    );
  }

  // ================= FORWARD =================
  void _handleForward(Chatmsgobject msg) {
    if (msg.isRecalled) {
      return;
    }
    debugPrint("Forward message: ${msg.IdMsg}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatSearch(
        messages: _msgsNotifier.value,
        onJumpToMessage: _scrollToMessage,
        onCloseSearch: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onSearchChanged: (keyword, matchedIds, currentMatchedId) {
          setState(() {
            _searchKeyword = keyword;
            _searchMatchedIds = matchedIds;
            _searchCurrentIndex = currentMatchedId == null
                ? -1
                : matchedIds.indexOf(currentMatchedId);
          });
        },
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: const Color(0xffE4E8F3),
        child: Column(
          children: [
            // ================= PIN HEADER =================
            PinnedMessageBar(
              pinController: _pinController,
              msgsNotifier: _msgsNotifier,
              onRefresh: () => setState(() {}),
              onTapPinnedMessage: _scrollToMessage,
              onTogglePin: _handlePin,
            ),
            // ================= CHAT LIST =================
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
                      onPin: _handlePin,
                      onForward: _handleForward,
                      onApproveStatus: _handleApproveStatus,
                      searchKeyword: _searchKeyword,
                      matchedMessageIds: _searchMatchedIds,
                      currentMatchedMessageId: _searchCurrentIndex >= 0
                          ? _searchMatchedIds[_searchCurrentIndex]
                          : null,
                    );
                  },
                ),
              ),
            ),

            // ================= REPLY PREVIEW =================
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

            // ================= INPUT =================
            ChatInput(
              externalFocusNode: _inputFocusNode,
              showEmoji: _showEmoji,
              showGallery: _showGallery,
              showAttachMenu: _showAttachMenu,
              onShowEmojiChanged: (v) => setState(() => _showEmoji = v),
              onShowGalleryChanged: (v) => setState(() => _showGallery = v),
              onShowAttachMenuChanged: (v) =>
                  setState(() => _showAttachMenu = v),
              onSend: (msg) {
                msg.IdMsg = 'msg_${DateTime.now().microsecondsSinceEpoch}';
                msg.replyMsg = _replyingMsg;
                _msgsNotifier.value = [..._msgsNotifier.value, msg];

                setState(() {
                  _replyingMsg = null;
                });

                CloseAll();

                WidgetsBinding.instance.addPostFrameCallback((_) {
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
