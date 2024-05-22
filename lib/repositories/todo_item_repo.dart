import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/todo_item.dart';

class TodoItemRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final timeout = const Duration(seconds: 10);

  Stream<List<TodoItem>> streamTodoItems(String userId) {
    return _db
        .collection('apps/group-todo-list/users')
        .doc(userId)
        .collection('todo-items')
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<String> addItem(String userId, TodoItem item) async {
    Map<String, dynamic> itemMap = item.toMap();
    // Remove 'id' because Firestore automatically generates a unique document ID for each new document added to the collection.
    itemMap.remove('id');
    // Ensure 'createdDate' is set by the server to maintain consistency across different clients, independent of local time settings.
    itemMap['createdDate'] = FieldValue.serverTimestamp();
    DocumentReference docRef = await _db
        .collection('apps/group-todo-list/users')
        .doc(userId)
        .collection('todo-items')
        .add(itemMap); // write to local cache immediately
    // .timeout(timeout); // Add timeout to handle network issues

    return docRef.id;
  }

  Future<void> toggleDone(String userId, String itemId) async {
    final itemRef = _db
        .collection('apps/group-todo-list/users')
        .doc(userId)
        .collection('todo-items')
        .doc(itemId);

    return _db.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemRef);
      if (!itemSnapshot.exists) {
        throw Exception("Todo item does not exist!");
      }

      final bool currentStatus = itemSnapshot.data()?['isDone'] ??
          false; // Assuming 'isDone' is stored as a boolean
      transaction.update(itemRef, {'isDone': !currentStatus});
    }).timeout(timeout); // Add timeout to handle network issues
  }

  Future<void> reassignItem(
      String itemId, String oldUserId, String newUserId) async {
    final oldItemRef = _db
        .collection('apps/group-todo-list/users')
        .doc(oldUserId)
        .collection('todo-items')
        .doc(itemId);
    final newItemRef = _db
        .collection('apps/group-todo-list/users')
        .doc(newUserId)
        .collection('todo-items')
        .doc();

    return _db.runTransaction((transaction) async {
      final oldItemSnapshot = await transaction.get(oldItemRef);
      if (!oldItemSnapshot.exists) {
        throw Exception("Item does not exist!");
      }
      // Add the item to the new user's collection
      transaction.set(newItemRef, {
        ...oldItemSnapshot.data()!,
        'userId': newUserId, // Update userId to the new user's ID
        'createdDate': FieldValue
            .serverTimestamp(), // Update 'createdDate' so it is placed at the top of the new user's list
        'isDone': false, // Reset 'isDone' status
      });
      // Delete the item from the old user's collection
      transaction.delete(oldItemRef);
    }).timeout(timeout); // Add timeout to handle network issues
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _db
        .collection('apps/group-todo-list/users')
        .doc(userId)
        .collection('todo-items')
        .doc(itemId)
        .delete(); // write to local cache immediately
    //.timeout(timeout); // Add timeout to handle network issues
  }
}
