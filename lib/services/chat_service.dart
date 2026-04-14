import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser!.id;

  // ─── Conversations ───────────────────────────────────────────────

  Future<String> getOrCreateConversation(String otherUserId) async {
    // Check if conversation already exists between two users
    final existing = await _supabase.rpc('find_conversation', params: {
      'user_one': currentUserId,
      'user_two': otherUserId,
    });

    if (existing != null && existing.toString().isNotEmpty) {
      return existing.toString();
    }

    // Create new conversation
    final conv = await _supabase
        .from('conversations')
        .insert({'created_at': DateTime.now().toIso8601String()})
        .select('id')
        .single();

    final convId = conv['id'] as String;

    // Add both participants
    await _supabase.from('conversation_participants').insert([
      {'conversation_id': convId, 'user_id': currentUserId},
      {'conversation_id': convId, 'user_id': otherUserId},
    ]);

    return convId;
  }

  // ─── Conversation List ───────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    return _supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .asyncMap((participants) async {
          if (participants.isEmpty) return <Map<String, dynamic>>[];

          final conversationIds = participants
              .map((p) => p['conversation_id'] as String)
              .toList();

          List<Map<String, dynamic>> results = [];

          for (final convId in conversationIds) {
            // Get the other participant
            final otherParticipant = await _supabase
                .from('conversation_participants')
                .select('user_id, users(id, username, image_url, about, last_seen)')
                .eq('conversation_id', convId)
                .neq('user_id', currentUserId)
                .maybeSingle();

            if (otherParticipant == null) continue;

            // Get last message
            final lastMessage = await _supabase
                .from('messages')
                .select('text, created_at, user_id')
                .eq('conversation_id', convId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            // Get unread count
            final unread = await _supabase
                .from('messages')
                .select()
                .eq('conversation_id', convId)
                .neq('user_id', currentUserId)
                .eq('is_read', false)
                .count(CountOption.exact);

            results.add({
              'conversation_id': convId,
              'other_user': otherParticipant['users'],
              'last_message': lastMessage,
              'unread_count': unread.count,
            });
          }

          // Sort by last message time
          results.sort((a, b) {
            final aTime = a['last_message']?['created_at'] ?? '';
            final bTime = b['last_message']?['created_at'] ?? '';
            return bTime.compareTo(aTime);
          });

          return results;
        });
  }

  // ─── Messages ────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list);
  }

  Future<void> sendMessage(String conversationId, String text) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'user_id': currentUserId,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update conversation timestamp
    await _supabase.from('conversations').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<void> markAsRead(String conversationId) async {
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('user_id', currentUserId)
        .eq('is_read', false);
  }

  // ─── Users ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return getUserProfile(currentUserId);
  }

  Future<List<Map<String, dynamic>>> getAllAppUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .neq('id', currentUserId)
        .order('username', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProfile({
    String? username,
    String? about,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (about != null) updates['about'] = about;
    if (imageUrl != null) updates['image_url'] = imageUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('users').update(updates).eq('id', currentUserId);
    }
  }

  Future<void> updateLastSeen() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final now = DateTime.now().toIso8601String();

      if (existingUser == null) {
        final metadata = user.userMetadata;
        final fullName = metadata?['full_name'] ?? metadata?['name'] ?? 'User';
        final avatarUrl = metadata?['avatar_url'] ?? metadata?['picture'] ?? '';

        await _supabase.from('users').insert({
          'id': user.id,
          'username': fullName,
          'email': user.email,
          'image_url': avatarUrl,
          'about': 'Hey there! I am using Chatify',
          'last_seen': now,
        });
      } else {
        await _supabase.from('users').update({
          'last_seen': now,
        }).eq('id', user.id);
      }
    } catch (e) {
      // Log or handle error
      print('Error updating last seen/profile: $e');
    }
  }
}
