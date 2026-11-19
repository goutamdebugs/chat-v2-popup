import 'package:chat_one_way_communication/core/provider/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchedUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final emailQuery = ref.watch(searchQueryProvider);
  
  if (emailQuery.isEmpty) return null;
  
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUserByEmail(emailQuery);
});

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final searchState = ref.watch(searchedUserProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepPurpleAccent),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logOutUser();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search user by email...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
                  onPressed: _performSearch,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _performSearch(), // Search when pressing enter on keyboard
            ),
            const SizedBox(height: 24),

            // Search Results Area
            Expanded(
              child: searchState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
                error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                data: (user) {
                  // Initial state: Search bar is empty
                  if (currentQuery.isEmpty) {
                    return const Center(
                      child: Text(
                        'Type an email address to find someone.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // State: User not found in database
                  if (user == null) {
                    return const Center(
                      child: Text(
                        'No user found with this email.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // State: User searched for their own email
                  if (user.id == currentUserId) {
                    return const Center(
                      child: Text(
                        'You cannot chat with yourself.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurpleAccent,
                        radius: 24,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurpleAccent),
                      onTap: () {
                        // context.push('/chat/${user.id}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}