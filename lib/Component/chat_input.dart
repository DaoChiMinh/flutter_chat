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

/// Trạng thái preview URL đang detect
class _UrlDetectState {
  final String url;
  final UrlContentType? contentType; // null = đang detect
  final UrlTypeResult? typeResult;
  final UrlMetadata? metadata; // chỉ cho web
  final bool isFetching;

  const _UrlDetectState({
    required this.url,
    this.contentType,
    this.typeResult,
    this.metadata,
    this.isFetching = true,
  });
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

  // ── URL detect state ──
  _UrlDetectState? _urlState;
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

    _urlDetectTimer?.cancel();
    _urlDetectTimer = Timer(const Duration(milliseconds: 600), () {
      _detectUrl(value);
    });
  }

  Future<void> _detectUrl(String text) async {
    final url = UrlMetadataFetcher.extractFirstUrl(text);

    // Không có URL → xoá preview
    if (url == null) {
      if (_urlState != null) {
        setState(() => _urlState = null);
      }
      return;
    }

    // URL giống lần trước → skip
    if (_urlState?.url == url) return;

    // ── Bước 1: Nhận dạng nhanh bằng extension ──
    final quickResult = UrlMetadataFetcher.detectByExtension(url);

    if (quickResult.type == UrlContentType.image ||
        quickResult.type == UrlContentType.video) {
      // Extension rõ ràng → hiện preview ngay
      setState(() {
        _urlState = _UrlDetectState(
          url: url,
          contentType: quickResult.type,
          typeResult: quickResult,
          isFetching: false,
        );
      });
      return;
    }

    // ── Bước 2: URL không rõ extension → detect song song ──
    setState(() {
      _urlState = _UrlDetectState(url: url, isFetching: true);
    });

    // Detect type + fetch metadata song song
    final results = await Future.wait([
      UrlMetadataFetcher.detectType(url),
      UrlMetadataFetcher.fetch(url),
    ]);

    if (!mounted || _urlState?.url != url) return;

    final typeResult = results[0] as UrlTypeResult;
    final metadata = results[1] as UrlMetadata;

    setState(() {
      _urlState = _UrlDetectState(
        url: url,
        contentType: typeResult.type,
        typeResult: typeResult,
        metadata: typeResult.type == UrlContentType.web ? metadata : null,
        isFetching: false,
      );
    });
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
  // ★ SMART SEND — phân loại image / video / web
  // ----------------------------------------------------------

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final allUrls = UrlMetadataFetcher.extractAllUrls(text);

    if (allUrls.isEmpty || _urlState == null) {
      // ── Tin nhắn text thuần ──
      _sendTextMessage(text);
    } else {
      final detectedType = _urlState!.contentType;

      if (detectedType == UrlContentType.image) {
        // ── ★ URL là ảnh → gửi như tin nhắn ảnh ──
        _sendImageUrlMessage(text, allUrls);
      } else if (detectedType == UrlContentType.video) {
        // ── ★ URL là video → gửi như tin nhắn video ──
        _sendVideoUrlMessage(text, allUrls);
      } else {
        // ── URL là trang web → gửi như tin nhắn URL ──
        _sendWebUrlMessage(text, allUrls.first);
      }
    }

    // Reset input
    _textController.clear();
    _urlDetectTimer?.cancel();
    setState(() {
      _state = _state.copyWith(isEditing: false);
      _urlState = null;
    });
  }

  void _sendTextMessage(String text) {
    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Note = text
        ..Send_Date = DateTime.now(),
    );
  }

  void _sendImageUrlMessage(String text, List<String> imageUrls) {
    // Lọc chỉ giữ URL ảnh
    final imgUrls = <String>[];
    for (final url in imageUrls) {
      final result = UrlMetadataFetcher.detectByExtension(url);
      if (result.type == UrlContentType.image) {
        imgUrls.add(url);
      }
    }
    if (imgUrls.isEmpty) imgUrls.addAll(imageUrls);

    // Tách phần text không phải URL
    final extraText = _removeUrlsFromText(text, imageUrls);

    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = imgUrls
        ..strTypeFile = 'jpg'
        ..Note = extraText,
    );
  }

  void _sendVideoUrlMessage(String text, List<String> videoUrls) {
    final vidUrls = <String>[];
    for (final url in videoUrls) {
      final result = UrlMetadataFetcher.detectByExtension(url);
      if (result.type == UrlContentType.video) {
        vidUrls.add(url);
      }
    }
    if (vidUrls.isEmpty) vidUrls.addAll(videoUrls);

    final extraText = _removeUrlsFromText(text, videoUrls);

    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = vidUrls
        ..strTypeFile = 'mp4'
        ..Note = extraText,
    );
  }

  void _sendWebUrlMessage(String text, String url) {
    final msg = Chatmsgobject()
      ..Comment = "minhdc"
      ..isMe = true
      ..Note = text
      ..Send_Date = DateTime.now()
      ..strDataFile = [url]
      ..strTypeFile = 'url';

    // Gắn metadata nếu đã có
    if (_urlState?.metadata != null) {
      msg.titleUrl = _urlState!.metadata!.title;
      msg.descriptioneUrl = _urlState!.metadata!.description;
      msg.ImageUrl = _urlState!.metadata!.imageUrl;
    }

    widget.onSend(msg);

    // Nếu chưa có metadata → fetch async
    if (_urlState?.metadata == null) {
      _fetchMetadataLate(msg, url);
    }
  }

  String _removeUrlsFromText(String text, List<String> urls) {
    var result = text;
    for (final url in urls) {
      result = result.replaceAll(url, '');
      // Thử xoá cả dạng không có https://
      final noScheme = url
          .replaceFirst('https://', '')
          .replaceFirst('http://', '');
      result = result.replaceAll(noScheme, '');
    }
    return result.trim();
  }

  Future<void> _fetchMetadataLate(Chatmsgobject msg, String url) async {
    try {
      final metadata = await UrlMetadataFetcher.fetch(url);
      msg.titleUrl = metadata.title;
      msg.descriptioneUrl = metadata.description;
      msg.ImageUrl = metadata.imageUrl;
      widget.onRefreshMessages?.call();
    } catch (_) {}
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

          // ── ★ Smart URL Preview Card ──
          if (_urlState != null)
            _SmartUrlPreview(
              urlState: _urlState!,
              onDismiss: () => setState(() => _urlState = null),
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
// ★ Smart URL Preview — hiện khác nhau cho image/video/web
// ═══════════════════════════════════════════════════════════

class _SmartUrlPreview extends StatelessWidget {
  final _UrlDetectState urlState;
  final VoidCallback onDismiss;

  const _SmartUrlPreview({required this.urlState, required this.onDismiss});

  String get _domain {
    final uri = Uri.tryParse(urlState.url);
    return uri?.host ?? urlState.url;
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
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
            child: Row(
              children: [
                Icon(_headerIcon, size: 16, color: _headerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _headerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _headerColor,
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
          if (urlState.isFetching)
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
                    "Đang nhận dạng...",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

          // ── ★ Image preview ──
          if (!urlState.isFetching &&
              urlState.contentType == UrlContentType.image)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: Image.network(
                    urlState.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF0F2F5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF0F2F5),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── ★ Video preview ──
          if (!urlState.isFetching &&
              urlState.contentType == UrlContentType.video)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 80,
                  color: const Color(0xFF2D2D2D),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Video",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            urlState.typeResult?.extension?.toUpperCase() ??
                                'MP4',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── ★ Web metadata preview ──
          if (!urlState.isFetching &&
              urlState.contentType == UrlContentType.web &&
              urlState.metadata != null) ...[
            if (urlState.metadata!.imageUrl != null)
              SizedBox(
                width: double.infinity,
                height: 120,
                child: Image.network(
                  urlState.metadata!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (urlState.metadata!.title != null)
                    Text(
                      urlState.metadata!.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  if (urlState.metadata!.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        urlState.metadata!.description!,
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

          // ── Web loading (chưa có metadata) ──
          if (!urlState.isFetching &&
              urlState.contentType == UrlContentType.web &&
              urlState.metadata == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Text(
                "Trang web",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  IconData get _headerIcon {
    switch (urlState.contentType) {
      case UrlContentType.image:
        return Icons.image;
      case UrlContentType.video:
        return Icons.videocam;
      case UrlContentType.web:
      case null:
        return Icons.link;
    }
  }

  Color get _headerColor {
    switch (urlState.contentType) {
      case UrlContentType.image:
        return Colors.green.shade600;
      case UrlContentType.video:
        return Colors.orange.shade700;
      case UrlContentType.web:
      case null:
        return Colors.blue.shade600;
    }
  }

  String get _headerLabel {
    switch (urlState.contentType) {
      case UrlContentType.image:
        return 'Hình ảnh — $_domain';
      case UrlContentType.video:
        return 'Video — $_domain';
      case UrlContentType.web:
      case null:
        return _domain;
    }
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
