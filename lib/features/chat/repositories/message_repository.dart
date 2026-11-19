import 'package:chat_one_way_communication/core/services/notification_service.dart';
import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:chat_one_way_communication/features/chat/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    authRepository: ref.watch(authRepositoryProvider),
    firestore: ref.watch(firestoreProvider),
    userRepository: ref.watch(userRepositoryProvider)
  );
});

class MessageRepository {
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  
  MessageRepository({
    required AuthRepository authRepository,
    required FirebaseFirestore firestore,
    required UserRepository userRepository
  })  : _authRepository = authRepository,
        _firestore = firestore,
        _userRepository = userRepository;
  
// save message -------------------------------------------
  Future<MessageModel> saveMessage({
    required String chatId,
    required String text,
    required String type,
    required String receiverId, 
    String? mediaUrl,
  }) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final userModel = await _userRepository.getUser(userId); 
    final senderName = userModel?.name ?? 'Unknown User'; 
    
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    
    // 2. Create the message model
    final message = MessageModel(
      messageId: messageRef.id,
      senderId: userId,
      senderName: senderName,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      createdAt: Timestamp.now(),
    );
    

    await messageRef.set(message.toMap());
    await _firestore.collection('chats').doc(chatId).set({
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));

    try {

      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      
      if (receiverDoc.exists && receiverDoc.data()!.containsKey('fcmToken')) {
        
        Map<String, dynamic> tokensMap = receiverDoc.get('fcmToken');

        String notificationBody = type == 'video' ? '🎥 Video Message' : text;
        
        for (var token in tokensMap.values) {
          if (token != null && token.toString().isNotEmpty) {
            await PushNotificationService.sendNotification(
              receiverFcmToken: token.toString(),
              title: senderName,
              body: notificationBody, 
              chatId: chatId,
              senderId: userId,
            );
          }
        }
      }
    } catch (e) {
      print("Error sending push notification: $e");
    }
    // ---------------------------------------------------------

    return message;
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data, doc.id);
      }).toList();
    });
  }
}