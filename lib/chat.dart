import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_boxmsg.dart';
import 'package:flutter_chat/Component/chat_input.dart';
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
  final _msgsNotifier = ValueNotifier<List<Chatmsgobject>>(
    List.from(Chatmsgobjects),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Chat", style: TextStyle(color: Colors.white)),
      ),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _showEmoji = false;
            _showGallery = false;
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: const Color(0xffE4E8F3),
          // padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<Chatmsgobject>>(
                  valueListenable: _msgsNotifier,
                  builder: (context, msgs, _) {
                    return ChatMessage(msgs: msgs);
                  },
                ),
              ),
              ChatInput(
                showEmoji: _showEmoji,
                showGallery: _showGallery,
                onShowEmojiChanged: (v) => setState(() => _showEmoji = v),
                onShowGalleryChanged: (v) => setState(() => _showGallery = v),
                onSend: (msg) {
                  _msgsNotifier.value = [..._msgsNotifier.value, msg];
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() {
                    _showEmoji = false;
                    _showGallery = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
