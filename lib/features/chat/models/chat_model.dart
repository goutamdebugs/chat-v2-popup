import 'package:cloud_firestore/cloud_firestore.dart';
class ChatModel {
  final String chatId;
  final String type;
  final String? name;
  final List<String> members;
  final String createdBy;
  final Timestamp createdAt;

  ChatModel({
    required this.chatId,
    required this.type,
    this.name,
    required this.members,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      type: map['type'] ?? 'individual',
      name: map['name'],
      members: List<String>.from(map['members'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'type': type,
      'name': name,
      'members': members,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}
