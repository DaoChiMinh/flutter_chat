import 'package:flutter_chat/chat_frame.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatMessageController {
  void Function(String messageId)? _scrollTo;

  void attachScroll(void Function(String messageId) fn) => _scrollTo = fn;

  void detach() => _scrollTo = null;

  void scrollToMessage(String messageId) => _scrollTo?.call(messageId);
}


class ChatMessage extends StatefulWidget {
  final String currentUser = "Nguyen Quang Minh";
  final bool showPinnedBar;
  final VoidCallback? onCloseOverlays;
  final FocusNode? inputFocusNode;
  const ChatMessage({
    super.key,
    this.showPinnedBar = true,
    this.onCloseOverlays,
    this.inputFocusNode,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late final ChatPinController _pinController;
  late final ItemScrollController _itemScrollController;
  ValueNotifier<List<Chatmsgobject>>? _msgsNv;
  ChatMessageController? _scrollController;
  int _prevMsgCount = 0;
  String? _longPressedApproveMsgId;

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleApproveStatus(Chatmsgobject msg, String status) {
    final list = [..._msgsNv!.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;
    list[i].approvedStatus = status;
    _msgsNv!.value = list;
  }

  void _handlePin(Chatmsgobject msg) {
    _pinController.togglePin(
      msg: msg,
      msgsNotifier: _msgsNv!,
      onStateChanged: () => setState(() {}),
    );
  }

  void _handleReaction(Chatmsgobject msg, String emoji) {
    final list = [..._msgsNv!.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;
    list[i].setReaction(widget.currentUser, emoji);
    _msgsNv!.value = list;
  }

  void _handleRemoveMyReaction(Chatmsgobject msg) {
    final list = [..._msgsNv!.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;
    list[i].removeReactionOfUser(widget.currentUser);
    _msgsNv!.value = list;
  }

  void _handleReply(Chatmsgobject msg) {
    final session = ChatSessionScopeData.of(context);
    session.replyingToNotifier.value = msg;
    widget.onCloseOverlays?.call();
    Future.delayed(const Duration(milliseconds: 50), () {
      widget.inputFocusNode?.requestFocus();
    });
  }

  void _handleRecall(Chatmsgobject msg) {
    final list = [..._msgsNv!.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;
    list[i].isRecalled = true;
    list[i].Note = "Tin nhắn đã được thu hồi";
    list[i].strDataFile = [];
    list[i].strTypeFile = "";
    list[i].replyMsg = null;
    _msgsNv!.value = list;
  }

  void _handleDelete(Chatmsgobject msg) {
    _msgsNv!.value = _msgsNv!.value.where((e) => e.IdMsg != msg.IdMsg).toList();
    _pinController.removeDeletedMessage(
      msg.IdMsg,
      onStateChanged: () => setState(() {}),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleForward(Chatmsgobject msg) {
    if (msg.isRecalled) return;
    debugPrint("Forward message: ${msg.IdMsg}");
  }

  void _scrollToMessage(String idMsg) {
    final list = _msgsNv!.value;
    final index = list.indexWhere((e) => e.IdMsg == idMsg);
    if (index == -1) return;
    final reverseIndex = list.length - 1 - index;
    _itemScrollController.scrollTo(
      index: reverseIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    if (_msgsNv!.value.isEmpty) return;
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onMsgsLengthChanged() {
    final nv = _msgsNv;
    if (nv == null) return;
    final next = nv.value.length;
    if (next > _prevMsgCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }
    _prevMsgCount = next;
  }

  @override
  void initState() {
    super.initState();
    _pinController = ChatPinController();
    _itemScrollController = ItemScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = ChatSessionScopeData.of(context);
    if (_msgsNv == null) {
      _msgsNv = session.msgsNotifier;
      _scrollController = session.messageController;
      _prevMsgCount = _msgsNv!.value.length;
      _msgsNv!.addListener(_onMsgsLengthChanged);
      _scrollController!.attachScroll(_scrollToMessage);
    }
  }

  @override
  void dispose() {
    _msgsNv?.removeListener(_onMsgsLengthChanged);
    _scrollController?.detach();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ChatSessionScopeData.of(context);
    return ValueListenableBuilder<List<Chatmsgobject>>(
      valueListenable: session.msgsNotifier,
      builder: (context, msgs, _) {
        return ValueListenableBuilder<ChatSearchHighlight>(
          valueListenable: session.searchHighlightNotifier,
          builder: (context, highlight, _) {
            final empty = msgs.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        "Hãy khởi đầu cuộc trò chuyện bằng một tin nhắn 😀",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final originalIndex = msgs.length - 1 - index;
                          final msg = msgs[originalIndex];

                          final Chatmsgobject? prevMsgInTime = originalIndex > 0
                              ? msgs[originalIndex - 1]
                              : null;

                          final bool showDateHeader =
                              prevMsgInTime == null ||
                              !_isSameDay(
                                msg.Send_Date,
                                prevMsgInTime.Send_Date,
                              );
                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        formatTime(msg.Send_Date, 'dd/MM/yyyy'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              MessageBubble(
                                key: ValueKey(msg.IdMsg),
                                currentUser: widget.currentUser,
                                msg: msg,
                                onReply: _handleReply,
                                onRecall: _handleRecall,
                                onDelete: _handleDelete,
                                onTapReplyPreview: _scrollToMessage,
                                onReaction: _handleReaction,
                                onRemoveMyReaction: _handleRemoveMyReaction,
                                onPin: _handlePin,
                                onForward: _handleForward,
                                onApproveStatus: (targetMsg, status) {
                                  _handleApproveStatus(targetMsg, status);
                                  setState(() {
                                    _longPressedApproveMsgId = null;
                                  });
                                },
                                showApproveActions:
                                    _longPressedApproveMsgId == msg.IdMsg,
                                onToggleApproveActions: () {
                                  setState(() {
                                    if (_longPressedApproveMsgId == msg.IdMsg) {
                                      _longPressedApproveMsgId = null;
                                    } else {
                                      _longPressedApproveMsgId = msg.IdMsg;
                                    }
                                  });
                                },
                                searchKeyword: highlight.keyword,
                                matchedMessageIds: highlight.matchedMessageIds,
                                currentMatchedMessageId:
                                    highlight.currentMatchedMessageId,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showPinnedBar)
                  PinnedMessageBar(
                    pinController: _pinController,
                    msgsNotifier: session.msgsNotifier,
                    onScrollToMessage: _scrollToMessage,
                    onTogglePin: _handlePin,
                  ),
                empty,
              ],
            );
          },
        );
      },
    );
  }
}

