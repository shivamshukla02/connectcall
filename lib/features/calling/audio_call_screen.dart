import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/zego_config.dart';
import '../../providers/auth_providers.dart';
import '../../providers/call_providers.dart';

/// This is where the actual ZEGOCLOUD RTC join/publish/leave/dispose
/// happens. Firestore (CallService) only tracked signaling state up to
/// this point — everything below is the live media session.
///
/// Room ID = the Firestore call doc id. Both caller and callee arrive
/// here holding the exact same [callId] (caller from createCall()'s
/// return value, callee from the same doc via watchIncomingCalls), so
/// they always land in the same ZEGOCLOUD room. No second ID scheme.
class AudioCallScreen extends ConsumerStatefulWidget {
  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
  });

  final String callId;
  final String otherUserName;

  @override
  ConsumerState<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends ConsumerState<AudioCallScreen> {
  late final DateTime _joinedAt;
  bool _cleanedUp = false;

  @override
  void initState() {
    super.initState();
    _joinedAt = DateTime.now();
  }

  /// Shared cleanup for every way a call can end: local hang-up, remote
  /// hang-up, remote leaving the room (only-self-in-room), or being
  /// kicked. v4 of the SDK consolidates all of these into one
  /// onCallEnd callback, differentiated by event.reason — we don't need
  /// to branch on the reason ourselves since the Firestore-side cleanup
  /// (mark ended, record duration) is identical regardless of why the
  /// call ended.
  Future<void> _handleCallEnded(VoidCallback defaultAction) async {
    if (_cleanedUp) {
      defaultAction();
      return;
    }
    _cleanedUp = true;
    try {
      await ref
          .read(callServiceProvider)
          .endCall(widget.callId, startedAt: _joinedAt);
    } catch (_) {
      // Best-effort: even if the Firestore write fails (e.g. offline),
      // we still want to leave the RTC room and pop back.
    }
    // defaultAction() is the SDK's own "return to previous page" logic —
    // required per ZEGOCLOUD docs: if you override onCallEnd you MUST
    // call this (or navigate yourself) or the user gets stuck on the
    // call screen.
    defaultAction();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.read(authServiceProvider).currentUser;
    final myName = ref.read(currentUserProvider).value?.name ?? 'Me';

    if (me == null) {
      // Shouldn't happen (this screen is only reachable while signed in),
      // but fail safely instead of crashing into an invalid RTC join.
      return const Scaffold(
        body: Center(child: Text('Not signed in — cannot start call.')),
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
        // oneOnOneVoiceCall(): audio-only, no camera permission requested,
        // matches Phase 5 scope exactly (video is Phase 6).
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) =>
              _handleCallEnded(defaultAction),
        ),
      ),
    );
  }
}

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
          child: Text('Not signed in � cannot start call.'),
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
