import 'package:flutter_chat/chat_frame.dart';

/// Trạng thái highlight kết quả tìm trong đoạn chat.
class ChatSearchHighlight {
  final String keyword;
  final List<String> matchedMessageIds;
  final String? currentMatchedMessageId;

  const ChatSearchHighlight({
    this.keyword = '',
    this.matchedMessageIds = const [],
    this.currentMatchedMessageId,
  });
}

class ChatSearch extends StatefulWidget {
  final String hintText;
  final VoidCallback? onCloseSearch;

  const ChatSearch({
    super.key,
    this.hintText = 'Tìm trong đoạn chat',
    this.onCloseSearch,
  });

  @override
  State<ChatSearch> createState() => ChatSearchState();
}

class ChatSearchState extends State<ChatSearch> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _matchedIds = [];
  int _currentIndex = -1;
  String _keyword = '';

  String? get currentMatchedMessageId =>
      _currentIndex >= 0 && _currentIndex < _matchedIds.length
      ? _matchedIds[_currentIndex]
      : null;

  void focusInput() {
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _notifySearchChanged() {
    final session = ChatSessionScopeData.of(context);
    session.searchHighlightNotifier.value = ChatSearchHighlight(
      keyword: _keyword,
      matchedMessageIds: List<String>.from(_matchedIds),
      currentMatchedMessageId: currentMatchedMessageId,
    );
  }

  String _messageSearchText(Chatmsgobject msg) {
    final parts = <String>[];

    if (msg.Note.trim().isNotEmpty) {
      parts.add(msg.Note.trim());
    }
    if (msg.titleUrl?.trim().isNotEmpty == true) {
      parts.add(msg.titleUrl!.trim());
    }
    if (msg.descriptioneUrl?.trim().isNotEmpty == true) {
      parts.add(msg.descriptioneUrl!.trim());
    }
    if (msg.replyMsg?.Note.trim().isNotEmpty == true) {
      parts.add(msg.replyMsg!.Note.trim());
    }

    return parts.join(' ').toLowerCase();
  }

  void runSearch(String keyword) {
    final session = ChatSessionScopeData.of(context);
    final messages = session.msgsNotifier.value;
    final q = keyword.trim().toLowerCase();

    setState(() {
      _keyword = keyword;
    });

    if (q.isEmpty) {
      setState(() {
        _matchedIds = [];
        _currentIndex = -1;
      });
      _notifySearchChanged();
      return;
    }

    final matched = messages
        .where((msg) => _messageSearchText(msg).contains(q))
        .map((msg) => msg.IdMsg)
        .toList();

    setState(() {
      _matchedIds = matched;
      _currentIndex = matched.isNotEmpty ? 0 : -1;
    });

    _notifySearchChanged();

    if (matched.isNotEmpty) {
      session.messageController.scrollToMessage(matched[0]);
    }
  }

  void goNext() {
    if (_matchedIds.isEmpty) return;
    final session = ChatSessionScopeData.of(context);
    final nextIndex = (_currentIndex + 1) % _matchedIds.length;

    setState(() {
      _currentIndex = nextIndex;
    });

    _notifySearchChanged();
    session.messageController.scrollToMessage(_matchedIds[nextIndex]);
  }

  void goPrev() {
    if (_matchedIds.isEmpty) return;
    final session = ChatSessionScopeData.of(context);
    final prevIndex =
        (_currentIndex - 1 + _matchedIds.length) % _matchedIds.length;

    setState(() {
      _currentIndex = prevIndex;
    });

    _notifySearchChanged();
    session.messageController.scrollToMessage(_matchedIds[prevIndex]);
  }

  void clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _keyword = '';
      _matchedIds = [];
      _currentIndex = -1;
    });
    _notifySearchChanged();
  }

  void closeSearch() {
    _searchCtrl.clear();
    setState(() {
      _keyword = '';
      _matchedIds = [];
      _currentIndex = -1;
    });
    _notifySearchChanged();
    widget.onCloseSearch?.call();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                      )
                    : null,
              ),
              onChanged: (value) {
                runSearch(value);
                setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_matchedIds.isEmpty ? 0 : _currentIndex + 1}/${_matchedIds.length}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        IconButton(
          onPressed: _matchedIds.isEmpty ? null : goPrev,
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
        ),
        IconButton(
          onPressed: _matchedIds.isEmpty ? null : goNext,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
        IconButton(
          onPressed: closeSearch,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }
}
