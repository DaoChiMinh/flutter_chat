import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Component/chat_input.dart';
import 'package:flutter_chat/Component/chat_reply_preview.dart';
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

  final ValueNotifier<List<String>> _pinnedIdsNotifier =
      ValueNotifier<List<String>>([]);

  bool _showPinnedPanel = false;
  Chatmsgobject? _replyingMsg;

  void CloseAll() {
    setState(() {
      _showEmoji = false;
      _showGallery = false;
      _showAttachMenu = false;
    });
  }

  // ================= PIN =================
  void _handlePin(Chatmsgobject msg) {
    final list = [..._msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;

    list[i].isPinned = !list[i].isPinned;
    _msgsNotifier.value = list;

    final pinned = [..._pinnedIdsNotifier.value];

    if (list[i].isPinned) {
      if (!pinned.contains(msg.IdMsg)) {
        pinned.insert(0, msg.IdMsg);
      }
    } else {
      pinned.remove(msg.IdMsg);
      if (pinned.isEmpty) {
        _showPinnedPanel = false;
      }
    }

    _pinnedIdsNotifier.value = pinned;
    setState(() {});
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

    final pinned = [..._pinnedIdsNotifier.value]..remove(msg.IdMsg);
    _pinnedIdsNotifier.value = pinned;
    if (pinned.isEmpty && _showPinnedPanel) {
      setState(() {
        _showPinnedPanel = false;
      });
    }
  }

  List<Chatmsgobject> _getPinnedMsgs(
    List<String> pinnedIds,
    List<Chatmsgobject> msgs,
  ) {
    return pinnedIds
        .map(
          (id) => msgs.where((e) => e.IdMsg == id).isNotEmpty
              ? msgs.firstWhere((e) => e.IdMsg == id)
              : null,
        )
        .whereType<Chatmsgobject>()
        .toList();
  }

  String _pinnedPreview(Chatmsgobject m) {
    if (m.Note.trim().isNotEmpty) return m.Note.trim();

    switch (m.objtype()) {
      case ChatmsgObjtype.image:
        return '[Hình ảnh]';
      case ChatmsgObjtype.video:
        return '[Video]';
      case ChatmsgObjtype.audio:
        return '[Tin nhắn thoại]';
      case ChatmsgObjtype.pdf:
        return '[PDF]';
      case ChatmsgObjtype.doc:
        return '[Tài liệu]';
      case ChatmsgObjtype.excel:
        return '[Bảng tính]';
      case ChatmsgObjtype.file:
        return '[Tệp đính kèm]';
      case ChatmsgObjtype.url:
        return '[Liên kết]';
      case ChatmsgObjtype.stiker:
        return '[Sticker]';
      default:
        return '[Tin nhắn]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Chat", style: TextStyle(color: Colors.white)),
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: const Color(0xffE4E8F3),
        child: Column(
          children: [
            // ================= PIN HEADER =================
            ValueListenableBuilder<List<String>>(
              valueListenable: _pinnedIdsNotifier,
              builder: (context, pinnedIds, _) {
                if (pinnedIds.isEmpty) return const SizedBox.shrink();

                final msgs = _msgsNotifier.value;
                final pinnedMsgs = _getPinnedMsgs(pinnedIds, msgs);
                if (pinnedMsgs.isEmpty) return const SizedBox.shrink();

                final first = pinnedMsgs.first;
                final remain = pinnedMsgs.length - 1;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.fromLTRB(
                    8,
                    6,
                    8,
                    _showPinnedPanel ? 0 : 6,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: _showPinnedPanel ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: _showPinnedPanel
                        ? const BorderRadius.vertical(top: Radius.circular(14))
                        : BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF2DA1F8),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _scrollToMessage(first.IdMsg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pinnedPreview(first),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _showPinnedPanel ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!_showPinnedPanel) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Tin nhắn của ${first.User_Name.isNotEmpty ? first.User_Name : first.Comment}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (remain > 0)
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              _showPinnedPanel = !_showPinnedPanel;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFBFC4CC),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                if (remain > 0)
                                  Text(
                                    '+$remain',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6E7682),
                                    ),
                                  ),
                                if (remain > 0) const SizedBox(width: 4),
                                Icon(
                                  _showPinnedPanel
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF6E7682),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ================= PIN DROPDOWN =================
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _showPinnedPanel
                  ? ValueListenableBuilder<List<String>>(
                      valueListenable: _pinnedIdsNotifier,
                      builder: (context, pinnedIds, _) {
                        final msgs = _msgsNotifier.value;
                        final pinnedMsgs = _getPinnedMsgs(pinnedIds, msgs);
                        if (pinnedMsgs.isEmpty) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: pinnedMsgs.map((m) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _showPinnedPanel = false;
                                  });
                                  Future.microtask(
                                    () => _scrollToMessage(m.IdMsg),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFF0F0F0),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Color(0xFF2DA1F8),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _pinnedPreview(m),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tin nhắn của ${m.User_Name.isNotEmpty ? m.User_Name : m.Comment}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
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
