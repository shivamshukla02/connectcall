import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/zego_config.dart';
import '../../models/call_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/call_providers.dart';
import '../../services/permission_service.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key, required this.call});

  final CallModel call;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _responding = false;

  Future<void> _accept() async {
    setState(() => _responding = true);

    final isVideo = widget.call.type == CallType.video;

    final permission = isVideo
        ? await PermissionService.requestAudioAndVideo()
        : await PermissionService.requestMicrophone();

    if (permission != PermissionOutcome.granted) {
      if (!mounted) return;

      setState(() => _responding = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isVideo ? 'Camera and microphone' : 'Microphone'} permission is required to accept this call.',
          ),
        ),
      );
      return;
    }

    await ref
        .read(callServiceProvider)
        .updateStatus(widget.call.callId, CallStatus.calling);

    if (!mounted) return;

    if (isVideo) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            callId: widget.call.callId,
            otherUserName: widget.call.callerName,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AudioCallScreen(
          callId: widget.call.callId,
          otherUserName: widget.call.callerName,
        ),
      ),
    );
  }

  Future<void> _reject() async {
    setState(() => _responding = true);

    await ref
        .read(callServiceProvider)
        .updateStatus(widget.call.callId, CallStatus.rejected);

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.call.type == CallType.video;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Text(
                isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 56,
                child: Text(
                  widget.call.callerName.isNotEmpty
                      ? widget.call.callerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.call.callerName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onPressed: _responding ? null : _reject,
                  ),
                  _CallActionButton(
                    icon: isVideo ? Icons.videocam : Icons.call,
                    color: Colors.green,
                    label: 'Accept',
                    onPressed: _responding ? null : _accept,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
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
