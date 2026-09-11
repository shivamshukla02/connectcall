import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/zego_config.dart';
import '../../providers/auth_providers.dart';
import '../../providers/call_providers.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({
    super.key,
    required this.callId,
    required this.receiverName,
    required this.callType,
  });

  final String callId;
  final String receiverName;
  final CallType callType;

  @override
  ConsumerState<OutgoingCallScreen> createState() =>
      _OutgoingCallScreenState();
}

class _OutgoingCallScreenState
    extends ConsumerState<OutgoingCallScreen> {
  bool _handled = false;
  Timer? _ringTimeout;

  @override
  void initState() {
    super.initState();
    _ringTimeout = Timer(
      const Duration(seconds: 30),
      _timeoutAsMissed,
    );
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    super.dispose();
  }

  Future<void> _timeoutAsMissed() async {
    if (_handled) return;

    _handled = true;

    await ref.read(callServiceProvider).markMissed(widget.callId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.receiverName} did not answer'),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _cancel() async {
    if (_handled) return;

    _handled = true;
    _ringTimeout?.cancel();

    await ref.read(callServiceProvider).endCall(
          widget.callId,
          startedAt: DateTime.now(),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callStream =
        ref.read(callServiceProvider).watchCall(widget.callId);

    return StreamBuilder(
      stream: callStream,
      builder: (context, snapshot) {
        final call = snapshot.data;

        if (call != null && !_handled) {
          if (call.status == CallStatus.calling) {
            _handled = true;
            _ringTimeout?.cancel();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              final Widget screen =
                  widget.callType == CallType.video
                      ? VideoCallScreen(
                          callId: widget.callId,
                          otherUserName: widget.receiverName,
                        )
                      : AudioCallScreen(
                          callId: widget.callId,
                          otherUserName: widget.receiverName,
                        );

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => screen,
                ),
              );
            });
          } else if (call.status == CallStatus.rejected) {
            _handled = true;
            _ringTimeout?.cancel();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.receiverName} declined the call',
                  ),
                ),
              );

              Navigator.of(context).pop();
            });
          }
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _cancel();
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.callType == CallType.video
                          ? 'Video Calling...'
                          : 'Calling...',
                    ),
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 56,
                      child: Text(
                        widget.receiverName.isNotEmpty
                            ? widget.receiverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.receiverName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 40),
                    InkWell(
                      onTap: _cancel,
                      customBorder: const CircleBorder(),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Cancel'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AudioCallScreen extends ConsumerStatefulWidget {
  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
  });

  final String callId;
  final String otherUserName;

  @override
  ConsumerState<AudioCallScreen> createState() =>
      _AudioCallScreenState();
}

class _AudioCallScreenState
    extends ConsumerState<AudioCallScreen> {
  late final DateTime _joinedAt;
  bool _cleanedUp = false;

  @override
  void initState() {
    super.initState();
    _joinedAt = DateTime.now();
  }

  Future<void> _handleCallEnded(
    VoidCallback defaultAction,
  ) async {
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
    final myName =
        ref.read(currentUserProvider).value?.name ?? 'Me';

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Not signed in — cannot start call.',
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCallEnded(() {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      child: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appId,
        appSign: ZegoConfig.appSign,
        userID: me.uid,
        userName: myName,
        callID: widget.callId,
        config:
            ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
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
  ConsumerState<VideoCallScreen> createState() =>
      _VideoCallScreenState();
}

class _VideoCallScreenState
    extends ConsumerState<VideoCallScreen> {
  late final DateTime _joinedAt;
  bool _cleanedUp = false;

  @override
  void initState() {
    super.initState();
    _joinedAt = DateTime.now();
  }

  Future<void> _handleCallEnded(
    VoidCallback defaultAction,
  ) async {
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
    final myName =
        ref.read(currentUserProvider).value?.name ?? 'Me';

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Not signed in — cannot start call.',
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCallEnded(() {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      child: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appId,
        appSign: ZegoConfig.appSign,
        userID: me.uid,
        userName: myName,
        callID: widget.callId,
        config:
            ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) =>
              _handleCallEnded(defaultAction),
        ),
      ),
    );
  }
}
