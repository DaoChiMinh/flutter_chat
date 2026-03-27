import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// ═══════════════════════════════════════════════════════════
// ★ Voice Recorder Controller
// ═══════════════════════════════════════════════════════════

class VoiceRecorderController {
  final _recorder = AudioRecorder();
  Timer? _timer;
  String? _filePath;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  int _seconds = 0;
  int get seconds => _seconds;

  String get durationText {
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Bắt đầu thu âm → trả về true nếu OK
  Future<bool> start() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _filePath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          ),
          path: _filePath!,
        );

        _isRecording = true;
        _seconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _seconds++);
        return true;
      }
    } catch (e) {
      debugPrint('VoiceRecorder start error: $e');
    }
    return false;
  }

  /// Dừng thu âm → trả về {filePath, base64, durationSeconds}
  Future<VoiceRecordResult?> stop() async {
    _timer?.cancel();
    _timer = null;

    if (!_isRecording) return null;
    _isRecording = false;

    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      return VoiceRecordResult(
        filePath: path,
        base64Data: base64Data,
        durationSeconds: _seconds,
      );
    } catch (e) {
      debugPrint('VoiceRecorder stop error: $e');
      return null;
    }
  }

  /// Huỷ thu âm (không gửi)
  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    _isRecording = false;

    try {
      await _recorder.stop();
      // Xoá file tạm
      if (_filePath != null) {
        final f = File(_filePath!);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await cancel();
    _recorder.dispose();
  }
}

class VoiceRecordResult {
  final String filePath;
  final String base64Data;
  final int durationSeconds;

  const VoiceRecordResult({
    required this.filePath,
    required this.base64Data,
    required this.durationSeconds,
  });
}

// ═══════════════════════════════════════════════════════════
// ★ Recording Overlay — hiện khi đang thu âm
// ═══════════════════════════════════════════════════════════

class ChatVoiceRecordingOverlay extends StatefulWidget {
  final VoiceRecorderController controller;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const ChatVoiceRecordingOverlay({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<ChatVoiceRecordingOverlay> createState() =>
      _ChatVoiceRecordingOverlayState();
}

class _ChatVoiceRecordingOverlayState extends State<ChatVoiceRecordingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Cập nhật UI mỗi giây để hiện timer
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 10,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Nút huỷ ──
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
            tooltip: 'Huỷ',
          ),

          const SizedBox(width: 8),

          // ── Indicator nhấp nháy + thời gian ──
          Expanded(
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) =>
                      Transform.scale(scale: _pulseAnim.value, child: child),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.controller.durationText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đang ghi âm...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Nút gửi ──
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xff009EF9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ★ Audio Message Bubble — phát lại tin nhắn âm thanh
// ═══════════════════════════════════════════════════════════

class ChatAudioBubble extends StatefulWidget {
  /// base64 data hoặc file path hoặc URL
  final String audioData;

  /// Thời lượng (giây) — nếu biết trước
  final int? durationSeconds;

  const ChatAudioBubble({
    super.key,
    required this.audioData,
    this.durationSeconds,
  });

  @override
  State<ChatAudioBubble> createState() => _ChatAudioBubbleState();
}

class _ChatAudioBubbleState extends State<ChatAudioBubble> {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  bool _prepared = false;

  @override
  void initState() {
    super.initState();

    if (widget.durationSeconds != null) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _prepareAndPlay() async {
    if (!_prepared) {
      await _setSource();
      _prepared = true;
    }
    await _player.resume();
  }

  Future<void> _setSource() async {
    final data = widget.audioData;

    if (data.startsWith('http://') || data.startsWith('https://')) {
      await _player.setSource(UrlSource(data));
    } else if (File(data).existsSync()) {
      await _player.setSource(DeviceFileSource(data));
    } else {
      // Base64 → ghi file tạm rồi phát
      try {
        final raw = data.contains(',') ? data.split(',').last : data;
        final bytes = base64Decode(raw);
        final dir = await getTemporaryDirectory();
        final hash = raw.hashCode;
        final tmpFile = File('${dir.path}/audio_$hash.m4a');
        if (!await tmpFile.exists()) {
          await tmpFile.writeAsBytes(bytes, flush: true);
        }
        await _player.setSource(DeviceFileSource(tmpFile.path));
      } catch (e) {
        debugPrint('Audio setSource error: $e');
      }
    }
  }

  void _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _prepareAndPlay();
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final totalMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 1);
    final progress = totalMs > 0 ? posMs / totalMs : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Play / Pause button ──
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xff009EF9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Waveform + progress ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh progress giả dạng sóng âm
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    size: const Size(double.infinity, 28),
                    painter: _WaveformPainter(
                      progress: progress,
                      activeColor: const Color(0xff009EF9),
                      inactiveColor: const Color(0xFFCCD6E0),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // Duration text
                Text(
                  isPlaying || _position > Duration.zero
                      ? _formatDuration(_position)
                      : _formatDuration(_duration),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ── Mic icon ──
          Icon(Icons.mic, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ★ Waveform Painter — vẽ sóng âm giả
// ═══════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  // Pattern sóng âm cố định (giả lập)
  static const _bars = [
    0.3,
    0.5,
    0.7,
    0.4,
    0.9,
    0.6,
    0.8,
    0.3,
    0.5,
    0.7,
    0.4,
    0.6,
    0.9,
    0.5,
    0.3,
    0.7,
    0.8,
    0.4,
    0.6,
    0.5,
    0.7,
    0.3,
    0.8,
    0.5,
    0.9,
    0.4,
    0.6,
    0.7,
    0.3,
    0.5,
    0.8,
    0.6,
    0.4,
    0.7,
    0.9,
    0.3,
    0.5,
    0.8,
    0.6,
    0.4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.5;
    const barGap = 1.5;
    final totalBarWidth = barWidth + barGap;
    final barCount = (size.width / totalBarWidth).floor().clamp(
      1,
      _bars.length,
    );
    final midY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      final fraction = i / barCount;
      final barH = _bars[i % _bars.length] * size.height * 0.8;
      final halfH = barH / 2;

      final paint = Paint()
        ..color = fraction <= progress ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      canvas.drawLine(
        Offset(x + barWidth / 2, midY - halfH),
        Offset(x + barWidth / 2, midY + halfH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress;
}
