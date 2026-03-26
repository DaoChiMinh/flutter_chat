import 'package:flutter/material.dart';
import 'package:flutter_chat/Compoment/chat_boxmsg.dart';
import 'package:flutter_chat/Compoment/chat_input.dart';
import 'package:flutter_chat/Module/chatData.dart';


class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Chat", style: TextStyle(color: Colors.white)),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          color: const Color(0xffE4E8F3),
          // padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Expanded(child: ChatMessage(msgs: Chatmsgobjects,)),
              ChatInput(),
            ],
          ),
        ),
      ),
    );
  }
}
