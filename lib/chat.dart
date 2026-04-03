import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/Chatbox/chat_boxmsg.dart';
import 'package:flutter_chat/Component/Chatinput/chat_input.dart';
import 'package:flutter_chat/Component/Chatbox/chat_pin_message.dart';
import 'package:flutter_chat/Component/Chatinput/chat_reply_preview.dart';
import 'package:flutter_chat/Component/Services/chat_search.dart';
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
              onTapPinnedMessage: _scrollToMessage,
              onTogglePin: (msg) {
                _pinController.togglePin(
                  msg: msg,
                  msgsNotifier: _msgsNotifier,
                  onStateChanged: () => setState(() {}),
                );
              },
            ),
            // ================= CHAT LIST =================
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  CloseAll();
                },
                behavior: HitTestBehavior.translucent,
                child: ChatMessage(
                  msgsNotifier: _msgsNotifier,
                  pinController: _pinController,
                  itemScrollController: _itemScrollController,
                  inputFocusNode: _inputFocusNode,
                  onCloseOverlays: CloseAll,
                  onReplySelected: (msg) {
                    setState(() {
                      _replyingMsg = msg;
                    });
                  },
                  searchKeyword: _searchKeyword,
                  matchedMessageIds: _searchMatchedIds,
                  currentMatchedMessageId: _searchCurrentIndex >= 0
                      ? _searchMatchedIds[_searchCurrentIndex]
                      : null,
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

