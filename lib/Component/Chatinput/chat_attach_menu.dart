import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/Module/chatobj.dart';

class _AttachMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final String id;

  const _AttachMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.id,
  });
}

const _kMenuItems = <_AttachMenuItem>[
  _AttachMenuItem(
    id: 'location',
    label: 'Vị trí',
    icon: Icons.location_on,
    color: Color(0xFFE74C3C),
  ),
  _AttachMenuItem(
    id: 'document',
    label: 'Tài liệu',
    icon: Icons.description,
    color: Color(0xFF3498DB),
  ),
];

class ChatAttachMenuPanel extends StatelessWidget {
  final ValueChanged<Chatmsgobject> onSend;

  const ChatAttachMenuPanel({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _kMenuItems.length,
        itemBuilder: (context, index) {
          final item = _kMenuItems[index];
          return _AttachMenuCell(
            item: item,
            onTap: () => _onItemTap(context, item),
          );
        },
      ),
    );
  }

  void _onItemTap(BuildContext context, _AttachMenuItem item) {
    HapticFeedback.lightImpact();

    switch (item.id) {
      case 'document':
        _pickDocument(context);
        break;
      case 'location':
      case 'reminder':
      case 'quick_message':
      case 'contact':
      case 'gif':
      case 'draw':
      case 'font':
        _showComingSoon(context, item.label);
        break;
    }
  }

  // ── Chọn tài liệu ──
  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        if (file.path == null) continue;
        _sendFileMessage(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Không thể chọn tệp: $e')));
      }
    }
  }

  void _sendFileMessage(PlatformFile file) {
    final path = file.path!;
    final ext = (file.extension ?? '').toLowerCase();
    final fileName = file.name;

    // Xác định strTypeFile
    final String typeFile;
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    const videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'];
    const audioExts = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'wma', 'flac'];

    if (imageExts.contains(ext)) {
      typeFile = ext == 'jpeg' ? 'jpg' : ext;
    } else if (videoExts.contains(ext)) {
      typeFile = ext;
    } else if (audioExts.contains(ext)) {
      typeFile = ext;
    } else if (ext == 'pdf') {
      typeFile = 'pdf';
    } else if (ext == 'doc' || ext == 'docx') {
      typeFile = ext;
    } else if (ext == 'xls' || ext == 'xlsx') {
      typeFile = ext;
    } else if (ext == 'ppt' || ext == 'pptx') {
      typeFile = ext;
    } else {
      typeFile = ext.isNotEmpty ? ext : 'file';
    }

    // Note: tên file cho document, trống cho media
    final String note;
    if (imageExts.contains(ext) || videoExts.contains(ext)) {
      note = '';
    } else {
      note = fileName;
    }
  
    onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = [path]
        ..strTypeFile = typeFile
        ..Note = note,
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label — Tính năng đang phát triển'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _AttachMenuCell extends StatefulWidget {
  final _AttachMenuItem item;
  final VoidCallback onTap;

  const _AttachMenuCell({required this.item, required this.onTap});

  @override
  State<_AttachMenuCell> createState() => _AttachMenuCellState();
}

class _AttachMenuCellState extends State<_AttachMenuCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Circular icon ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.item.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.item.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.item.icon, color: Colors.white, size: 24),
            ),

            const SizedBox(height: 8),
            //
            // ── Label ──
            Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
