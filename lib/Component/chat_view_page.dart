import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatMessageVideo extends StatelessWidget {
  final String data;
  final VoidCallback onTap;
  final String durationText;
  final ImageProvider? thumbnail;

  const ChatMessageVideo({
    super.key,
    required this.data,
    required this.onTap,
    this.durationText = "Video",
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 220,
              child: thumbnail != null
                  ? Image(
                      image: thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
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
                  durationText,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: const Icon(Icons.videocam, color: Colors.grey, size: 36),
    );
  }
}

class ChatVideoViewerPage extends StatefulWidget {
  final String path;
  const ChatVideoViewerPage({super.key, required this.path});

  @override
  State<ChatVideoViewerPage> createState() => _ChatVideoViewerPageState();
}

class _ChatVideoViewerPageState extends State<ChatVideoViewerPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isDragging = false;
  Timer? _hideTimer;

  bool get _isNetwork {
    final v = widget.path.trim();
    return v.startsWith("http://") || v.startsWith("https://");
  }

  bool get _isBase64 {
    final v = widget.path.trim();
    if (v.isEmpty || _isNetwork) return false;
    if (v.startsWith("data:video/")) return true;
    if (v.length < 100) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(v);
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final source = widget.path.trim();
      if (source.isEmpty) throw Exception("Empty");
      if (_isNetwork) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(source));
      } else if (_isBase64) {
        final file = await _writeTempVideo(source);
        _controller = VideoPlayerController.file(file);
      } else {
        _controller = VideoPlayerController.file(File(source));
      }
      await _controller!.initialize();
      _controller!.addListener(_onTick);
      setState(() {
        _ready = true;
        _hasError = false;
      });
      _startAutoHide();
    } catch (_) {
      setState(() {
        _ready = false;
        _hasError = true;
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

  void _onTick() {
    if (mounted && !_isDragging) setState(() {});
  }

  void _startAutoHide() {
    _hideTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      c.play();
      setState(() => _showControls = true);
      _startAutoHide();
    }
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = _controller;
    if (c == null) return;
    var target = c.value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > c.value.duration) target = c.value.duration;
    await c.seekTo(target);
    setState(() => _showControls = true);
    _startAutoHide();
  }

  String _format(Duration d) {
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Xem video"),
      ),
      body: Center(
        child: _hasError
            ? const Text(
                "Không mở được video",
                style: TextStyle(color: Colors.white),
              )
            : !_ready || c == null
            ? const CircularProgressIndicator()
            : GestureDetector(
                onTap: () {
                  setState(() => _showControls = !_showControls);
                  if (_showControls) _startAutoHide();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),
                    if (_showControls)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: Column(
                            children: [
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => _seekRelative(
                                      const Duration(seconds: -10),
                                    ),
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: _togglePlayPause,
                                    icon: Icon(
                                      c.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 68,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () => _seekRelative(
                                      const Duration(seconds: 10),
                                    ),
                                    icon: const Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _format(c.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 2.4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                        ),
                                        child: Slider(
                                          value:
                                              c.value.duration.inMilliseconds <=
                                                  0
                                              ? 0
                                              : c.value.position.inMilliseconds
                                                    .clamp(
                                                      0,
                                                      c
                                                          .value
                                                          .duration
                                                          .inMilliseconds,
                                                    )
                                                    .toDouble(),
                                          min: 0,
                                          max:
                                              c.value.duration.inMilliseconds <=
                                                  0
                                              ? 1
                                              : c.value.duration.inMilliseconds
                                                    .toDouble(),
                                          onChangeStart: (_) {
                                            _isDragging = true;
                                            _hideTimer?.cancel();
                                          },
                                          onChanged: (v) async {
                                            await c.seekTo(
                                              Duration(milliseconds: v.toInt()),
                                            );
                                            if (mounted) setState(() {});
                                          },
                                          onChangeEnd: (_) {
                                            _isDragging = false;
                                            _startAutoHide();
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _format(c.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ChatWebViewerPage extends StatefulWidget {
  final String url;
  const ChatWebViewerPage({super.key, required this.url});

  @override
  State<ChatWebViewerPage> createState() => _ChatWebViewerPageState();
}

class _ChatWebViewerPageState extends State<ChatWebViewerPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trình duyệt'),
        actions: [
          IconButton(
            onPressed: () async {
              final uri = Uri.tryParse(widget.url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class ChatImageViewerPage extends StatelessWidget {
  final String path;
  const ChatImageViewerPage({super.key, required this.path});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');
  bool get _isBase64 {
    if (path.isEmpty || _isNetwork) return false;
    if (File(path).existsSync()) return false;
    return path.startsWith("data:image/") ||
        RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(path.trim());
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
    Widget imageWidget;
    if (_isNetwork) {
      imageWidget = Image.network(path, fit: BoxFit.contain);
    } else if (File(path).existsSync()) {
      imageWidget = Image.file(File(path), fit: BoxFit.contain);
    } else if (_isBase64) {
      final bytes = _decodeBase64(path);
      imageWidget = bytes == null
          ? const Icon(Icons.broken_image, color: Colors.white, size: 48)
          : Image.memory(bytes, fit: BoxFit.contain);
    } else {
      imageWidget = const Icon(
        Icons.broken_image,
        color: Colors.white,
        size: 48,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hình ảnh')),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: imageWidget,
        ),
      ),
    );
  }
}

class ChatPdfViewerPage extends StatelessWidget {
  final String path;
  const ChatPdfViewerPage({super.key, required this.path});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF')),
      body: _isNetwork
          ? SfPdfViewer.network(path)
          : SfPdfViewer.file(File(path)),
    );
  }
}

class ChatDocViewerPage extends StatelessWidget {
  final String path;
  final String title;
  const ChatDocViewerPage({super.key, required this.path, required this.title});

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _open(BuildContext context) async {
    if (_isNetwork) {
      final gUrl =
          'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(path)}';
      final uri = Uri.parse(gUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else {
      final result = await OpenFilex.open(path);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở tệp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Mở tệp'),
        ),
      ),
    );
  }
}

class ChatUnsupportedFilePage extends StatelessWidget {
  final String path;
  final String title;
  const ChatUnsupportedFilePage({
    super.key,
    required this.path,
    required this.title,
  });

  Future<void> _openExternal(BuildContext context) async {
    final result = await OpenFilex.open(path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _openExternal(context),
          icon: const Icon(Icons.insert_drive_file_outlined),
          label: const Text('Mở bằng ứng dụng khác'),
        ),
      ),
    );
  }
}
