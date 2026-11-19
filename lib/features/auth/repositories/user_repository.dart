import 'dart:io';

import 'package:chat_one_way_communication/core/utils/find_device_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(fireStore: ref.read(firestoreProvider));
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getAllUsers();
});

class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository({required FirebaseFirestore fireStore})
    : _firestore = fireStore;

Future<void> saveUserFCMToken(String userId) async{
  try{
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final String? fcmTokens = await messaging.getToken();
    if(fcmTokens==null) return;

    final String deviceId = await getDeviceId();
    
     print(deviceId);

    await _firestore.collection('users').doc(userId).set(
      {
        'fcmToken':{
          deviceId : fcmTokens,
        }
      }, SetOptions(merge: true)
    );
    print('FCM token Save For DEvice $deviceId');
  }catch(e){
    print('error saving fcm token');
  }
}

  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }
// search user by email-----
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1) 
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
      return null;
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }
}
