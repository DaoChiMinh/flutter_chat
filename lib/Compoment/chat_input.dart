import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});
  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _textController;
  bool isEdit = false;
  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _chatInput();
  }

  Widget _chatInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, -4),
            blurRadius: 10,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  color: const Color(0xff9E9E9E),
                  iconSize: 28,
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Nhập tin nhắn",
                      hintStyle: TextStyle(color: Color(0xff9E9E9E)),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isEdit = value.isNotEmpty;
                      });
                    },
                    minLines: 1,
                    maxLines: 2,
                  ),
                ),
              ),
              if (!isEdit) ...[
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                    color: const Color(0xff9E9E9E),
                    iconSize: 28,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.image),
                    color: const Color(0xff9E9E9E),
                    iconSize: 28,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xff009EF9),
                    iconSize: 28,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    // _textController = null;
    super.dispose();
  }
}
