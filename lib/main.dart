import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/firebase_options.dart';
import 'package:flutter_app/services/navigation.dart';
import 'package:flutter_app/view_models/all_users_vm.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make sure you have your Firebase options configured
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AllUsersViewModel>(
          create: (_) => AllUsersViewModel(),
        ),
        Provider<NavigationService>(
          create: (_) => NavigationService(),
        ),
      ],
      child: MaterialApp.router(
        theme: ThemeData.light().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
        ),
        routerConfig: routerConfig,
        restorationScopeId: 'app',
      ),
    );
  }
}
