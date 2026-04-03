import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';

class ChatCall extends StatelessWidget {
  const ChatCall({super.key});
  Future<void> testIncomingCall() async {
    final id = const Uuid().v4();

    final params = CallKitParams(
      id: id,
      nameCaller: 'Nguyen Van A',
      appName: 'Chat App',
      handle: '0839783643',
      type: 0,
      duration: 30000,
      textAccept: 'Nghe',
      textDecline: 'Từ chối',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        isShowFullLockedScreen: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
        isShowCallID: true,
      ),
      ios: const IOSParams(handleType: 'generic', supportsVideo: false),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> testOutgoingCall() async {
    final id = const Uuid().v4();

    final params = CallKitParams(
      id: id,
      nameCaller: 'Nguyen Van A',
      handle: '0839783643',
      type: 0,
      extra: const {'userId': '123'},
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Calling...',
        callbackText: 'Hang Up',
      ),
      android: const AndroidParams(
        isCustomNotification: false,
        isShowCallID: true,
      ),
      ios: const IOSParams(handleType: 'generic'),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        debugPrint('ICON TAPPED');
        await testIncomingCall();
      },
      icon: const Icon(Icons.phone, color: Colors.white),
      tooltip: 'Gọi điện',
    );
  }
}
