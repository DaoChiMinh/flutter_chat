import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ChatPinController {
  final ValueNotifier<List<String>> pinnedIdsNotifier =
      ValueNotifier<List<String>>([]);

  bool showPinnedPanel = false;

  void dispose() {
    pinnedIdsNotifier.dispose();
  }

  void togglePin({
    required Chatmsgobject msg,
    required ValueNotifier<List<Chatmsgobject>> msgsNotifier,
    VoidCallback? onStateChanged,
  }) {
    final list = [...msgsNotifier.value];
    final i = list.indexWhere((e) => e.IdMsg == msg.IdMsg);
    if (i == -1) return;

    list[i].isPinned = !list[i].isPinned;
    msgsNotifier.value = list;

    final pinned = [...pinnedIdsNotifier.value];

    if (list[i].isPinned) {
      if (!pinned.contains(msg.IdMsg)) {
        pinned.insert(0, msg.IdMsg);
      }
    } else {
      pinned.remove(msg.IdMsg);
      if (pinned.isEmpty) {
        showPinnedPanel = false;
      }
    }

    pinnedIdsNotifier.value = pinned;
    onStateChanged?.call();
  }

  void removeDeletedMessage(String msgId, {VoidCallback? onStateChanged}) {
    final pinned = [...pinnedIdsNotifier.value]..remove(msgId);
    pinnedIdsNotifier.value = pinned;

    if (pinned.isEmpty && showPinnedPanel) {
      showPinnedPanel = false;
      onStateChanged?.call();
    }
  }

  List<Chatmsgobject> getPinnedMessages({
    required List<String> pinnedIds,
    required List<Chatmsgobject> msgs,
  }) {
    return pinnedIds
        .map(
          (id) => msgs.cast<Chatmsgobject?>().firstWhere(
            (e) => e?.IdMsg == id,
            orElse: () => null,
          ),
        )
        .whereType<Chatmsgobject>()
        .toList();
  }

  String pinnedPreview(Chatmsgobject m) {
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
}

class PinnedMessageBar extends StatefulWidget {
  final ChatPinController pinController;
  final ValueNotifier<List<Chatmsgobject>> msgsNotifier;
  final ValueChanged<String> onScrollToMessage;
  final ValueChanged<Chatmsgobject> onTogglePin;

  const PinnedMessageBar({
    super.key,
    required this.pinController,
    required this.msgsNotifier,
    required this.onScrollToMessage,
    required this.onTogglePin,
  });

  @override
  State<PinnedMessageBar> createState() => _PinnedMessageBarState();
}

class _PinnedMessageBarState extends State<PinnedMessageBar> {
  void _togglePanel() {
    setState(() {
      widget.pinController.showPinnedPanel =
          !widget.pinController.showPinnedPanel;
    });
  }

  void _closePanel() {
    if (!widget.pinController.showPinnedPanel) return;
    setState(() {
      widget.pinController.showPinnedPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<List<String>>(
          valueListenable: widget.pinController.pinnedIdsNotifier,
          builder: (context, pinnedIds, _) {
            if (pinnedIds.isEmpty) {
              return const SizedBox.shrink();
            }

            final msgs = widget.msgsNotifier.value;
            final pinnedMsgs = widget.pinController.getPinnedMessages(
              pinnedIds: pinnedIds,
              msgs: msgs,
            );

            if (pinnedMsgs.isEmpty) {
              return const SizedBox.shrink();
            }

            final first = pinnedMsgs.first;
            final remain = pinnedMsgs.length - 1;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              margin: EdgeInsets.fromLTRB(
                8,
                6,
                8,
                widget.pinController.showPinnedPanel ? 0 : 6,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: widget.pinController.showPinnedPanel ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: widget.pinController.showPinnedPanel
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
                      onTap: () => widget.onScrollToMessage(first.IdMsg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pinController.pinnedPreview(first),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.pinController.showPinnedPanel
                                  ? 15
                                  : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.pinController.showPinnedPanel) ...[
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

                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _togglePanel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBFC4CC)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          if (remain > 0) ...[
                            Text(
                              '+$remain',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6E7682),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Icon(
                            widget.pinController.showPinnedPanel
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
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: widget.pinController.showPinnedPanel
              ? ValueListenableBuilder<List<String>>(
                  valueListenable: widget.pinController.pinnedIdsNotifier,
                  builder: (context, pinnedIds, _) {
                    final msgs = widget.msgsNotifier.value;
                    final pinnedMsgs = widget.pinController.getPinnedMessages(
                      pinnedIds: pinnedIds,
                      msgs: msgs,
                    );

                    if (pinnedMsgs.isEmpty) {
                      return const SizedBox.shrink();
                    }

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
                        children: List.generate(pinnedMsgs.length, (index) {
                          final m = pinnedMsgs[index];
                          final isLast = index == pinnedMsgs.length - 1;

                          return InkWell(
                            onTap: () {
                              _closePanel();
                              Future.microtask(
                                () => widget.onScrollToMessage(m.IdMsg),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
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
                                          widget.pinController.pinnedPreview(m),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 15),
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
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => widget.onTogglePin(m),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: Color(0xFF6E7682),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
