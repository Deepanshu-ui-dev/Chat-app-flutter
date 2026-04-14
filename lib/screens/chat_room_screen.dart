import 'package:chat_app/main.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/widgets/chat_mesgs.dart';
import 'package:chat_app/widgets/new_mesg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.otherUser['username'] ?? 'Unknown';
    final avatarUrl = widget.otherUser['image_url'] ?? '';
    final about = widget.otherUser['about'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.otherUser['username']}',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.background,
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 20, color: AppColors.secondary)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ChatMesgs(
              userId: _chatService.currentUserId,
              conversationId: widget.conversationId,
            ),
          ),
          NewMesg(conversationId: widget.conversationId),
        ],
      ),
    );
  }
}
