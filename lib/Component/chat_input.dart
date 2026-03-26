import 'package:flutter/material.dart';
import 'package:flutter_chat/Component/chat_emoji.dart';
import 'package:flutter_chat/Module/chatobj.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

// ============================================================
// MODEL
// ============================================================

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

// ============================================================
// MAIN WIDGET
// ============================================================

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    required this.showEmoji,
    required this.showGallery,
    required this.onShowEmojiChanged,
    required this.onShowGalleryChanged,
  });

  final ValueChanged<Chatmsgobject> onSend;
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

  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Actions
  // ----------------------------------------------------------

  void _onTextChanged(String value) {
    setState(() => _state = _state.copyWith(isEditing: value.isNotEmpty));
  }

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

  void _onStickerSelected(Sticker _sticker) {
    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Send_Date = DateTime.now()
        ..strDataFile = [_sticker.url]
        ..strTypeFile = 'gif'
        ..Note = '',
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

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSend(
      Chatmsgobject()
        ..Comment = "minhdc"
        ..isMe = true
        ..Note = text
        ..Send_Date = DateTime.now(),
    );

    _textController.clear();
    // _focusNode.unfocus();
    setState(() => _state = _state.copyWith(isEditing: false));
  }

  Future<void> _onSendImages() async {
    if (_state.selectedAssets.isEmpty) return;

    for (final asset in _state.selectedAssets) {
      final file = await asset.file;
      if (file == null) continue;

      widget.onSend(
        Chatmsgobject()
          ..Comment = "minhdc"
          ..isMe = true
          ..Send_Date = DateTime.now()
          ..strDataFile = [file.path]
          ..strTypeFile = asset.mimeType?.split('/').last ?? 'jpg'
          ..Note = '',
      );
    }

    widget.onShowGalleryChanged(false);
    setState(() => _state = _state.copyWith(selectedAssets: []));
  }

  // ----------------------------------------------------------
  // Data
  // ----------------------------------------------------------

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
        spacing: 8,
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

// ============================================================
// SUB WIDGETS
// ============================================================

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

// ----------------------------------------------------------

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

// ----------------------------------------------------------

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

// ----------------------------------------------------------

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

// ----------------------------------------------------------

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

// ----------------------------------------------------------

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
