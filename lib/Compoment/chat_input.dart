import 'package:flutter/material.dart';

Widget ChatInput() {
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
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn",
                    hintStyle: TextStyle(color: const Color(0xff9E9E9E)),
                    border: InputBorder.none,
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
                color: const Color(0xff9E9E9E),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.image),
                color: const Color(0xff9E9E9E),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded),
                color: const Color(0xff9E9E9E),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
