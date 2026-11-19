import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String? mediaUrl;
  final Timestamp createdAt;
  final bool isDeleted;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    this.mediaUrl,
    required this.createdAt,
    this.isDeleted = false,
  });

  // Convert Model to Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName' : senderName,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt,
      'isDeleted': isDeleted,
    };
  }

  // Convert Map to Model
  factory MessageModel.fromMap(
    Map<String, dynamic> map,
    String messageId,
  ) {
    return MessageModel(
      messageId: messageId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}