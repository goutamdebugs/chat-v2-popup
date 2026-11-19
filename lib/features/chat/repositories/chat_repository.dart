import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import 'package:chat_one_way_communication/features/auth/repositories/user_repository.dart';
import 'package:chat_one_way_communication/features/chat/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryprovider = Provider<ChatRepository>((ref){
  return ChatRepository(
    firestore: ref.watch(firestoreProvider), 
    authrepo: ref.watch(authRepositoryProvider)
  );
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  ChatRepository({required this._firestore, required AuthRepository authrepo})
      : _authRepository = authrepo;

  // Helper method to generate deterministic 1-on-1 chat ID
  String generateChatId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '${user1}_$user2';
    }
    return '${user2}_$user1';
  }

  Future<ChatModel> saveChatModel(
    String? name,
    String type,
    List<String> members,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // FIX: Generate deterministic ID for private chats, random ID for groups
    String chatId;
    if (type == 'private' && members.length == 2) {
      chatId = generateChatId(members[0], members[1]);
    } else {
      chatId = _firestore.collection('chats').doc().id;
    }

    final docRef = _firestore.collection('chats').doc(chatId);

    final chat = ChatModel(
      chatId: chatId,
      type: type,
      name: name,
      members: members,
      createdBy: currentUserId,
      createdAt: Timestamp.now(),
    );

    await docRef.set({
      'chatId': chat.chatId,
      'type': chat.type,
      'name': chat.name,
      'members': chat.members,
      'createdBy': chat.createdBy,
      'createdAt': chat.createdAt,
    }, SetOptions(merge: true));

    return chat;
  }

  Future<String> getIndividualChat({
    required String otherUserId
  }) async {
    final myId = _authRepository.currentUserId;

    if (myId == null) {
      throw Exception('Current user is not logged in.');
    }

    final chatId = generateChatId(myId, otherUserId);

    final chatRef = _firestore.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (doc.exists) {
      return chatId;
    }

    final chat = ChatModel(
      chatId: chatId, 
      type: 'individual', 
      members: [myId, otherUserId], 
      createdBy: myId, 
      createdAt: Timestamp.now()
    );

    await chatRef.set(chat.toMap(), SetOptions(merge: true));
    return chatId;
  }

  Future<List<ChatModel>> getChatByUserId(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) {
      return ChatModel.fromMap(doc.data());
    }).toList();
  }

  // Stream user own chats 
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
  
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromMap(doc.data());
          }).toList();
        });
  }
}