import 'package:flutter_chat/chat_frame.dart';

class ChatSessionScope extends StatefulWidget {
  const ChatSessionScope({
    super.key,
    required this.msgsNotifier,
    required this.child,
  });

  final ValueNotifier<List<Chatmsgobject>> msgsNotifier;
  final Widget child;

  @override
  State<ChatSessionScope> createState() => _ChatSessionScopeState();
}

class _ChatSessionScopeState extends State<ChatSessionScope> {
  late final ChatMessageController _messageController;
  late final ValueNotifier<ChatSearchHighlight> _searchHighlight;
  late final ValueNotifier<Chatmsgobject?> _replyingToNotifier;

  @override
  void initState() {
    super.initState();
    _messageController = ChatMessageController();
    _searchHighlight = ValueNotifier(const ChatSearchHighlight());
    _replyingToNotifier = ValueNotifier<Chatmsgobject?>(null);
  }

  @override
  void dispose() {
    _searchHighlight.dispose();
    _replyingToNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedChatSession(
      msgsNotifier: widget.msgsNotifier,
      messageController: _messageController,
      searchHighlightNotifier: _searchHighlight,
      replyingToNotifier: _replyingToNotifier,
      child: widget.child,
    );
  }
}

class _InheritedChatSession extends InheritedWidget {
  const _InheritedChatSession({
    required this.msgsNotifier,
    required this.messageController,
    required this.searchHighlightNotifier,
    required this.replyingToNotifier,
    required super.child,
  });

  final ValueNotifier<List<Chatmsgobject>> msgsNotifier;
  final ChatMessageController messageController;
  final ValueNotifier<ChatSearchHighlight> searchHighlightNotifier;
  final ValueNotifier<Chatmsgobject?> replyingToNotifier;

  @override
  bool updateShouldNotify(covariant _InheritedChatSession oldWidget) =>
      msgsNotifier != oldWidget.msgsNotifier ||
      messageController != oldWidget.messageController ||
      searchHighlightNotifier != oldWidget.searchHighlightNotifier ||
      replyingToNotifier != oldWidget.replyingToNotifier;
}

class ChatSessionScopeData {
  ChatSessionScopeData._({
    required this.msgsNotifier,
    required this.messageController,
    required this.searchHighlightNotifier,
    required this.replyingToNotifier,
  });

  final ValueNotifier<List<Chatmsgobject>> msgsNotifier;
  final ChatMessageController messageController;
  final ValueNotifier<ChatSearchHighlight> searchHighlightNotifier;
  final ValueNotifier<Chatmsgobject?> replyingToNotifier;

  static ChatSessionScopeData of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<_InheritedChatSession>();
    assert(w != null, 'ChatSessionScope required');
    return ChatSessionScopeData._(
      msgsNotifier: w!.msgsNotifier,
      messageController: w.messageController,
      searchHighlightNotifier: w.searchHighlightNotifier,
      replyingToNotifier: w.replyingToNotifier,
    );
  }
}