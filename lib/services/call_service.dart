import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

class CallService {
  CallService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection(AppConstants.callsCollection);

  Future<String> createCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
    required CallType type,
  }) async {
    final doc = _calls.doc();
    final call = CallModel(
      callId: doc.id,
      callerId: callerId,
      callerName: callerName,
      receiverId: receiverId,
      receiverName: receiverName,
      type: type,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
    );
    await doc.set(call.toMap());
    return doc.id;
  }

  Future<void> updateStatus(String callId, CallStatus status) async {
    await _calls.doc(callId).update({'status': status.value});
  }

  Future<void> endCall(String callId, {required DateTime startedAt}) async {
    final duration = DateTime.now().difference(startedAt).inSeconds;
    await _calls.doc(callId).update({
      'status': CallStatus.ended.value,
      'endTime': Timestamp.now(),
      'durationSeconds': duration,
    });
  }

  Future<void> markMissed(String callId) async {
    await _calls.doc(callId).update({
      'status': CallStatus.missed.value,
      'endTime': Timestamp.now(),
    });
  }

  Stream<CallModel?> watchCall(String callId) {
    return _calls.doc(callId).snapshots().map(
        (doc) => doc.exists ? CallModel.fromMap(doc.id, doc.data()!) : null);
  }

  Stream<CallModel?> watchIncomingCalls(String myUid) {
    return _calls
        .where('receiverId', isEqualTo: myUid)
        .where('status', isEqualTo: CallStatus.ringing.value)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : CallModel.fromMap(
                snapshot.docs.first.id, snapshot.docs.first.data()));
  }

  Stream<List<CallModel>> watchCallHistory(String myUid) {
    final controller = StreamController<List<CallModel>>();
    final calls = <String, CallModel>{};

    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> callerSub;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> receiverSub;

    void emit() {
      final history = calls.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      controller.add(history);
    }

    QuerySnapshot<Map<String, dynamic>>? callerSnapshot;
    QuerySnapshot<Map<String, dynamic>>? receiverSnapshot;

    void rebuild() {
      calls.clear();

      for (final doc in [
        ...?callerSnapshot?.docs,
        ...?receiverSnapshot?.docs,
      ]) {
        calls[doc.id] = CallModel.fromMap(doc.id, doc.data());
      }

      emit();
    }

    final baseQuery = _calls.orderBy('startTime', descending: true);

    callerSub = baseQuery
        .where('callerId', isEqualTo: myUid)
        .snapshots()
        .listen((snapshot) {
      callerSnapshot = snapshot;
      rebuild();
    }, onError: controller.addError);

    receiverSub = baseQuery
        .where('receiverId', isEqualTo: myUid)
        .snapshots()
        .listen((snapshot) {
      receiverSnapshot = snapshot;
      rebuild();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await callerSub.cancel();
      await receiverSub.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Future<bool> hasActiveCallBetween(String uidA, String uidB) async {
    final asCallerSnap = await _calls
        .where('callerId', isEqualTo: uidA)
        .where('receiverId', isEqualTo: uidB)
        .where('status', whereIn: [
          CallStatus.calling.value,
          CallStatus.ringing.value,
          CallStatus.connected.value,
        ])
        .limit(1)
        .get();

    if (asCallerSnap.docs.isNotEmpty) return true;

    final asReceiverSnap = await _calls
        .where('callerId', isEqualTo: uidB)
        .where('receiverId', isEqualTo: uidA)
        .where('status', whereIn: [
          CallStatus.calling.value,
          CallStatus.ringing.value,
          CallStatus.connected.value,
        ])
        .limit(1)
        .get();

    return asReceiverSnap.docs.isNotEmpty;
  }
}
