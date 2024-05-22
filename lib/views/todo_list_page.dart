import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/todo_item.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/navigation.dart';
import 'package:flutter_app/view_models/todos_of_user_vm.dart';
import 'package:flutter_app/views/todo_list_tile.dart';
import 'package:provider/provider.dart';

class TodoListPage extends StatefulWidget {
  final String userId;
  final String? newItemId;

  const TodoListPage({super.key, required this.userId, this.newItemId});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<TodosOfUserViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.pendingAddItemAnimationIndex > -1) {
          print(
              'Schedule animation for viewModel.pendingAddItemAnimationIndex: ${viewModel.pendingAddItemAnimationIndex}');
          // Animate adding the new item after the current build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _listKey.currentState?.insertItem(
              viewModel.pendingAddItemAnimationIndex,
              duration: const Duration(milliseconds: 300),
            );
            viewModel.pendingAddItemAnimationIndex = -1;
          });
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.adaptive.arrow_back),
              onPressed: () {
                Provider.of<NavigationService>(context, listen: false)
                    .pop(context);
              },
            ),
            title: const Text('To-do List'),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_task),
                onPressed: () {
                  final nav = Provider.of<NavigationService>(
                    context,
                    listen: false,
                  );
                  final viewModel = Provider.of<TodosOfUserViewModel>(
                    context,
                    listen: false,
                  );
                  nav.goAddTodoOnTodos(viewModel.userId);
                },
              ),
            ],
          ),
          body: viewModel.todoItems.isEmpty
              ? const Center(child: Text('No to-do items.'))
              : AnimatedList(
                  key: _listKey,
                  // If new-item animation is scheduled, subtract one item from the initial item count to simulate that a new item is being added
                  initialItemCount: _computeInitItemCount(viewModel),
                  itemBuilder: (context, index, animation) =>
                      _buildAnimatedTodoListTile(
                          context, viewModel, index, animation),
                ),
        );
      },
    );
  }

  /// The initialItemCount parameter in `AnimatedList` is only used during the `initState()` phase, not during subsequent `rebuild()` operations. If the `AnimatedList` is re-initializing due to a transition from another empty view and if there's a pending add-item animation, it is necessary to adjust the `initialItemCount` to one less than the current data count in the view model. This adjustment helps simulate the addition of the new item AFTER initialization when the add-item animation runs. Failing to make this adjustment could lead to an "array index out of range" exception because the `AnimatedList` would erroneously attempt to animate the addition of a new item from a list initially presumed to contain one item, rather than correctly animating from an empty list.
  int _computeInitItemCount(TodosOfUserViewModel viewModel) {
    if (viewModel.pendingAddItemAnimationIndex > -1 &&
        viewModel.todoItems.length == 1) {
      return viewModel.todoItems.length - 1;
    }
    return viewModel.todoItems.length;
  }

  Widget _buildAnimatedTodoListTile(BuildContext context,
      TodosOfUserViewModel viewModel, int index, Animation<double> animation,
      {TodoItem? animatedItem}) {
    final item = animatedItem ?? viewModel.todoItems[index];
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: Column(
          children: [
            TodoListTile(
              key: ValueKey(item.id!),
              item: item,
              onTap: () => _toggleTodoDone(viewModel, item.id!),
              onReassign: (_) =>
                  _showReassignDialog(context, index, item, viewModel),
              onDelete: (_) => _animateDeleteItem(viewModel, index),
            ),
            if (index < viewModel.todoItems.length - 1)
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                // Height of the separator, can be set to 0 for a thin line
                height: 1,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleTodoDone(TodosOfUserViewModel viewModel, String itemId) async {
    try {
      await viewModel.toggleDone(itemId);
    } catch (e) {
      // Check if the widget is still mounted after async gap
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Operation failed: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showReassignDialog(BuildContext context, int index, TodoItem item,
      TodosOfUserViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reassign "${item.name}" to:'),
          content: viewModel.otherUsers.isEmpty
              ? const Text('No other users.')
              : SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      for (User newUser in viewModel.otherUsers)
                        ListTile(
                          title: Text(newUser.name),
                          onTap: () => _animateReassignItem(
                            context,
                            viewModel,
                            index,
                            item,
                            newUser.id!,
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _animateDeleteItem(
      TodosOfUserViewModel viewModel, int index) async {
    TodoItem item = viewModel.todoItems[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedTodoListTile(
          context, viewModel, index, animation,
          animatedItem: item),
      duration: const Duration(milliseconds: 300),
    );

    // Since the `deleteItem()` is non-transactional, it is first synchronously executed on local cache before the server operation. This can lead error when animating the deletion. To avoid this, we call `deleteItem()` after the  animation starts.

    // Timeout/offline check is NOT needed because Firestore always writes to local cache first
    // try {
    //   await viewModel.deleteItem(item.id!);
    // } on TimeoutException catch (e) {
    //   // Check if the widget is still mounted after async gap
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).clearSnackBars();
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text("Operation timed out: ${e.message}"),
    //         duration: const Duration(seconds: 3),
    //       ),
    //     );
    //   }
    // }
    viewModel.deleteItem(item.id!);
  }

  Future<void> _animateReassignItem(
      BuildContext dialogContext,
      TodosOfUserViewModel viewModel,
      int index,
      TodoItem item,
      String newUserId) async {
    try {
      await viewModel.reassignItem(item.id!, newUserId);

      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedTodoListTile(
            context, viewModel, index, animation,
            animatedItem: item),
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Operation failed: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Check if the dialog is still mounted after async gap
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }
  }
}
