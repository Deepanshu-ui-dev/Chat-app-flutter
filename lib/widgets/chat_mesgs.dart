import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatMesgs extends StatefulWidget {
  final String userId;
  final String conversationId;

  const ChatMesgs({
    super.key,
    required this.userId,
    required this.conversationId,
  });

  @override
  State<ChatMesgs> createState() => _ChatMesgsState();
}

class _ChatMesgsState extends State<ChatMesgs> {
  late ScrollController _scrollController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getMessagesStream() {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatDateHeader(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dt.year, dt.month, dt.day);

      if (messageDate == today) return 'TODAY';
      if (messageDate == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
      if (now.difference(dt).inDays < 7) return DateFormat('EEEE').format(dt).toUpperCase();
      return DateFormat('MMMM d, y').format(dt).toUpperCase();
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDateHeader(List<Map<String, dynamic>> messages, int index) {
    if (index == 0) return true;
    final current = messages[index]['created_at'] ?? '';
    final previous = messages[index - 1]['created_at'] ?? '';
    return _formatDateHeader(current) != _formatDateHeader(previous);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textSecondary)),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 32, color: AppColors.secondary),
                  SizedBox(height: 12),
                  Text(
                    'Messages are securely encrypted.\nStart your conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, 
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isOwn = message['user_id'] == widget.userId;
            final time = _formatTime(message['created_at'] ?? '');
            final text = message['text'] ?? '';
            final showDateHeader = _shouldShowDateHeader(messages, index);

            return Column(
              children: [
                if (showDateHeader)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _formatDateHeader(message['created_at'] ?? ''),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                _buildBubble(text, time, isOwn),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBubble(String text, String time, bool isOwn) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.sentBubble : AppColors.receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
          boxShadow: isOwn ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isOwn ? AppColors.sentText : AppColors.receivedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isOwn 
                    ? AppColors.sentText.withValues(alpha: 0.7) 
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}