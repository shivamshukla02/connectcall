import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/call_model.dart';
import '../../../providers/auth_providers.dart';

class CallHistoryTile extends ConsumerWidget {
  const CallHistoryTile({
    super.key,
    required this.call,
  });

  final CallModel call;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);

    if (value == today) return 'Today';
    if (value == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _duration() {
    if (call.durationSeconds <= 0) return '';
    final minutes = call.durationSeconds ~/ 60;
    final seconds = call.durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final isOutgoing = call.callerId == me?.uid;
    final otherName = isOutgoing ? call.receiverName : call.callerName;

    final isFailed = call.status == CallStatus.missed ||
        call.status == CallStatus.rejected ||
        call.status == CallStatus.failed;

    final statusText = switch (call.status) {
      CallStatus.missed => 'Missed',
      CallStatus.rejected => 'Declined',
      CallStatus.failed => 'Failed',
      CallStatus.ended => _duration(),
      _ => '',
    };

    final statusColor = isFailed
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          call.type == CallType.video
              ? Icons.videocam_outlined
              : Icons.call_outlined,
        ),
      ),
      title: Text(
        otherName.isEmpty ? 'Unknown user' : otherName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(_formatDate(call.startTime)),
        ],
      ),
      trailing: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: isFailed ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
