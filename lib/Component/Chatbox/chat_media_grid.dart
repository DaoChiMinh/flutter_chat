import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/Chatbox/chat_message_type.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class ChatMediaGrid extends StatelessWidget {
  final List<String> files;
  final ChatmsgObjtype type;
  final ValueChanged<int> onTapItem;

  const ChatMediaGrid({
    super.key,
    required this.files,
    required this.type,
    required this.onTapItem,
  });

  static const _gap = 2.0;
  static const _radius = 10.0;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final count = files.length;
    final maxW = MediaQuery.of(context).size.width * 0.68;

    if (count == 1) {
      return _cell(0, maxW, 180, borderRadius: BorderRadius.circular(_radius));
    }

    if (count == 2) {
      final w = (maxW - _gap) / 2;
      final h = w;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(
            0,
            w,
            h,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
            ),
          ),
          const SizedBox(width: _gap),
          _cell(
            1,
            w,
            h,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(_radius),
              bottomRight: Radius.circular(_radius),
            ),
          ),
        ],
      );
    }

    if (count == 3) {
      final bigW = maxW * 0.6;
      final smallW = maxW - bigW - _gap;
      final totalH = maxW * 0.75;
      final smallH = (totalH - _gap) / 2;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(
            0,
            bigW,
            totalH,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
            ),
          ),
          const SizedBox(width: _gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cell(
                1,
                smallW,
                smallH,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(_radius),
                ),
              ),
              const SizedBox(height: _gap),
              _cell(
                2,
                smallW,
                smallH,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(_radius),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return _buildDynamicGrid(maxW);
  }

  List<int> _distributeRows(int count) {
    final numRows = (count + 2) ~/ 3;
    final base = count ~/ numRows;
    final extra = count % numRows;
    final rows = List<int>.filled(numRows, base);
    final start = (numRows - extra) ~/ 2;
    for (int i = 0; i < extra; i++) {
      rows[start + i]++;
    }
    return rows;
  }

  Widget _buildDynamicGrid(double maxW) {
    final rowSizes = _distributeRows(files.length);
    final numRows = rowSizes.length;
    const cellH = 120.0;
    int fileIdx = 0;
    final rowWidgets = <Widget>[];

    for (int r = 0; r < numRows; r++) {
      final cols = rowSizes[r];
      final cellW = (maxW - _gap * (cols - 1)) / cols;
      final cells = <Widget>[];
      for (int c = 0; c < cols; c++) {
        final br = BorderRadius.only(
          topLeft: r == 0 && c == 0
              ? const Radius.circular(_radius)
              : Radius.zero,
          topRight: r == 0 && c == cols - 1
              ? const Radius.circular(_radius)
              : Radius.zero,
          bottomLeft: r == numRows - 1 && c == 0
              ? const Radius.circular(_radius)
              : Radius.zero,
          bottomRight: r == numRows - 1 && c == cols - 1
              ? const Radius.circular(_radius)
              : Radius.zero,
        );
        cells.add(_cell(fileIdx, cellW, cellH, borderRadius: br));
        fileIdx++;
        if (c < cols - 1) cells.add(const SizedBox(width: _gap));
      }
      rowWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
      if (r < numRows - 1) rowWidgets.add(const SizedBox(height: _gap));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rowWidgets);
  }

  Widget _cell(
    int index,
    double w,
    double h, {
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return GestureDetector(
      onTap: () => onTapItem(index),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: w,
          height: h,
          child: type == ChatmsgObjtype.video
              ? ChatVideoThumb(path: files[index])
              : _buildImage(files[index]),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    final bytes = _decodeBase64(path);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final raw = value.contains(',') ? value.split(',').last : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF1F3F5),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
