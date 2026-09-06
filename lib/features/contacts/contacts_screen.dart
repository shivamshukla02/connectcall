import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_providers.dart';
import 'widgets/user_tile.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  void _placeholderCallTap(BuildContext context, String type) {
    // Phase 4/5 replaces this with real ZEGOCLOUD call initiation.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type calling comes online in Phase 4/5')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredUsers = ref.watch(filteredUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search people...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).state = value,
          ),
        ),
        Expanded(
          child: filteredUsers.when(
            data: (users) {
              if (users.isEmpty) {
                return const _EmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return UserTile(
                    user: user,
                    onAudioCall: () => _placeholderCallTap(context, 'Audio'),
                    onVideoCall: () => _placeholderCallTap(context, 'Video'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load contacts: $e')),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('No contacts found'),
        ],
      ),
    );
  }
}
