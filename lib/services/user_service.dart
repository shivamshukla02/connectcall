import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Live stream of every user except [excludeUid] (the signed-in user).
  /// Small-scale by design — fine for an intern-assignment contact list;
  /// a production app would paginate this.
  Stream<List<UserModel>> watchAllUsers({required String excludeUid}) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.id != excludeUid)
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc =
        await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }

  /// Client-side filter on an already-fetched list. A Firestore
  /// prefix-range query would be needed for large datasets, but for this
  /// assignment's scale, filtering the live snapshot is simpler and still
  /// gives instant results as the user types.
  List<UserModel> filterUsers(List<UserModel> users, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }
}
