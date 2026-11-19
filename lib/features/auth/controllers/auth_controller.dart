import 'package:chat_one_way_communication/features/auth/models/user_model.dart';
import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProviderForCurrentUser = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChange;
});

final authControllerProvider = StateNotifierProvider<AuthController, bool>((
  ref,
) {
  return AuthController(
    authRepository: ref.read(authRepositoryProvider),
    userRepository: ref.read(userRepositoryProvider),
  );
});

class AuthController extends StateNotifier<bool>{
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthController({
    required this._authRepository,
    required UserRepository userRepository,
  }) : _userRepository = userRepository,
       super(false);

  Future<void> registerAndSaveUser(
    String email,
    String password,
    String name,
  ) async {
    state = true;
    try {
      final create = await _authRepository.signUp(email, password);      
      final userModel = UserModel(
        id: create.user!.uid,
        name: name,
        email: email,
      );
      await _userRepository.saveUser(userModel);
      await _userRepository.saveUserFCMToken(create.user!.uid);
    } finally{
      state = false;
    }
  }

  Future<void> signInUser(String email, String password) async{
    state = true;
     try {
       final userCredential = await _authRepository.signIn(email, password);

       if(userCredential.user!=null){
        await _userRepository.saveUserFCMToken(userCredential.user!.uid);
       }
     } catch (e) {
        throw Exception('error to signin $e');
     }finally{
      state = false;
     }
  }

  Future <void> logOutUser () async{
    return await _authRepository.signOut();
  }
}
