import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewMesg extends StatefulWidget {
  final String conversationId;

  const NewMesg({
    super.key,
    required this.conversationId,
  });

  @override
  State<NewMesg> createState() => _NewMesgState();
}

class _NewMesgState extends State<NewMesg> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'text': text,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client.from('conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.conversationId);

      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment icon
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: AppColors.secondary),
                    onPressed: () {},
                  ),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Emoji icon
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.secondary, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _isSending ? null : (_hasText ? _sendMessage : null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText ? AppColors.primary : AppColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _hasText ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                        color: _hasText ? Colors.white : AppColors.secondary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}