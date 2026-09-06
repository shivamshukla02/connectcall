import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_providers.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Live list of every other user, keyed off whoever is currently signed in.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<UserModel>[]);
      return ref.watch(userServiceProvider).watchAllUsers(excludeUid: user.uid);
    },
    loading: () => Stream.value(<UserModel>[]),
    error: (_, __) => Stream.value(<UserModel>[]),
  );
});

/// Holds whatever the user has typed into the contacts search field.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Derived: allUsersProvider filtered by searchQueryProvider. UI just
/// watches this one provider instead of combining the two itself.
final filteredUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final query = ref.watch(searchQueryProvider);
  final userService = ref.watch(userServiceProvider);
  return usersAsync.whenData((users) => userService.filterUsers(users, query));
});
