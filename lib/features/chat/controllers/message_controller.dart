import 'dart:async';
import 'package:chat_one_way_communication/features/chat/models/message_model.dart';
import 'package:chat_one_way_communication/features/chat/repositories/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.getMessages(chatId);
});

final messageControllerProvider = AsyncNotifierProvider<MessageController, void>(() {
  return MessageController();
});

class MessageController extends AsyncNotifier<void> {
  late final MessageRepository _messageRepository;
  
  @override
  FutureOr<void> build() {
    _messageRepository = ref.watch(messageRepositoryProvider);
  }

  
  Future<void> saveMessage({
    required String chatId,
    required String text,
    required String type,
    required String receiverId,
    String? mediaUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _messageRepository.saveMessage(
        chatId: chatId,
        text: text,
        type: type,
        receiverId: receiverId,
        mediaUrl: mediaUrl,
      );
    });
  }
}