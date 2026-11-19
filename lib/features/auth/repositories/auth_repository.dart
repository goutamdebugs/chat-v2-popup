import 'package:chat_one_way_communication/core/provider/firebase_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref){
   return AuthRepository(auth: ref.read(firebaseAuthProvider));
});

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({required this._auth});
  
  Stream<User?> get authStateChange => _auth.authStateChanges();
  
  String? get currentUserId => _auth.currentUser?.uid;
  //signup
  Future<UserCredential> signUp(String email, String password) async{
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  //singin

  Future<UserCredential> signIn(String email, String password) async{
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }


  Future<void> signOut()async{
      return await _auth.signOut();
  }
  
}