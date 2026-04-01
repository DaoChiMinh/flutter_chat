import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class ChatImageGalleryPage extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const ChatImageGalleryPage({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  @override
  State<ChatImageGalleryPage> createState() => _ChatImageGalleryPageState();
}

class _ChatImageGalleryPageState extends State<ChatImageGalleryPage> {
  late final PageController _pageCtrl;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Widget _buildPageImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.contain);
    }
    if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    try {
      final raw = path.contains(',') ? path.split(',').last : path;
      final bytes = base64Decode(raw);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (_) {}
    return const Icon(Icons.broken_image, color: Colors.white, size: 48);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentPage + 1} / ${widget.paths.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: _buildPageImage(widget.paths[i]),
            ),
          );
        },
      ),
    );
  }
}
