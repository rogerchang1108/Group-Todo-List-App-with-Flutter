import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/user_repo.dart';

class AllUsersViewModel with ChangeNotifier {
  final UserRepository _userRepository;

  List<User> _users = [];
  List<User> get users => _users;
  StreamSubscription<List<User>>? _usersSubscription;

  AllUsersViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository() {
    _usersSubscription = _userRepository.streamUsers().listen((usersData) {
      _users = usersData;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  Future<void> addUser(User newUser) async {
    await _userRepository.addUser(newUser);
  }

  Future<void> deleteUser(User user) async {
    await _userRepository.deleteUser(user);
    // After deletion, notify listeners
    _users = _users.where((user) => user.id != user.id).toList();
    notifyListeners();
  }
}
