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
  //ChatmsgObjtype objtype => V_CheckType();
  List<String> strDataFile =
      []; // nếu kiểu image, video, file thì là strbase64 hoặc Url, url: là UrlFile
  //List<String>? strDataFiles = strDataFile.split(";");
  String strTypeFile = "";
  Chatmsgobject? replyMsg; // nội dung tinh nhắn trả lời

  bool isMe = false;
  bool isPinned = false;
  bool isRecalled = false;
  bool isUploading = false;
  double uploadProgress = 0;
  String status = ""; // sent, received, read

  ChatmsgObjtype objtype() {
    if (strTypeFile.isEmpty) return ChatmsgObjtype.tex;
    strTypeFile = strTypeFile.toLowerCase();
    if (strTypeFile == "url") return ChatmsgObjtype.url;
    List<String> fileVideo = ["mp4", "mov", "avi", "mkv", "webm", "3gp"];
    List<String> isImage = ["jpg", "jpeg", "png", "gif", "webp", "bmp"];
    List<String> isPdf = ["pdf"];
    List<String> isDoc = ["doc"];
    List<String> isExcel = ["xls", "xlsx"];
    if (fileVideo.contains(strTypeFile)) return ChatmsgObjtype.video;
    if (isImage.contains(strTypeFile)) return ChatmsgObjtype.image;
    if (isPdf.contains(strTypeFile)) return ChatmsgObjtype.pdf;
    if (isDoc.contains(strTypeFile)) return ChatmsgObjtype.doc;
    if (isExcel.contains(strTypeFile)) return ChatmsgObjtype.excel;

    return ChatmsgObjtype.file;
  }
}

enum ChatmsgObjtype { tex, image, video, pdf, doc, excel, file, url }

// viết class menu
class ChatMenu {
  List<ChatItemMenu>? ChatItemMenus;
}

class ChatItemMenu {
  String? Id;
  String? IconName;
  String? Caption;
}
