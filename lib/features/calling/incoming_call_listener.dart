import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/call_model.dart';
import '../../providers/call_providers.dart';
import '../../services/permission_service.dart';
import '../../core/constants/app_constants.dart';

/// Listens for incoming calls at the app-shell level.
class IncomingCallListener extends ConsumerWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(incomingCallProvider, (previous, next) {
      next.whenData((call) {
        if (call == null) return;

        final alreadyShowing =
            ModalRoute.of(context)?.settings.name ==
                '/incoming-call-${call.callId}';

        if (alreadyShowing) return;

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            settings: RouteSettings(
              name: '/incoming-call-${call.callId}',
            ),
            fullscreenDialog: true,
            builder: (_) => IncomingCallScreen(call: call),
          ),
        );
      });
    });

    return child;
  }
}

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.call,
  });

  final CallModel call;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState
    extends ConsumerState<IncomingCallScreen> {
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
      return;
    }

    await ref
        .read(callServiceProvider)
        .updateStatus(
          widget.call.callId,
          CallStatus.calling,
        );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> _reject() async {
    setState(() => _responding = true);

    await ref
        .read(callServiceProvider)
        .updateStatus(
          widget.call.callId,
          CallStatus.rejected,
        );

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
                isVideo
                    ? 'Incoming Video Call'
                    : 'Incoming Audio Call',
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
              Text(widget.call.callerName),
              const Spacer(),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _responding ? null : _reject,
                    child: const Text('Decline'),
                  ),
                  ElevatedButton(
                    onPressed: _responding ? null : _accept,
                    child: Text(
                      isVideo ? 'Video' : 'Accept',
                    ),
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
