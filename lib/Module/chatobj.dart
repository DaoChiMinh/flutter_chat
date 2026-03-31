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
  String User_Name = "";
  String Comment = "";
  String IdMsg = "";
  String Idgroup = "";
  String Note = "";
  DateTime? Send_Date;
  List<String> strDataFile = [];
  String strTypeFile = "";
  Chatmsgobject? replyMsg;

  bool isMe = false;
  bool isPinned = false;
  bool isRecalled = false;
  bool isUploading = false;
  double uploadProgress = 0;
  String status = "";

  String? ImageUrl;
  String? titleUrl;
  String? descriptioneUrl;

  bool isUrlFetchDone = false;

  int audioDurationSeconds = 0;

  // ★ REACTION
  List<ChatReaction> reactions = [];

  bool get hasReaction => reactions.isNotEmpty;

  /// Tổng reaction
  int get reactionCount => reactions.length;

  /// getEmoji
  List<String> get getEmojiList {
    final result = <String>[];
    for (final r in reactions) {
      if (!result.contains(r.emoji)) {
        result.add(r.emoji);
      }
    }
    return result;
  }

  void setReaction(String userName, String emoji) {
    reactions.removeWhere((e) => e.userName == userName);

    reactions.add(
      ChatReaction(emoji: emoji, userName: userName, createdAt: DateTime.now()),
    );
  }

  /// Danh sách emoji unique + count
  Map<String, int> get reactionSummary {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }

  void removeReactionOfUser(String userName) {
    reactions.removeWhere((e) => e.userName == userName);
  }

  /// Group theo user -> list emoji
  Map<String, List<String>> get reactionByUser {
    final map = <String, List<String>>{};
    for (final r in reactions) {
      map.putIfAbsent(r.userName, () => []);
      if (!map[r.userName]!.contains(r.emoji)) {
        map[r.userName]!.add(r.emoji);
      }
    }
    return map;
  }

  bool get hasUrlPreview =>
      titleUrl != null || descriptioneUrl != null || ImageUrl != null;

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
    List<String> isAudio = ["m4a", "mp3", "wav", "aac", "ogg", "voice"];

    if (fileVideo.contains(strTypeFile)) return ChatmsgObjtype.video;
    if (isImage.contains(strTypeFile)) return ChatmsgObjtype.image;
    if (isPdf.contains(strTypeFile)) return ChatmsgObjtype.pdf;
    if (isDoc.contains(strTypeFile)) return ChatmsgObjtype.doc;
    if (isExcel.contains(strTypeFile)) return ChatmsgObjtype.excel;
    if (sticker.contains(strTypeFile)) return ChatmsgObjtype.stiker;
    if (isAudio.contains(strTypeFile)) return ChatmsgObjtype.audio;
    return ChatmsgObjtype.file;
  }

  String get file {
    if (strDataFile.isEmpty) return "";
    return strDataFile.first;
  }
}

enum ChatmsgObjtype {
  tex,
  image,
  video,
  pdf,
  doc,
  excel,
  file,
  url,
  stiker,
  audio, // ★ Tin nhắn thoại
}

// class ChatMenu {
//   List<ChatItemMenu>? ChatItemMenus;
// }

// class ChatItemMenu {
//   String? Id;
//   String? IconName;
//   String? Caption;
// }

class ChatReaction {
  final String emoji;
  final String userName;
  final DateTime createdAt;

  ChatReaction({
    required this.emoji,
    required this.userName,
    required this.createdAt,
  });
}
