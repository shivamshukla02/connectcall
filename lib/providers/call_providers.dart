import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_model.dart';
import '../services/call_service.dart';
import 'auth_providers.dart';

final callServiceProvider = Provider<CallService>((ref) => CallService());

final incomingCallProvider = StreamProvider<CallModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(callServiceProvider).watchIncomingCalls(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final callHistoryProvider = StreamProvider<List<CallModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(callServiceProvider).watchCallHistory(user.uid);
});
