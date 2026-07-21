import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/avatar_widget.dart';
import 'create_group_dialog.dart';
import 'providers/home_providers.dart';

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({super.key});

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final groupsAsync = ref.watch(myGroupsProvider);
    final dmsAsync = ref.watch(dmSummariesProvider);

    final groups = (groupsAsync.value ?? [])
        .where((g) => g.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final dms = (dmsAsync.value ?? [])
        .where((d) => (d.other?.displayName ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final loading = groupsAsync.isLoading || dmsAsync.isLoading;
    final isEmpty = !loading && groups.isEmpty && dms.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search chats',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => showCreateGroupDialog(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : isEmpty
                  ? const _EmptyChats()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        ...groups.map((g) => ListTile(
                              leading: GroupAvatar(name: g.name, size: 48),
                              title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(g.description ?? 'Group chat', maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/chat/group:${g.id}'),
                            )),
                        ...dms.map((d) {
                          final mine = d.lastMessage.senderId == userId;
                          return ListTile(
                            leading: AvatarWidget(
                              url: d.other?.avatarUrl,
                              initialsSource: d.other?.displayName ?? '?',
                              size: 48,
                            ),
                            title: Text(d.other?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${mine ? 'You: ' : ''}${d.lastMessage.content}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              timeAgo(d.lastMessage.createdAt, addSuffix: false),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            onTap: () => context.push('/chat/dm:${d.otherUserId}'),
                          );
                        }),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('No conversations yet.'),
            const SizedBox(height: 4),
            Text(
              'Create a group or say hi from Contacts.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
