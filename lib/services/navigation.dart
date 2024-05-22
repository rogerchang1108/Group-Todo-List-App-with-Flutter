import 'package:flutter/material.dart';
import 'package:flutter_app/view_models/todos_of_user_vm.dart';
import 'package:flutter_app/views/user_grid_page.dart';
import 'package:flutter_app/views/add_user_page.dart';
import 'package:flutter_app/views/todo_list_page.dart';
import 'package:flutter_app/views/add_todo_page.dart';
import 'package:flutter_app/view_models/all_users_vm.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final routerConfig = GoRouter(
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return child;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/users',
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: UserGridPage()),
          routes: <RouteBase>[
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddUserPage(),
            ),
            ShellRoute(
              builder:
                  (BuildContext context, GoRouterState state, Widget child) {
                // Provide the ViewModel here
                return ChangeNotifierProxyProvider<AllUsersViewModel,
                    TodosOfUserViewModel>(
                  create: (_) => TodosOfUserViewModel(
                    userId: state.pathParameters['userId']!,
                  ),
                  update: (_, allUsersViewModel, prevTodosOfUserViewModel) =>
                      prevTodosOfUserViewModel!
                        ..updateViewModel(allUsersViewModel.users),
                  child: child,
                );
              },
              routes: [
                GoRoute(
                  path: ':userId/todos',
                  builder: (context, state) {
                    return TodoListPage(
                      userId: state.pathParameters['userId']!,
                    );
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const AddTodoPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  initialLocation: '/users',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final currentPath = state.uri.path;
    if (currentPath == '/') {
      return '/users';
    }
    // No redirection needed for other routes
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);

class NavigationService {
  late final GoRouter _router;

  NavigationService() {
    _router = routerConfig;
  }

  void goUsers() {
    _router.go('/users');
  }

  void goAddUserOnUsers() {
    _router.go('/users/add');
  }

  void goTodosOnUsers(String userId) {
    _router.go('/users/$userId/todos');
  }

  void goAddTodoOnTodos(String userId) {
    _router.go('/users/$userId/todos/add');
  }

  void pop(BuildContext context) {
    _router.pop(context);
  }
}
