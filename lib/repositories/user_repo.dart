import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/user.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final timeout = const Duration(seconds: 10);

  Stream<List<User>> streamUsers() {
    return _db
        .collection('apps/group-todo-list/users')
        .orderBy('itemCount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
              (doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> addUser(User user) async {
    Map<String, dynamic> userMap = user.toMap();
    // Remove 'id' because Firestore automatically generates a unique document ID for each new document added to the collection.
    userMap.remove('id');
    await _db
        .collection('apps/group-todo-list/users')
        .add(userMap); // write to local cache immediately
    //.timeout(timeout); // Add timeout to handle network issues
  }
  
  Future<void> deleteUser(User user) async {
    await _db
        .collection('apps/group-todo-list/users')
        .doc(user.id)
        .delete();
  }
}
