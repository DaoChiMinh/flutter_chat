import 'package:flutter/material.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({super.key});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.red, title: Text("Xin chào")),
      body: Column(
        children: [
          Expanded(child: Container()),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hint: Text("aaaaaaaaaaa"),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
