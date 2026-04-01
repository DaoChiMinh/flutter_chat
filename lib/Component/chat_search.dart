import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ChatSearch extends StatefulWidget implements PreferredSizeWidget {
  final List<Chatmsgobject> messages;
  final ValueChanged<String> onJumpToMessage;
  final VoidCallback? onCloseSearch;
  final Color backgroundColor;
  final String hintText;
  final void Function(
    String keyword,
    List<String> matchedIds,
    String? currentMatchedMessageId,
  )?
  onSearchChanged;
  const ChatSearch({
    super.key,
    required this.messages,
    required this.onJumpToMessage,
    this.onCloseSearch,
    this.onSearchChanged,
    this.backgroundColor = Colors.red,
    this.hintText = 'Tìm trong đoạn chat',
  });

  static _ChatSearchState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ChatSearchState>();
  }

  @override
  State<ChatSearch> createState() => _ChatSearchState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ChatSearchState extends State<ChatSearch> {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _matchedIds = [];
  int _currentIndex = -1;
  String _keyword = '';

  String get searchKeyword => _keyword;
  List<String> get matchedMessageIds => _matchedIds;
  String? get currentMatchedMessageId =>
      _currentIndex >= 0 && _currentIndex < _matchedIds.length
      ? _matchedIds[_currentIndex]
      : null;

  void _notifySearchChanged() {
    widget.onSearchChanged?.call(
      _keyword,
      _matchedIds,
      currentMatchedMessageId,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
    final q = keyword.trim().toLowerCase();

    setState(() {
      _keyword = keyword;
    });
    _notifySearchChanged();
    if (q.isEmpty) {
      setState(() {
        _matchedIds = [];
        _currentIndex = -1;
      });
      return;
    }

    final matched = widget.messages
        .where((msg) => _messageSearchText(msg).contains(q))
        .map((msg) => msg.IdMsg)
        .toList();

    setState(() {
      _matchedIds = matched;
      _currentIndex = matched.isNotEmpty ? 0 : -1;
    });

    if (matched.isNotEmpty) {
      widget.onJumpToMessage(matched[0]);
    }
  }

  void goNext() {
    if (_matchedIds.isEmpty) return;

    final nextIndex = (_currentIndex + 1) % _matchedIds.length;

    setState(() {
      _currentIndex = nextIndex;
    });
    _notifySearchChanged();
    widget.onJumpToMessage(_matchedIds[nextIndex]);
  }

  void goPrev() {
    if (_matchedIds.isEmpty) return;

    final prevIndex =
        (_currentIndex - 1 + _matchedIds.length) % _matchedIds.length;

    setState(() {
      _currentIndex = prevIndex;
    });
    _notifySearchChanged();
    widget.onJumpToMessage(_matchedIds[prevIndex]);
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

  void toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;

      if (!_isSearching) {
        _searchCtrl.clear();
        _keyword = '';
        _matchedIds = [];
        _currentIndex = -1;
        _notifySearchChanged();
      }
    });

    if (_isSearching) {
      Future.microtask(() => _searchFocusNode.requestFocus());
    } else {
      widget.onCloseSearch?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.backgroundColor,
      title: _isSearching
          ? Container(
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
                onChanged: runSearch,
              ),
            )
          : const Text("Chat", style: TextStyle(color: Colors.white)),
      actions: [
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Text(
                '${_matchedIds.isEmpty ? 0 : _currentIndex + 1}/${_matchedIds.length}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        IconButton(
          onPressed: toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
        ),
        if (_isSearching) ...[
          IconButton(
            onPressed: _matchedIds.isEmpty ? null : goPrev,
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
          IconButton(
            onPressed: _matchedIds.isEmpty ? null : goNext,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
        ],
      ],
    );
  }
}
