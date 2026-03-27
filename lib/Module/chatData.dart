import 'package:flutter_chat/chat_frame.dart';

List<User_name> User_Names = [
  User_name()
    ..User_Name = "MinhDc"
    ..Comment = "Đào Chí minh",
  User_name()
    ..User_Name = "MinhNQ"
    ..Comment = "Nguyễn Quang Minh",
  User_name()
    ..User_Name = "LinhNv"
    ..Comment = "Nguyễn Văn Linh",
  User_name()
    ..User_Name = "TrungHL"
    ..Comment = "Hồ Lê Trung",
  User_name()
    ..User_Name = "DungNt"
    ..Comment = "Nguyễn Tiến Dũng",
];
List<ChatGroup> ChatGroups = [];

List<ChatMenu> ChatMenus = [];

List<Chatmsgobject> Chatmsgobjects = [
  Chatmsgobject()
    ..Comment = "abcds"
    ..IdMsg = "1"
    ..Note =
        "Cơ quan điều hành quyết định giảm 2.040 đồng/lít với xăng E5 RON 92 và giảm 3.890 đồng/lít với xăng RON 95. Sau điều chỉnh, giá bán lẻ với xăng E5 RON 92 là 28.070 đồng/lít và xăng RON 95 là 29.950 đồng/lít."
    ..Send_Date = DateTime.now()
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..IdMsg = "2"
    ..Note = "xd"
    ..Send_Date = DateTime.now()
    ..isMe = false,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..Note = "Test video network abc abc"
    ..IdMsg = "3"
    ..Send_Date = DateTime.now()
    ..strDataFile = [
      "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    ]
    ..strTypeFile = "mp4"
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..Note = "Mở link preview"
    ..IdMsg = "4"
    ..Send_Date = DateTime.now()
    ..strDataFile = ["https://openai.com"]
    ..strTypeFile = "url"
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..Note = "Link ảnh"
    ..IdMsg = "5"
    ..Send_Date = DateTime.now()
    ..strDataFile = [
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
      // "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200"
    ]
    ..strTypeFile = "jpg"
    ..isMe = false,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..Note = "Link file"
    ..IdMsg = "6"
    ..Send_Date = DateTime.now()
    ..strDataFile = ["https://www.orimi.com/pdf-test.pdf"]
    ..strTypeFile = "pdf"
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..Note = "abc.com"
    ..IdMsg = "7"
    ..Send_Date = DateTime.now()
    ..isMe = true,
  // Chatmsgobject()
  //   ..Comment = "Nguyễn Quang Minh"
  //   ..Note = "test reply"
  //   ..IdMsg = "8"
  //   ..Send_Date = DateTime.now()
  //   ..isMe = true
  //   ..replyMsg = Chatmsgobject() ..Note = "ádsd"
];
