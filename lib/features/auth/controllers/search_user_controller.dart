import 'dart:async';

import 'package:chat_one_way_communication/features/auth/models/user_model.dart';
import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchuserProvider =
    AsyncNotifierProvider<SearchUserController, UserModel?>(() {
  return SearchUserController();
});

class SearchUserController extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() {
    return null;
  }

  Future<void> searchByemail(String email) async {
    final emmailTried = email.trim();
    if (emmailTried.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userrepo = ref.read(userRepositoryProvider);
      return await userrepo.getUserByEmail(emmailTried);
    });
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}