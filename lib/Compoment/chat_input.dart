import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});
  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _textController;
  final focusNode = FocusNode();
  bool isEdit = false;
  bool isShowChonAnh = false;
  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _chatInput();
  }

  Widget _chatInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, -4),
            blurRadius: 10,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  color: const Color(0xff9E9E9E),
                  iconSize: 28,
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  child: TextField(
                    controller: _textController,
                    focusNode: focusNode,
                    onTap: () {
                      setState(() {
                        isShowChonAnh = false;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Nhập tin nhắn",
                      hintStyle: TextStyle(color: Color(0xff9E9E9E)),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isEdit = value.isNotEmpty;
                      });
                    },
                    minLines: 1,
                    maxLines: 2,
                  ),
                ),
              ),
              if (!isEdit) ...[
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                    color: const Color(0xff9E9E9E),
                    iconSize: 28,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () async {
                      await loadPhoto();
                      setState(() {
                        isShowChonAnh = !isShowChonAnh;

                        if (isShowChonAnh) {
                          focusNode.unfocus();
                        }
                      });
                    },
                    icon: const Icon(Icons.image),
                    color: const Color(0xff9E9E9E),
                    iconSize: 28,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 36,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xff009EF9),
                    iconSize: 28,
                  ),
                ),
              ],
            ],
          ),
          ShowChonAnh(),
        ],
      ),
    );
  }

  Widget ShowChonAnh() {
    if (_textController.text.isNotEmpty) return SizedBox.shrink();
    if (isShowChonAnh == false) return SizedBox.shrink();

    return Container(
      height: 360,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 cột như Zalo
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _assets.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCameraCell();
          }

          return ImageChon(_assets[index - 1]);
        },
      ),
    );
  }

  Widget _buildCameraCell() {
    return GestureDetector(
      onTap: () => _openCamera(),
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
            SizedBox(height: 6),
            Text(
              'Chụp ảnh',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await loadPhoto();
    }
  }

  List<AssetEntity> _assets = [];
  List<AssetEntity> _assetsSelect = [];
  Widget ImageChon(AssetEntity _itemassets) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_assetsSelect.contains(_itemassets)) {
            _assetsSelect.remove(_itemassets);
          } else {
            _assetsSelect.add(_itemassets);
          }
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AssetEntityImage(
              _itemassets,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(300, 300),
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: _assetsSelect.contains(_itemassets)
                  ? Colors.black.withOpacity(0.6)
                  : Colors.transparent,
            ),
          ),

          Positioned(
            right: 6,
            top: 6,
            child: Icon(
              _assetsSelect.contains(_itemassets)
                  ? Icons.check_circle_outline
                  : Icons.circle_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadPhoto() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    // Lấy tất cả album
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListPaged(page: 0, size: 80);
    setState(() => _assets = assets);
  }

  @override
  void dispose() {
    _textController.dispose();
    // _textController = null;
    super.dispose();
  }
}
