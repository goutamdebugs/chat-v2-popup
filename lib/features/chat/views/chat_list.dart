import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:chat_one_way_communication/features/chat/controllers/get_message_controller.dart';
import 'package:chat_one_way_communication/features/chat/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/search_user_controller.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
      super.initState();
      _updateTokenOnAppStart();
  }
  
  Future<void> _updateTokenOnAppStart()async{
    final currentUser = ref.watch(authStateProviderForCurrentUser).valueOrNull;
    if(currentUser!=null){
      await ref.read(userRepositoryProvider).saveUserFCMToken(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    ref.read(searchQueryProvider.notifier).state = query;
    ref.read(searchuserProvider.notifier).searchByemail(query);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchuserProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authStateProviderForCurrentUser).valueOrNull?.uid;
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logOutUser(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user by email',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, __) => value.text.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _performSearch,
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(searchuserProvider.notifier).clear();
                }
              },
            ),
          ),
          Expanded(
            child: currentQuery.isEmpty
                ? _buildChatList(currentUserId) // <-- Pass currentUserId
                : _buildSearchResults(currentUserId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearSearch();
          context.push('/create-group');
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildChatList(String? currentUserId) {
    final chatState = ref.watch(getChatStreamProvider);

    return chatState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chats) {
        if (chats.isEmpty) {
          return const Center(
            child: Text('No chats yet.\nSearch a user above to start one.'),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final title = (chat.name?.isNotEmpty ?? false)
                ? chat.name!
                : 'Private Chat';

            // Find the ID of the person we are chatting with
            final receiverId = chat.members.firstWhere(
              (id) => id != currentUserId,
              orElse: () => 'group', 
            );

            return ListTile(
              leading: CircleAvatar(
                child: Text(title[0].toUpperCase()),
              ),
              title: Text(title),
              subtitle: const Text('Tap to open'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // FIXED ROUTE: Passing receiverId to the chat screen
                context.push('/chat/${chat.chatId}/$receiverId', extra: title);
              }
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(String? currentUserId) {
    final searchState = ref.watch(searchuserProvider);

    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('No user found with this email.'));
        }
        if (user.id == currentUserId) {
          return const Center(child: Text('You cannot chat with yourself.'));
        }

        return ListTile(
          leading: CircleAvatar(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            ),
          ),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: const Icon(Icons.chat_bubble_outline),
          onTap: () async {
            if (currentUserId == null) return;

            final chatId = ref
                .read(chatRepositoryprovider)
                .generateChatId(currentUserId, user.id);

            await ref.read(getChatStreamProvider.notifier).createChat(
                  name: user.name,
                  type: 'private',
                  members: [currentUserId, user.id],
                );

            if (!mounted) return;

            _clearSearch();
            // FIXED ROUTE: Passing the search result user.id as receiverId
            context.push('/chat/$chatId/${user.id}', extra: user.name);
          },
        );
      },
    );
  }
}