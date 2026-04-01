import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_audio.dart';
import 'package:flutter_chat/Component/chat_attach_menu.dart';
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
  final UrlContentType? contentType;
  final UrlTypeResult? typeResult;
  final UrlMetadata? metadata;
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
    required this.showAttachMenu, // ★ NEW
    required this.onShowEmojiChanged,
    required this.onShowGalleryChanged,
    required this.onShowAttachMenuChanged,
    FocusNode? this.externalFocusNode, // ★ NEW
    this.onRefreshMessages,
  });

  final ValueChanged<Chatmsgobject> onSend;
  final VoidCallback? onRefreshMessages;
  final bool showEmoji;
  final bool showGallery;
  final bool showAttachMenu; // ★ NEW
  final ValueChanged<bool> onShowEmojiChanged;
  final ValueChanged<bool> onShowGalleryChanged;
  final ValueChanged<bool> onShowAttachMenuChanged;
  //Thêm focus node từ ngoài
  final FocusNode? externalFocusNode; // ★ NEW

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  late final FocusNode _focusNode;
  late final bool _isExternalFocusNode;
  @override
  void initState() {
    super.initState();
    _isExternalFocusNode = widget.externalFocusNode != null;
    _focusNode = widget.externalFocusNode ?? FocusNode();
  }

  var _state = const ChatInputState();

  // ── URL detect state ──
  _UrlDetectState? _urlState;
  Timer? _urlDetectTimer;

  // ── Voice recording state ──
  final _voiceController = VoiceRecorderController();
  bool _isRecording = false;

  @override
  void dispose() {
    _urlDetectTimer?.cancel();
    _textController.dispose();
    if (!_isExternalFocusNode) {
      _focusNode.dispose();
    }
    _voiceController.dispose();
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

    if (url == null) {
      if (_urlState != null) setState(() => _urlState = null);
      return;
    }

    if (_urlState?.url == url) return;

    final quickResult = UrlMetadataFetcher.detectByExtension(url);

    if (quickResult.type == UrlContentType.image ||
        quickResult.type == UrlContentType.video) {
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

    setState(() {
      _urlState = _UrlDetectState(url: url, isFetching: true);
    });

    try {
      final results = await Future.wait([
        UrlMetadataFetcher.detectType(url),
        UrlMetadataFetcher.fetch(url),
      ]).timeout(const Duration(seconds: 10));

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
    } catch (_) {
      if (!mounted || _urlState?.url != url) return;
      setState(() {
        _urlState = _UrlDetectState(
          url: url,
          contentType: UrlContentType.web,
          isFetching: false,
        );
      });
    }
  }

  // ----------------------------------------------------------
  // Panel management
  // ----------------------------------------------------------

  void _closeAllPanels() {
    widget.onShowEmojiChanged(false);
    widget.onShowGalleryChanged(false);
    widget.onShowAttachMenuChanged(false);
  }

  void _onTextFieldTapped() {
    _closeAllPanels();
  }

  void _onEmojiToggled() {
    final willShow = !widget.showEmoji;
    widget.onShowEmojiChanged(willShow);
    widget.onShowGalleryChanged(false);
    widget.onShowAttachMenuChanged(false);
    if (willShow) _focusNode.unfocus();
  }

  void _onAttachMenuToggled() {
    final willShow = !widget.showAttachMenu;
    widget.onShowAttachMenuChanged(willShow);
    widget.onShowEmojiChanged(false);
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
    widget.onShowAttachMenuChanged(false);
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
  // Voice Recording
  // ----------------------------------------------------------

  Future<void> _onMicPressed() async {
    if (_isRecording) return;

    _closeAllPanels();
    _focusNode.unfocus();

    final ok = await _voiceController.start();
    if (ok) {
      setState(() => _isRecording = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Không thể thu âm. Vui lòng cấp quyền microphone.'),
            ),
          );
      }
    }
  }

  Future<void> _onVoiceSend() async {
    final result = await _voiceController.stop();
    setState(() => _isRecording = false);

    if (result == null) return;

    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = [result.base64Data]
        ..strTypeFile = 'voice'
        ..audioDurationSeconds = result.durationSeconds
        ..Note = '',
    );
  }

  Future<void> _onVoiceCancel() async {
    await _voiceController.cancel();
    setState(() => _isRecording = false);
  }

  // ----------------------------------------------------------
  // SMART SEND
  // ----------------------------------------------------------

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final allUrls = UrlMetadataFetcher.extractAllUrls(text);

    if (allUrls.isEmpty || _urlState == null) {
      _sendTextMessage(text);
    } else {
      final detectedType = _urlState!.contentType;

      if (detectedType == UrlContentType.image) {
        _sendImageUrlMessage(text, allUrls);
      } else if (detectedType == UrlContentType.video) {
        _sendVideoUrlMessage(text, allUrls);
      } else {
        _sendWebUrlMessage(text, allUrls.first);
      }
    }

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
    final imgUrls = <String>[];
    for (final url in imageUrls) {
      final result = UrlMetadataFetcher.detectByExtension(url);
      if (result.type == UrlContentType.image) imgUrls.add(url);
    }
    if (imgUrls.isEmpty) imgUrls.addAll(imageUrls);

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
      if (result.type == UrlContentType.video) vidUrls.add(url);
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

    if (_urlState?.metadata != null) {
      msg.titleUrl = _urlState!.metadata!.title;
      msg.descriptioneUrl = _urlState!.metadata!.description;
      msg.ImageUrl = _urlState!.metadata!.imageUrl;
      msg.isUrlFetchDone = true;
    }

    widget.onSend(msg);

    if (!msg.isUrlFetchDone) {
      _fetchMetadataLate(msg, url);
    }
  }

  String _removeUrlsFromText(String text, List<String> urls) {
    var result = text;
    for (final url in urls) {
      result = result.replaceAll(url, '');
      final noScheme = url
          .replaceFirst('https://', '')
          .replaceFirst('http://', '');
      result = result.replaceAll(noScheme, '');
    }
    return result.trim();
  }

  Future<void> _fetchMetadataLate(Chatmsgobject msg, String url) async {
    try {
      final metadata = await UrlMetadataFetcher.fetch(
        url,
      ).timeout(const Duration(seconds: 10));
      msg.titleUrl = metadata.title;
      msg.descriptioneUrl = metadata.description;
      msg.ImageUrl = metadata.imageUrl;
    } catch (_) {
    } finally {
      msg.isUrlFetchDone = true;
      widget.onRefreshMessages?.call();
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
    final showAttachMenu = widget.showAttachMenu && !_state.isEditing;

    // Khi đang thu âm → hiện overlay ghi âm
    if (_isRecording) {
      return ChatVoiceRecordingOverlay(
        controller: _voiceController,
        onCancel: _onVoiceCancel,
        onSend: _onVoiceSend,
      );
    }

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
          // ── Smart URL Preview Card ──
          if (_urlState != null)
            _SmartUrlPreview(
              urlState: _urlState!,
              onDismiss: () => setState(() => _urlState = null),
            ),

          // ── Input Row ──
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
            onMicPressed: _onMicPressed,
            onAttachMenuPressed: _onAttachMenuToggled, // ★
          ),

          // ── Emoji Panel ──
          if (widget.showEmoji)
            SizedBox(
              height: 300,
              child: ChatEmojiPanel(
                onEmojiSelected: _onEmojiSelected,
                onStickerSelected: _onStickerSelected,
              ),
            ),

          // ── Gallery Panel ──
          if (showGallery)
            _GalleryGrid(
              assets: _state.assets,
              selectedAssets: _state.selectedAssets,
              onAssetToggled: _onAssetToggled,
              onCameraPressed: _onCameraPressed,
              onConfirm: _onSendImages,
            ),

          // ── ★ Attach Menu Panel (Zalo-style grid) ──
          if (showAttachMenu) ChatAttachMenuPanel(onSend: widget.onSend),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ★ Smart URL Preview
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
// Các widget con
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
  final VoidCallback onMicPressed;
  final VoidCallback onAttachMenuPressed; // ★

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
    required this.onMicPressed,
    required this.onAttachMenuPressed,
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
          // ★ Nút ••• (more) — giống Zalo
          _IconBtn(icon: Icons.more_horiz, onPressed: onAttachMenuPressed),
          _IconBtn(icon: Icons.mic, onPressed: onMicPressed),
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
