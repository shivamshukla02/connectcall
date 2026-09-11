import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/zego_config.dart';
import '../../providers/auth_providers.dart';
import '../../providers/call_providers.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
  });

  final String callId;
  final String otherUserName;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  late final DateTime _joinedAt;
  bool _cleanedUp = false;

  @override
  void initState() {
    super.initState();
    _joinedAt = DateTime.now();
  }

  Future<void> _handleCallEnded(VoidCallback defaultAction) async {
    if (_cleanedUp) {
      defaultAction();
      return;
    }

    _cleanedUp = true;

    try {
      await ref.read(callServiceProvider).endCall(
            widget.callId,
            startedAt: _joinedAt,
          );
    } catch (_) {}

    defaultAction();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.read(authServiceProvider).currentUser;
    final myName = ref.read(currentUserProvider).value?.name ?? 'Me';

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not signed in — cannot start call.'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCallEnded(() {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appId,
        appSign: ZegoConfig.appSign,
        userID: me.uid,
        userName: myName,
        callID: widget.callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) =>
              _handleCallEnded(defaultAction),
        ),
      ),
    );
  }
}
