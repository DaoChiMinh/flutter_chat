import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_emoji.dart';
import 'package:flutter_chat/Component/chat_url_preview.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ChatInputState {
  final bool isEditing;
  final List<AssetEntity> assets;
  final List<AssetEntity> selectedAssets;

  const ChatInputState({
    this.isEditing = false,
    this.assets = const [],
    this.selectedAssets = const [],
  });

  ChatInputState copyWith({
    bool? isEditing,
    List<AssetEntity>? assets,
    List<AssetEntity>? selectedAssets,
  }) {
    return ChatInputState(
      isEditing: isEditing ?? this.isEditing,
      assets: assets ?? this.assets,
      selectedAssets: selectedAssets ?? this.selectedAssets,
    );
  }
}

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    required this.showEmoji,
    required this.showGallery,
    required this.onShowEmojiChanged,
    required this.onShowGalleryChanged,
    this.onRefreshMessages,
  });

  final ValueChanged<Chatmsgobject> onSend;

  /// Gọi khi metadata cập nhật xong → parent rebuild list (KHÔNG thêm msg mới)
  final VoidCallback? onRefreshMessages;

  final bool showEmoji;
  final bool showGallery;
  final ValueChanged<bool> onShowEmojiChanged;
  final ValueChanged<bool> onShowGalleryChanged;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  var _state = const ChatInputState();

  // ── URL preview state ──
  String? _detectedUrl;
  UrlMetadata? _urlMetadata;
  bool _isFetchingPreview = false;
  Timer? _urlDetectTimer;

  @override
  void dispose() {
    _urlDetectTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Text & URL detection
  // ----------------------------------------------------------

  void _onTextChanged(String value) {
    setState(() => _state = _state.copyWith(isEditing: value.isNotEmpty));

    // Debounce 600ms → detect URL
    _urlDetectTimer?.cancel();
    _urlDetectTimer = Timer(const Duration(milliseconds: 600), () {
      _detectAndFetchUrl(value);
    });
  }

  Future<void> _detectAndFetchUrl(String text) async {
    final url = UrlMetadataFetcher.extractFirstUrl(text);

    // Không có URL → xoá preview
    if (url == null) {
      if (_detectedUrl != null) {
        setState(() {
          _detectedUrl = null;
          _urlMetadata = null;
          _isFetchingPreview = false;
        });
      }
      return;
    }

    // URL giống lần trước → skip
    if (url == _detectedUrl) return;

    // URL mới → fetch metadata
    setState(() {
      _detectedUrl = url;
      _urlMetadata = null;
      _isFetchingPreview = true;
    });

    try {
      final metadata = await UrlMetadataFetcher.fetch(url);
      if (!mounted) return;
      // Kiểm tra URL vẫn còn đúng (user chưa thay đổi text)
      if (_detectedUrl == url) {
        setState(() {
          _urlMetadata = metadata;
          _isFetchingPreview = false;
        });
      }
    } catch (_) {
      if (mounted && _detectedUrl == url) {
        setState(() => _isFetchingPreview = false);
      }
    }
  }

  // ----------------------------------------------------------
  // Emoji & Gallery
  // ----------------------------------------------------------

  void _onTextFieldTapped() {
    widget.onShowEmojiChanged(false);
    widget.onShowGalleryChanged(false);
  }

  void _onEmojiToggled() {
    final willShow = !widget.showEmoji;
    widget.onShowEmojiChanged(willShow);
    widget.onShowGalleryChanged(false);
    if (willShow) _focusNode.unfocus();
  }

  void _onEmojiSelected(String emoji) {
    final text = _textController.text;
    final sel = _textController.selection;
    final newText = sel.isValid
        ? text.replaceRange(sel.start, sel.end, emoji)
        : text + emoji;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: sel.isValid ? sel.start + emoji.length : newText.length,
      ),
    );
    setState(() => _state = _state.copyWith(isEditing: newText.isNotEmpty));
  }

  void _onStickerSelected(Sticker sticker) {
    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..Note = sticker.url
        ..strTypeFile = 'stiker',
    );
  }

  Future<void> _onGalleryToggled() async {
    final willShow = !widget.showGallery;
    if (willShow && _state.assets.isEmpty) await _loadPhotos();
    widget.onShowGalleryChanged(willShow);
    widget.onShowEmojiChanged(false);
    if (willShow) _focusNode.unfocus();
  }

  void _onAssetToggled(AssetEntity asset) {
    final selected = List<AssetEntity>.from(_state.selectedAssets);
    if (selected.contains(asset)) {
      selected.remove(asset);
    } else {
      selected.add(asset);
    }
    setState(() => _state = _state.copyWith(selectedAssets: selected));
  }

  Future<void> _onCameraPressed() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) await _loadPhotos();
  }

  // ----------------------------------------------------------
  // ★ SEND — chỉ gửi 1 tin nhắn duy nhất
  // ----------------------------------------------------------

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final msg = Chatmsgobject()
      ..Comment = "minhdc"
      ..isMe = true
      ..Send_Date = DateTime.now()
      ..Note = text;

    if (_detectedUrl != null) {
      // ── Tin nhắn có chứa URL ──
      msg.strDataFile = [_detectedUrl!];
      msg.strTypeFile = 'url';

      // Nếu metadata đã fetch xong → gắn luôn
      if (_urlMetadata != null) {
        msg.titleUrl = _urlMetadata!.title;
        msg.descriptioneUrl = _urlMetadata!.description;
        msg.ImageUrl = _urlMetadata!.imageUrl;
      }

      // Gửi 1 lần duy nhất
      widget.onSend(msg);

      // Nếu metadata chưa sẵn sàng → fetch async rồi cập nhật
      if (_urlMetadata == null) {
        _fetchMetadataLate(msg, _detectedUrl!);
      }
    } else {
      // ── Tin nhắn text thường ──
      widget.onSend(msg);
    }

    // Reset input
    _textController.clear();
    _urlDetectTimer?.cancel();
    setState(() {
      _state = _state.copyWith(isEditing: false);
      _detectedUrl = null;
      _urlMetadata = null;
      _isFetchingPreview = false;
    });
  }

  /// Fetch metadata sau khi đã gửi tin nhắn → cập nhật msg object → gọi refresh
  Future<void> _fetchMetadataLate(Chatmsgobject msg, String url) async {
    try {
      final metadata = await UrlMetadataFetcher.fetch(url);
      msg.titleUrl = metadata.title;
      msg.descriptioneUrl = metadata.description;
      msg.ImageUrl = metadata.imageUrl;

      // Gọi refresh để parent rebuild list (KHÔNG gọi onSend)
      widget.onRefreshMessages?.call();
    } catch (_) {
      // Thất bại → giữ nguyên, không crash
    }
  }

  Future<void> _onSendImages() async {
    if (_state.selectedAssets.isEmpty) return;

    List<String> lsImages = [];
    for (final asset in _state.selectedAssets) {
      final file = await asset.file;
      if (file == null) continue;
      lsImages.add(file.path);
    }
    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = lsImages
        ..strTypeFile = 'jpg'
        ..Note = '',
    );
    widget.onShowGalleryChanged(false);
    setState(() => _state = _state.copyWith(selectedAssets: []));
  }

  Future<void> _loadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 80);
    setState(() => _state = _state.copyWith(assets: assets));
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final showGallery = widget.showGallery && !_state.isEditing;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 26),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InputRow(
            textController: _textController,
            focusNode: _focusNode,
            isEditing: _state.isEditing,
            isShowingEmoji: widget.showEmoji,
            onTextChanged: _onTextChanged,
            onTap: _onTextFieldTapped,
            onEmojiPressed: _onEmojiToggled,
            onGalleryPressed: _onGalleryToggled,
            onSendPressed: _onSendPressed,
          ),

          // ── ★ URL Preview Card (hiển thị khi đang gõ) ──
          if (_detectedUrl != null)
            _UrlPreviewCard(
              url: _detectedUrl!,
              metadata: _urlMetadata,
              isLoading: _isFetchingPreview,
              onDismiss: () {
                setState(() {
                  _detectedUrl = null;
                  _urlMetadata = null;
                  _isFetchingPreview = false;
                });
              },
            ),

          if (widget.showEmoji)
            SizedBox(
              height: 300,
              child: ChatEmojiPanel(
                onEmojiSelected: _onEmojiSelected,
                onStickerSelected: _onStickerSelected,
              ),
            ),
          if (showGallery)
            _GalleryGrid(
              assets: _state.assets,
              selectedAssets: _state.selectedAssets,
              onAssetToggled: _onAssetToggled,
              onCameraPressed: _onCameraPressed,
              onConfirm: _onSendImages,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ★ URL Preview Card — hiện bên dưới input khi phát hiện URL
// ═══════════════════════════════════════════════════════════

class _UrlPreviewCard extends StatelessWidget {
  final String url;
  final UrlMetadata? metadata;
  final bool isLoading;
  final VoidCallback onDismiss;

  const _UrlPreviewCard({
    required this.url,
    required this.metadata,
    required this.isLoading,
    required this.onDismiss,
  });

  String get _domain {
    final uri = Uri.tryParse(url);
    return uri?.host ?? url;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: domain + nút đóng ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.blue.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading ──
          if (isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

          // ── Metadata đã sẵn sàng ──
          if (!isLoading && metadata != null) ...[
            // Ảnh preview
            if (metadata!.imageUrl != null && metadata!.imageUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 120,
                child: Image.network(
                  metadata!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (metadata!.title != null)
                    Text(
                      metadata!.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  if (metadata!.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        metadata!.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Các widget con giữ nguyên
// ═══════════════════════════════════════════════════════════

class _InputRow extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isEditing;
  final bool isShowingEmoji;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onTap;
  final VoidCallback onEmojiPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onSendPressed;

  const _InputRow({
    required this.textController,
    required this.focusNode,
    required this.isEditing,
    required this.isShowingEmoji,
    required this.onTextChanged,
    required this.onTap,
    required this.onEmojiPressed,
    required this.onGalleryPressed,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconBtn(
          icon: isShowingEmoji
              ? Icons.keyboard_alt_outlined
              : Icons.emoji_emotions_outlined,
          onPressed: onEmojiPressed,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              onTap: onTap,
              onChanged: onTextChanged,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn',
                hintStyle: TextStyle(color: Color(0xff9E9E9E)),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        if (isEditing)
          _IconBtn(
            icon: Icons.send_rounded,
            color: const Color(0xff009EF9),
            onPressed: onSendPressed,
          )
        else ...[
          _IconBtn(icon: Icons.more_horiz, onPressed: () {}),
          _IconBtn(icon: Icons.image, onPressed: onGalleryPressed),
        ],
      ],
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<AssetEntity> assets;
  final List<AssetEntity> selectedAssets;
  final ValueChanged<AssetEntity> onAssetToggled;
  final VoidCallback onCameraPressed;
  final Future<void> Function() onConfirm;

  const _GalleryGrid({
    required this.assets,
    required this.selectedAssets,
    required this.onAssetToggled,
    required this.onCameraPressed,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: GridView.builder(
              padding: selectedAssets.isNotEmpty
                  ? const EdgeInsets.only(bottom: 60)
                  : EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: assets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CameraCell(onPressed: onCameraPressed);
                }
                final asset = assets[index - 1];
                return _AssetCell(
                  asset: asset,
                  selectedIndex: selectedAssets.contains(asset)
                      ? selectedAssets.indexOf(asset) + 1
                      : null,
                  onTap: () => onAssetToggled(asset),
                );
              },
            ),
          ),
          if (selectedAssets.isNotEmpty)
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: FilledButton(
                onPressed: onConfirm,
                child: Text('Gửi ${selectedAssets.length} ảnh'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraCell extends StatelessWidget {
  final VoidCallback onPressed;
  const _CameraCell({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 32,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              'Chụp ảnh',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCell extends StatelessWidget {
  final AssetEntity asset;
  final int? selectedIndex;
  final VoidCallback onTap;
  const _AssetCell({
    required this.asset,
    required this.selectedIndex,
    required this.onTap,
  });

  bool get isSelected => selectedIndex != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(300, 300),
              fit: BoxFit.cover,
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withOpacity(0.5)),
            ),
          Positioned(
            right: 6,
            top: 6,
            child: _SelectBadge(index: selectedIndex),
          ),
        ],
      ),
    );
  }
}

class _SelectBadge extends StatelessWidget {
  final int? index;
  const _SelectBadge({required this.index});
  bool get isSelected => index != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff009EF9) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          : null,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _IconBtn({
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xff9E9E9E),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: color,
        iconSize: 28,
      ),
    );
  }
}
