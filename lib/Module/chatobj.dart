//chatzoom
class User_name {
  String User_Name = "";
  String Comment = "";
  List<String>? Friends;
  List<String>? Groups;
}

class ChatGroup {
  String Idgroup = "";
  String Ten_group = "";
  List<String>? User_names;
  List<String>? Administrators;
}

class Chatmsgobject {
  String User_Name = ""; // tài khoản người gửi dữ liệu
  String Comment = ""; // tên người dùng
  String IdMsg = "";
  String Idgroup = "";
  String Note = ""; //noi dung
  DateTime? Send_Date;
  List<String> strDataFile = [];
  String strTypeFile = "";
  Chatmsgobject? replyMsg; // nội dung tin nhắn trả lời

  bool isMe = false;
  bool isPinned = false;
  bool isRecalled = false;
  bool isUploading = false;
  double uploadProgress = 0;
  String status = ""; // sent, received, read

  // ── URL Preview metadata ──
  String? ImageUrl; // đường link ảnh preview
  String? titleUrl; // tiêu đề trang web
  String? descriptioneUrl; // mô tả trang web

  /// Đánh dấu đã fetch xong (thành công hoặc thất bại) → ẩn loading
  bool isUrlFetchDone = false;

  /// Kiểm tra đã có metadata preview chưa
  bool get hasUrlPreview =>
      titleUrl != null || descriptioneUrl != null || ImageUrl != null;

  /// Còn đang loading preview không?
  /// false khi: đã fetch xong HOẶC đã có metadata
  bool get isUrlLoading => !isUrlFetchDone && !hasUrlPreview;

  ChatmsgObjtype objtype() {
    if (strTypeFile.isEmpty) return ChatmsgObjtype.tex;

    strTypeFile = strTypeFile.toLowerCase();
    if (strTypeFile == "url") return ChatmsgObjtype.url;
    List<String> fileVideo = ["mp4", "mov", "avi", "mkv", "webm", "3gp"];
    List<String> isImage = ["jpg", "jpeg", "png", "gif", "webp", "bmp"];
    List<String> isPdf = ["pdf"];
    List<String> isDoc = ["doc", "docx"];
    List<String> sticker = ["stiker"];
    List<String> isExcel = ["xls", "xlsx"];
    if (fileVideo.contains(strTypeFile)) return ChatmsgObjtype.video;
    if (isImage.contains(strTypeFile)) return ChatmsgObjtype.image;
    if (isPdf.contains(strTypeFile)) return ChatmsgObjtype.pdf;
    if (isDoc.contains(strTypeFile)) return ChatmsgObjtype.doc;
    if (isExcel.contains(strTypeFile)) return ChatmsgObjtype.excel;
    if (sticker.contains(strTypeFile)) return ChatmsgObjtype.stiker;
    return ChatmsgObjtype.file;
  }

  String get file {
    if (strDataFile.isEmpty) return "";
    return strDataFile.first;
  }
}

enum ChatmsgObjtype { tex, image, video, pdf, doc, excel, file, url, stiker }

class ChatMenu {
  List<ChatItemMenu>? ChatItemMenus;
}

class ChatItemMenu {
  String? Id;
  String? IconName;
  String? Caption;
}
