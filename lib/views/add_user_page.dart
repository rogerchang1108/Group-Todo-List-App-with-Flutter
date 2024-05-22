import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/navigation.dart';
import 'package:flutter_app/view_models/all_users_vm.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:provider/provider.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  String _enteredName = '';
  // String _enteredAvatarUrl = '';
  String _selectedAvatarSvgData = '';

  bool _isAddingUser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Add User')),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  // To ensure the button stretches to fit the width
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FluttermojiCircleAvatar(
                      radius: 80,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(height: 16),
                    FluttermojiCustomizer(
                      scaffoldHeight: 300,
                      autosave: true,
                      theme: FluttermojiThemeData(
                        labelTextStyle: Theme.of(context).textTheme.labelLarge,
                        primaryBgColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        // secondaryBgColor:
                        //     Theme.of(context).colorScheme.surfaceVariant,
                        selectedTileDecoration: BoxDecoration(
                          // color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        selectedIconColor:
                            Theme.of(context).colorScheme.primary,
                        unselectedIconColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                      onSaved: (value) => _enteredName = value!,
                    ),
                    // const SizedBox(height: 16),
                    // TextFormField(
                    //   decoration: InputDecoration(
                    //     labelText: 'Avatar URL',
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(8.0),
                    //     ),
                    //   ),
                    //   validator: (value) {
                    //     if (value!.isEmpty) {
                    //       return 'Please provide an avatar URL';
                    //     } else {
                    //       const urlPattern =
                    //           r'^(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)(\?.*)?(#.*)?$';
                    //       final result =
                    //           RegExp(urlPattern, caseSensitive: false)
                    //               .hasMatch(value);
                    //       if (!result) {
                    //         return 'Please enter a valid URL';
                    //       }
                    //     }
                    //     return null;
                    //   },
                    //   onSaved: (value) => _enteredAvatarUrl = value!,
                    // ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isAddingUser ? null : () => _submit(),
                      child: _isAddingUser
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text('Add User'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAddingUser = true;
    });

    _formKey.currentState!.save();
    final fmoji = FluttermojiFunctions();
    _selectedAvatarSvgData = fmoji.decodeFluttermojifromString(
      await fmoji.encodeMySVGtoString(),
    );

    final newUser = User(
      name: _enteredName,
      // avatarUrl: _enteredAvatarUrl,
      avatarSvgData: _selectedAvatarSvgData,
    );

    // Check if the widget is still mounted after async gap
    if (!mounted) return;

    // Timeout/offline check is NOT needed because Firestore always writes to local cache first
    // try {
    //   await Provider.of<AllUsersViewModel>(context, listen: false)
    //       .addUser(newUser);

    //   if (mounted) {
    //     Provider.of<NavigationService>(context, listen: false).goUsers();
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
    Provider.of<AllUsersViewModel>(context, listen: false).addUser(newUser);
    Provider.of<NavigationService>(context, listen: false).goUsers();
  }
}
