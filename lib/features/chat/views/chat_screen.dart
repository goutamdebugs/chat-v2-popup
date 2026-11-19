import 'package:chat_one_way_communication/core/provider/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/message_controller.dart';
import '../models/message_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverId; // <-- Missing field added here

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.receiverId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(messageControllerProvider.notifier).saveMessage(
            chatId: widget.chatId,
            text: text,
            type: 'text',
            receiverId: widget.receiverId, // Uses the receiverId to send push notification
          );
      // Clear the text field immediately after sending
      _messageController.clear(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the current user ID to determine message alignment (left or right)
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    // 2. Watch the real-time stream of messages for this specific chat
    final messagesStream = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.deepPurpleAccent), 
        elevation: 1,
      ),
      body: Column(
        children: [
          // =======================
          // CHAT MESSAGES LIST AREA
          // =======================
          Expanded(
            child: messagesStream.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Keeps the view scrolled to the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // =======================
          // MESSAGE INPUT AREA
          // =======================
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Builds individual message bubbles
  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    // Handle null timestamp during the optimistic UI update (when sending)
    final messageTime = message.createdAt.toDate();
        
    // Format timestamp (e.g., "10:45 AM")
    final timeString = DateFormat('h:mm a').format(messageTime);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width 75% of screen
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurpleAccent : Colors.grey[900], 
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the text input field at the bottom of the screen
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black, 
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.deepPurpleAccent,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}