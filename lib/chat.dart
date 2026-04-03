import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_chat/Component/Chatbox/chat_boxmsg.dart';
import 'package:flutter_chat/Component/Services/chat_appbar.dart';
import 'package:flutter_chat/Component/Services/chat_session_scope.dart';
import 'package:flutter_chat/Component/Chatinput/chat_input.dart';
import 'package:flutter_chat/Module/chatData.dart';
import 'package:flutter_chat/Module/chatobj.dart';

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
  final ValueNotifier<List<Chatmsgobject>> _msgsNotifier =
      ValueNotifier<List<Chatmsgobject>>(List.from(Chatmsgobjects));

  @override
  void initState() {
    super.initState();
    _initCallkit();
  }

  //gọi call kit
  Future<void> _initCallkit() async {
    await FlutterCallkitIncoming.requestNotificationPermission({
      "title": "Notification permission",
      "rationaleMessagePermission":
          "Notification permission is required, to show notification.",
      "postNotificationMessageRequired":
          "Notification permission is required, Please allow notification permission from setting.",
    });

    await FlutterCallkitIncoming.requestFullIntentPermission();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _msgsNotifier.dispose();
    super.dispose();
  }

  void _closeInputPanels() {
    setState(() {
      _showEmoji = false;
      _showGallery = false;
      _showAttachMenu = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChatSessionScope(
      msgsNotifier: _msgsNotifier,
      child: Scaffold(
        appBar: ChatAppBar(
          // onCloseSearch: () {
          //   //FocusManager.instance.primaryFocus?.unfocus();
          // },
          title: "Chat",
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
                    _closeInputPanels();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: ChatMessage(
                    showPinnedBar: true,
                    inputFocusNode: _inputFocusNode,
                    onCloseOverlays: _closeInputPanels,
                  ),
                ),
              ),
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
                  _msgsNotifier.value = [..._msgsNotifier.value, msg];
                  _closeInputPanels();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
