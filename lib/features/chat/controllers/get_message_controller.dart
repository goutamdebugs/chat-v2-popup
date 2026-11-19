import 'package:chat_one_way_communication/features/auth/controllers/auth_controller.dart';
import 'package:chat_one_way_communication/features/chat/models/chat_model.dart';
import 'package:chat_one_way_communication/features/chat/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getChatStreamProvider = StreamNotifierProvider<getChatController,List<ChatModel>>((){
   return getChatController();
});

class getChatController extends StreamNotifier<List<ChatModel>>{


  @override
  Stream<List<ChatModel>> build() {

    final uid = ref.watch(authStateProviderForCurrentUser).valueOrNull?.uid;
    if(uid==null) return Stream.value(const []);

     return ref.watch(chatRepositoryprovider).getUserChatsStream(uid);
  }

  Future<void> createChat({
    String? name,
    required String type,
    required List<String> members,
  }) async {
    await ref.watch(chatRepositoryprovider).saveChatModel(name, type, members);
  }
}