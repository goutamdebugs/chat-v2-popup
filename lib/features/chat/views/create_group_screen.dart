import 'package:chat_one_way_communication/features/auth/views/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../controllers/chat_controller.dart';

// State provider to hold the list of users you select for the group
final selectedGroupMembersProvider = StateProvider.autoDispose<List<UserModel>>((ref) => []);

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _createGroup() {
    final groupName = _groupNameController.text.trim();
    final selectedUsers = ref.read(selectedGroupMembersProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUserId;

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a group name')));
      return;
    }
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least 1 member')));
      return;
    }

    // Add current user ID and all selected user IDs to the members list
    final memberIds = [currentUserId!, ...selectedUsers.map((user) => user.id)];

    // Create the group chat in Firestore
    ref.read(chatControllerProvider.notifier).createChat(
      name: groupName,
      type: 'group', // Mark as group chat
      members: memberIds,
    );

    // Clear search state and go back to chat list
    ref.read(searchQueryProvider.notifier).state = '';
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = ref.watch(searchQueryProvider);
    final selectedUsers = ref.watch(selectedGroupMembersProvider);
    final currentUserId = ref.watch(authRepositoryProvider).currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('New Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        backgroundColor: Colors.deepPurpleAccent,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Group Icon and Name Input ---
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 28), // Group Icon Placeholder
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter Group Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. Display Selected Members ---
            if (selectedUsers.isNotEmpty) ...[
              const Text('Members:', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = selectedUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        backgroundColor: Colors.grey[800],
                        deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onDeleted: () {
                          // Remove user from list
                          ref.read(selectedGroupMembersProvider.notifier).update((state) {
                            return state.where((u) => u.id != user.id).toList();
                          });
                        },
                        label: Text(user.name, style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- 3. Search Bar ---
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search user by email to add...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),

            // --- 4. Search Results ---
            Expanded(
              child: currentQuery.isEmpty 
                  ? const Center(child: Text('Search to add members', style: TextStyle(color: Colors.grey)))
                  : _buildSearchResults(currentUserId, selectedUsers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(String? currentUserId, List<UserModel> selectedUsers) {
    final searchState = ref.watch(searchedUserProvider);

    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
      data: (user) {
        if (user == null) return const Center(child: Text('No user found', style: TextStyle(color: Colors.grey)));
        if (user.id == currentUserId) return const Center(child: Text("You can't add yourself", style: TextStyle(color: Colors.grey)));
        
        final isAlreadyAdded = selectedUsers.any((u) => u.id == user.id);

        return Card(
          color: Colors.grey[900],
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurpleAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(user.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(user.email, style: const TextStyle(color: Colors.grey)),
            trailing: isAlreadyAdded 
                ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                : const Icon(Icons.add_circle_outline, color: Colors.grey),
            onTap: () {
              if (!isAlreadyAdded) {
                // Add user to the selected list
                ref.read(selectedGroupMembersProvider.notifier).update((state) => [...state, user]);
                // Clear search to allow searching for the next person
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
        );
      },
    );
  }
}