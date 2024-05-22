import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/navigation.dart';
import 'package:flutter_app/view_models/all_users_vm.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class UserGridPage extends StatelessWidget {
  const UserGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group To-do List'),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () =>
                Provider.of<NavigationService>(context, listen: false)
                    .goAddUserOnUsers(),
          ),
        ],
      ),
      body: Consumer<AllUsersViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.users.isEmpty) {
            return const Center(child: Text('No users.'));
          }
          // Calculate the number of grid columns, ensuring there's at least one column
          double screenWidth = MediaQuery.of(context).size.width;
          double gridTileMinWidth = 150;
          int gridCrossAxisCount =
              max(1, (screenWidth / gridTileMinWidth).floor());
          double safeAreaBottomPadding = MediaQuery.of(context).padding.bottom;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 8.0, // 8dp spacing between grid tiles
              mainAxisSpacing: 8.0, // 8dp spacing between grid tiles
            ),
            padding:
                EdgeInsets.fromLTRB(16, 16, 16, 16 + safeAreaBottomPadding),
            itemCount: viewModel.users.length,
            itemBuilder: (context, index) =>
                _buildGridItem(context, viewModel.users[index]),
          );
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, User user) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Provider.of<NavigationService>(context, listen: false)
          .goTodosOnUsers(user.id!),
      child: Stack(
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    child: _buildAvatarImage(context, user),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  RichText(
                    text: TextSpan(
                      // Default text style for all spans
                      style: theme.textTheme.headlineLarge,
                      text: '${user.itemCount} ',
                      children: <TextSpan>[
                        TextSpan(
                          text: 'items to do.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Users?'),
                      content: const Text('The to-do items of this user will be randomly distributed to other users.'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () async {
                            Provider.of<AllUsersViewModel>(context, listen: false).deleteUser(user);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context, User user) {
    if (user.avatarSvgData != null) {
      return SvgPicture.string(
        user.avatarSvgData!,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user.avatarUrl != null) {
      return ClipOval(
        child: Stack(
          children: <Widget>[
            const Center(child: CircularProgressIndicator()),
            Positioned.fill(
              child: Center(
                child: Image.network(
                  user.avatarUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: Icon(
        Icons.account_circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }
}
