import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/todo_item.dart';
import 'package:flutter_app/repositories/todo_item_repo.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/user_repo.dart';

class TodosOfUserViewModel with ChangeNotifier {
  final TodoItemRepository _todoItemRepository;
  StreamSubscription<List<TodoItem>>? _itemsSubscription;

  final String userId;
  List<User> _otherUsers = [];
  List<User> get otherUsers => _otherUsers;
  List<TodoItem> _todoItems = [];
  List<TodoItem> get todoItems => _todoItems;
  int pendingAddItemAnimationIndex = -1;

  TodosOfUserViewModel(
      {required this.userId,
      TodoItemRepository? todoItemRepository,
      UserRepository? userRepository})
      : _todoItemRepository = todoItemRepository ?? TodoItemRepository() {
    _itemsSubscription = _todoItemRepository.streamTodoItems(userId).listen(
      (items) {
        _todoItems = items;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }

  // To be called by ChangeNotifierProxyProvider when the depending state changes
  void updateViewModel(List<User> allUsers) {
    _otherUsers = allUsers.where((user) => user.id != userId).toList();
    notifyListeners();
  }

  Future<void> toggleDone(String itemId) async {
    await _todoItemRepository.toggleDone(userId, itemId);
  }

  Future<String> addItem(TodoItem newItem) async {
    // Assume that the new item is always added as the first item in the to-do list
    pendingAddItemAnimationIndex = 0;
    return await _todoItemRepository.addItem(userId, newItem);
  }

  Future<void> deleteItem(String itemId) async {
    await _todoItemRepository.deleteItem(userId, itemId);
  }

  Future<void> reassignItem(String itemId, String newUserId) async {
    await _todoItemRepository.reassignItem(itemId, userId, newUserId);
  }
}
