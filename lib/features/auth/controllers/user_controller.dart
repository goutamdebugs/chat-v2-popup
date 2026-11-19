import 'package:chat_one_way_communication/features/auth/controllers/auth_controller.dart';
import 'package:chat_one_way_communication/features/auth/models/user_model.dart';
import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChange;
});

final currentUserNotifierProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(() {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return _fetchUser();
  }

  Future<UserModel?> _fetchUser() async {
    final currentUser = ref.watch(authStateProviderForCurrentUser);
    final firebaseUser = currentUser.value;

    if (firebaseUser == null) {
      return null;
    }

    final userRepository = ref.watch(userRepositoryProvider);
    return await userRepository.getUser(firebaseUser.uid);
  }

  Future<void> refreshUserData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUser());
  }
}

