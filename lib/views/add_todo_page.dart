import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/category.dart';
import 'package:flutter_app/models/todo_item.dart';
import 'package:flutter_app/services/navigation.dart';
import 'package:flutter_app/utils/categories.dart';
import 'package:flutter_app/view_models/todos_of_user_vm.dart';
import 'package:provider/provider.dart';

class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final _formKey = GlobalKey<FormState>();
  String _enteredName = '';
  String? _enteredDetails;
  Category _selectedCategory = categories[Categories.learning]!;

  bool _isAddingTodo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add To-do'),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                // To ensure the button stretches to fit the width
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length < 2) {
                        return 'Please enter a valid name.';
                      }
                      return null;
                    },
                    onSaved: (value) => _enteredName = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    minLines: 3,
                    maxLines: null, // Expand vertically
                    decoration: InputDecoration(
                      labelText: 'Details',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        _enteredDetails = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    value: _selectedCategory,
                    onChanged: (Category? newValue) {
                      _selectedCategory = newValue!;
                    },
                    items: categories.values
                        .map<DropdownMenuItem<Category>>((Category value) {
                      return DropdownMenuItem<Category>(
                        value: value,
                        child: Text(value.title),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isAddingTodo ? null : () => _submit(),
                    child: _isAddingTodo
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          )
                        : const Text('Add Item'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAddingTodo = true;
    });

    _formKey.currentState!.save();

    final viewModel = Provider.of<TodosOfUserViewModel>(context, listen: false);
    final newItem = TodoItem(
      name: _enteredName,
      details: _enteredDetails,
      category: _selectedCategory,
      userId: viewModel.userId,
    );

    // Timeout/offline check is NOT needed because Firestore always writes to local cache first
    // try {
    //   await viewModel.addItem(newItem);

    //   // Check if the widget is still mounted after async gap
    //   if (mounted) {
    //     Provider.of<NavigationService>(context, listen: false)
    //         .goTodosOnUsers(viewModel.userId);
    //   }
    // } on TimeoutException catch (e) {
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
    viewModel.addItem(newItem);
    Provider.of<NavigationService>(context, listen: false)
        .goTodosOnUsers(viewModel.userId);
  }
}
