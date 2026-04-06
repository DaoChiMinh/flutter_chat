import 'package:flutter_chat/chat_frame.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final String title;
  final String searchHintText;
  //final VoidCallback? onCloseSearch;

  const ChatAppBar({
    super.key,
    this.backgroundColor = Colors.red,
    this.title = 'Chat',
    this.searchHintText = 'Tìm trong đoạn chat',
    //this.onCloseSearch,
  });

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ChatAppBarState extends State<ChatAppBar> {
  bool _isSearching = false;
  final GlobalKey<ChatSearchState> _searchKey = GlobalKey<ChatSearchState>();

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchKey.currentState?.focusInput();
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
    });
    //widget.onCloseSearch?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.backgroundColor,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: _isSearching
          ? ChatSearch(
              key: _searchKey,
              hintText: widget.searchHintText,
              onCloseSearch: _closeSearch,
            )
          : Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
            ),
      actions: _isSearching
          ? null
          : [
              IconButton(
                onPressed: _openSearch,
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Tìm kiếm',
              ),
              const ChatCall(),
            ],
    );
  }
}