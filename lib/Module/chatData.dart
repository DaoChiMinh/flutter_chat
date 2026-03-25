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
    ..Comment = "Nguyễn Quang Minh"
    ..IdMsg = "1"
    ..Note =
        "Cơ quan điều hành quyết định giảm 2.040 đồng/lít với xăng E5 RON 92 và giảm 3.890 đồng/lít với xăng RON 95. Sau điều chỉnh, giá bán lẻ với xăng E5 RON 92 là 28.070 đồng/lít và xăng RON 95 là 29.950 đồng/lít."
    ..Send_Date = DateTime.now()
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..IdMsg = "2"
    ..Note =
        "Cơ quan điều hành quyết định giảm 2.040 đồng/lít với xăng E5 RON 92 và giảm 3.890 đồng/lít với xăng RON 95. Sau điều chỉnh, giá bán lẻ với xăng E5 RON 92 là 28.070 đồng/lít và xăng RON 95 là 29.950 đồng/lít."
    ..Send_Date = DateTime.now()
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..IdMsg = "3"
    ..Note =
        "Cơ quan điều hành quyết định giảm 2.040 đồng/lít với xăng E5 RON 92 và giảm 3.890 đồng/lít với xăng RON 95. Sau điều chỉnh, giá bán lẻ với xăng E5 RON 92 là 28.070 đồng/lít và xăng RON 95 là 29.950 đồng/lít."
    ..Send_Date = DateTime.now()
    ..isMe = true,
  Chatmsgobject()
    ..Comment = "Nguyễn Quang Minh"
    ..IdMsg = "4"
    ..Note =
        "xd"
    ..Send_Date = DateTime.now()
    ..isMe = false,
];
