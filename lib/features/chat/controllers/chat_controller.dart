import 'dart:async';
import 'package:chat_one_way_communication/features/auth/repositories/auth_repository.dart';
import 'package:chat_one_way_communication/features/chat/models/chat_model.dart';
import 'package:chat_one_way_communication/features/chat/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatControllerProvider = AsyncNotifierProvider<ChatController,List<ChatModel>>((){
  return ChatController();
});

class ChatController extends AsyncNotifier<List<ChatModel>>{

late final ChatRepository _chatRepo;
late final String? _currentUserId;

@override
  Future<List<ChatModel>> build() async{
    _chatRepo = ref.watch(chatRepositoryprovider);
    _currentUserId =ref.watch(authRepositoryProvider).currentUserId;
    return _fetchChat();
  }
  
  Future<List<ChatModel>> _fetchChat() async{
    if(_currentUserId==null){
      return [];
    }
    return await _chatRepo.getChatByUserId(_currentUserId);
  }

  Future<void> createChat({String? name, required String type,required List<String>members}) async{

     state = const AsyncValue.loading();

     state = await AsyncValue.guard(() async{
         await _chatRepo.saveChatModel(name, type, members);
         return _fetchChat();
     });
  }

  Future<void> refreshChats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(()=>_fetchChat());
  }

}
