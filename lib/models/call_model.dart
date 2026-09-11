import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/app_constants.dart';

/// Mirrors calls/{callId}. One doc per call, updated in place as the call
/// progresses through states rather than creating multiple records —
/// this is the "prevent multiple call records for one call" requirement
/// from the assignment.
class CallModel extends Equatable {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
  });

  factory CallModel.fromMap(String callId, Map<String, dynamic> map) {
    return CallModel(
      callId: callId,
      callerId: map['callerId'] as String? ?? '',
      callerName: map['callerName'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      type: CallType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (s) => s.value == map['status'],
        orElse: () => CallStatus.ended,
      ),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'type': type.value,
      'status': status.value,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': durationSeconds,
    };
  }

  @override
  List<Object?> get props => [
        callId,
        callerId,
        callerName,
        receiverId,
        receiverName,
        type,
        status,
        startTime,
        endTime,
        durationSeconds,
      ];
}
