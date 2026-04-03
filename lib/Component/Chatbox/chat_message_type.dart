import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/Chatinput/chat_url_preview.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:video_player/video_player.dart';

class ChatMessageText extends StatelessWidget {
  final String text;
  final bool isRecalled;
  final ValueChanged<String>? onTapLink;
  final String keyword;
  final bool isCurrentMatch;
  const ChatMessageText({
    super.key,
    required this.text,
    this.isRecalled = false,
    this.onTapLink,
    this.keyword = '',
    this.isCurrentMatch = false,
  });

  bool _isProbablyUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.') ||
        RegExp(
          r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}([\/?#][^\s]*)?$',
          caseSensitive: false,
        ).hasMatch(v);
  }

  String _normalizeUrl(String value) {
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  InlineSpan _buildHighlightedSpans({
    required String text,
    required String keyword,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    if (keyword.trim().isEmpty) {
      return TextSpan(text: text, style: normalStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: normalStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: highlightStyle,
        ),
      );

      start = index + keyword.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final styleNormal = TextStyle(
      fontSize: 15,
      color: Colors.black87,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );
    final styleMention = TextStyle(
      fontSize: 15,
      color: Colors.blue.shade700,
      fontWeight: FontWeight.w600,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );
    final styleLink = TextStyle(
      fontSize: 15,
      color: Colors.blue.shade700,
      decoration: TextDecoration.underline,
      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
    );

    final tokenReg = RegExp(
      r'((https?:\/\/[^\s]+)|(www\.[^\s]+)|((?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[\/?#][^\s]*)?)|(@[a-zA-Z0-9À-ỹ_]+))',
      caseSensitive: false,
    );

    final matches = tokenReg.allMatches(text).toList(growable: false);
    if (matches.isEmpty) {
      return RichText(
        text: _buildHighlightedSpans(
          text: text,
          keyword: keyword,
          normalStyle: styleNormal,
          highlightStyle: TextStyle(
            fontSize: 15,
            color: Colors.black,
            backgroundColor: isCurrentMatch
                ? Colors.orangeAccent
                : Colors.yellowAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final spans = <InlineSpan>[];
    int current = 0;

    for (final m in matches) {
      if (m.start > current) {
        spans.add(
          TextSpan(text: text.substring(current, m.start), style: styleNormal),
        );
      }
      final token = text.substring(m.start, m.end);
      if (token.startsWith('@')) {
        spans.add(TextSpan(text: token, style: styleMention));
      } else if (_isProbablyUrl(token)) {
        spans.add(
          TextSpan(
            text: token,
            style: styleLink,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onTapLink?.call(_normalizeUrl(token)),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: styleNormal));
      }
      current = m.end;
    }

    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current), style: styleNormal));
    }

    return RichText(
      text: _buildHighlightedSpans(
        text: text,
        keyword: keyword,
        normalStyle: styleNormal,
        highlightStyle: TextStyle(
          fontSize: 15,
          color: Colors.black,
          backgroundColor: isCurrentMatch
              ? Colors.orangeAccent
              : Colors.yellowAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ChatMessageImage extends StatelessWidget {
  final String data;
  final VoidCallback? onTap;

  const ChatMessageImage({super.key, required this.data, this.onTap});

  bool get _isNetwork =>
      data.startsWith("http://") ||
      data.startsWith("https://") ||
      data.startsWith("ftp://");

  bool get _isBase64 {
    if (data.isEmpty) return false;
    if (_isNetwork) return false;
    if (File(data).existsSync()) return false;
    return data.startsWith("data:image/") || _looksLikeBase64(data);
  }

  bool _looksLikeBase64(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 40) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(cleaned);
  }

  Uint8List? _decodeBase64(String value) {
    try {
      final raw = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isNetwork) {
      child = Image.network(
        data,
        fit: BoxFit.cover,
        height: 200,
        errorBuilder: (_, _, _) => _buildError(),
      );
    } else if (File(data).existsSync()) {
      child = Image.file(
        File(data),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildError(),
      );
    } else if (_isBase64) {
      final bytes = _decodeBase64(data);
      child = bytes == null
          ? _buildError()
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildError(),
            );
    } else {
      child = _buildError();
    }

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 240,
          maxHeight: 260,
          minHeight: 120,
        ),
        child: child,
      ),
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }

  Widget _buildError() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class ChatMessageSticker extends StatelessWidget {
  final String url;
  final String rawText;
  final VoidCallback onTap;

  const ChatMessageSticker({
    super.key,
    required this.url,
    required this.rawText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E5EA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rawText.trim().isNotEmpty)
                    Text(
                      rawText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageUrl extends StatefulWidget {
  final Chatmsgobject msg;
  final VoidCallback onTap;

  const ChatMessageUrl({super.key, required this.msg, required this.onTap});

  @override
  State<ChatMessageUrl> createState() => _ChatMessageUrlState();
}

class _ChatMessageUrlState extends State<ChatMessageUrl> {
  Chatmsgobject get msg => widget.msg;

  String get _url => msg.file;
  String get _displayDomain {
    final uri = Uri.tryParse(_url);
    return uri?.host ?? _url;
  }

  @override
  void initState() {
    super.initState();
    if (msg.isUrlLoading) {
      _autoFetch();
    }
  }

  Future<void> _autoFetch() async {
    final url = _url;
    if (url.isEmpty) {
      _markDone();
      return;
    }

    try {
      final metadata = await UrlMetadataFetcher.fetch(
        url,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      msg.titleUrl = metadata.title;
      msg.descriptioneUrl = metadata.description;
      msg.ImageUrl = metadata.imageUrl;
    } catch (_) {
    } finally {
      _markDone();
    }
  }

  void _markDone() {
    msg.isUrlFetchDone = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E5EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.ImageUrl != null && msg.ImageUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 160,
                child: Image.network(
                  msg.ImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF0F2F5),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.language,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFFF0F2F5),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayDomain,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (msg.titleUrl != null && msg.titleUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        msg.titleUrl!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),

                  if (msg.descriptioneUrl != null &&
                      msg.descriptioneUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        msg.descriptioneUrl!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ),

                  if (msg.isUrlLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Đang tải xem trước...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageFile extends StatelessWidget {
  final Chatmsgobject msg;
  final VoidCallback onTap;

  const ChatMessageFile({super.key, required this.msg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.insert_drive_file_outlined;
    Color iconColor = Colors.grey;
    final fileName = Uri.tryParse(msg.file)?.pathSegments.isNotEmpty == true
        ? Uri.parse(msg.file).pathSegments.last
        : msg.file.split('/').last;
    switch (msg.strTypeFile.toLowerCase()) {
      case "pdf":
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case "doc":
      case "docx":
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case "xls":
      case "xlsx":
        icon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case "ppt":
      case "pptx":
        icon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E4E4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName.isNotEmpty ? fileName : "Tệp đính kèm",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    msg.strTypeFile.isEmpty
                        ? "FILE"
                        : msg.strTypeFile.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ChatVideoThumb extends StatefulWidget {
  final String path;

  const ChatVideoThumb({super.key, required this.path});

  @override
  State<ChatVideoThumb> createState() => _ChatVideoThumbState();
}

class _ChatVideoThumbState extends State<ChatVideoThumb> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _hasError = false;
  String _durationText = "Video";

  bool get _isNetwork {
    final value = widget.path.trim();
    return value.startsWith("http://") || value.startsWith("https://");
  }

  bool get _isBase64 {
    final value = widget.path.trim();
    if (value.isEmpty || _isNetwork) return false;
    if (File(value).existsSync()) return false;
    if (value.startsWith("data:video/")) return true;
    if (value.length < 100) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final source = widget.path.trim();
      if (source.isEmpty) throw Exception("Empty video source");

      if (_isNetwork) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(source));
      } else if (_isBase64) {
        final file = await _writeTempVideo(source);
        _controller = VideoPlayerController.file(file);
      } else {
        _controller = VideoPlayerController.file(File(source));
      }

      await _controller!.initialize();
      await _controller!.pause();

      final d = _controller!.value.duration;
      _durationText = _format(d);

      if (!mounted) return;
      setState(() {
        _ready = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _hasError = true;
        _durationText = "Video";
      });
    }
  }

  Future<File> _writeTempVideo(String base64Value) async {
    final raw = base64Value.contains(',')
        ? base64Value.substring(base64Value.indexOf(',') + 1)
        : base64Value;

    final normalized = raw.replaceAll('\n', '').replaceAll('\r', '');
    final hash = normalized.hashCode;
    final file = File('${Directory.systemTemp.path}/chat_video_$hash.mp4');

    if (await file.exists()) return file;

    final bytes = base64Decode(normalized);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _format(Duration d) {
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_hasError) {
      body = Container(
        color: const Color(0xFFF5F5F5),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
      );
    } else if (_ready && _controller != null) {
      body = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    } else {
      body = Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 34,
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _durationText,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
