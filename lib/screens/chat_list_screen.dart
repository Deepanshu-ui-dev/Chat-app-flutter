import 'package:chat_app/main.dart';
import 'package:chat_app/screens/chat_room_screen.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getConversationsStream(),
      builder: (context, snapshot) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Error loading chats', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the chat icon below to start messaging',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final otherUser = conv['other_user'] as Map<String, dynamic>?;
            final lastMessage = conv['last_message'] as Map<String, dynamic>?;
            final unreadCount = conv['unread_count'] as int? ?? 0;

            return ConversationTile(
              name: otherUser?['username'] ?? 'Unknown',
              avatarUrl: otherUser?['image_url'] ?? '',
              lastMessage: lastMessage?['text'] ?? '',
              lastMessageTime: lastMessage?['created_at'] ?? '',
              unreadCount: unreadCount,
              isLastMessageMine: lastMessage?['user_id'] == _chatService.currentUserId,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      conversationId: conv['conversation_id'],
                      otherUser: otherUser ?? {},
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
