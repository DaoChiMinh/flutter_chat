import 'package:flutter/material.dart';
import 'package:flutter_chat/Module/chatobj.dart';

String buildTitle(String type) {
  switch (type) {
    case "pdf":
      return "PDF";
    case "doc":
    case "docx":
      return "Word";
    case "xls":
    case "xlsx":
      return "Excel";
    case "ppt":
    case "pptx":
      return "PowerPoint";
    default:
      return "Tệp";
  }
}

bool shouldShowForwardIcon(ChatmsgObjtype type) {
  return [
    ChatmsgObjtype.image,
    ChatmsgObjtype.video,
    ChatmsgObjtype.pdf,
    ChatmsgObjtype.doc,
    ChatmsgObjtype.excel,
    ChatmsgObjtype.file,
    ChatmsgObjtype.url,
    ChatmsgObjtype.audio,
  ].contains(type);
}

bool isFileType(ChatmsgObjtype type) {
  return [
    ChatmsgObjtype.pdf,
    ChatmsgObjtype.doc,
    ChatmsgObjtype.excel,
    ChatmsgObjtype.file,
  ].contains(type);
}

bool shouldShowNoteText(ChatmsgObjtype type) {
  return type == ChatmsgObjtype.tex ||
      type == ChatmsgObjtype.image ||
      type == ChatmsgObjtype.video;
}

String formatDate(DateTime? dt) {
  if (dt == null) return "";
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return "$hh:$mm";
}

void showSnackBar(BuildContext context, String text) {
  final height = MediaQuery.of(context).size.height;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: height * 0.4, left: 80, right: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        elevation: 0,
      ),
    );
}

//popup confirm delete message
Future<bool> confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Xóa tin nhắn?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bạn có chắc muốn xóa tin nhắn này không?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
