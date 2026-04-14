import 'package:chat_app/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationTile extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isLastMessageMine;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isLastMessageMine,
    required this.onTap,
  });

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dt.year, dt.month, dt.day);

      if (messageDate == today) {
        return DateFormat('h:mm a').format(dt);
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else if (now.difference(dt).inDays < 7) {
        return DateFormat('EEE').format(dt);
      } else {
        return DateFormat('dd/MM/yy').format(dt);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    final formattedTime = _formatTime(lastMessageTime);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Hero(
              tag: 'avatar_$name',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.background,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 30, color: AppColors.secondary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty ? 'Tap to start chatting' : lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
