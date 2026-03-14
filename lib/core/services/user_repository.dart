import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/shared/models/app_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);
  
  CollectionReference get _users => _firestore.collection('users');

  /// Creates or updates a user in Firestore
  Future<void> saveUser(AppUser user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetches a user by ID
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  /// Streams a user by ID for real-time updates
  Stream<AppUser?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Streams all users (for admin)
  Stream<List<AppUser>> streamAllUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams pending NGOs (those waiting for approval)
  Stream<List<AppUser>> streamPendingNGOs() {
    return _users
        .where('role', isEqualTo: AppRole.ngo.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Filter those who don't have extraData['isApproved'] == true
      return list.where((user) => user.extraData?['isApproved'] != true).toList();
    });
  }
}
