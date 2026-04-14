import 'package:chat_app/main.dart';
import 'package:chat_app/screens/chat_room_screen.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/services/contact_service.dart';
import 'package:chat_app/widgets/contact_tile.dart';
import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactService = ContactService();
  final _chatService = ChatService();

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactService.getAllAppUsers();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic> contact) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final conversationId = await _chatService.getOrCreateConversation(
        contact['id'] as String,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              conversationId: conversationId,
              otherUser: contact,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            Text(
              '${_contacts.length} contacts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.secondary),
            const SizedBox(height: 12),
            const Text('Failed to load contacts', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadContacts();
              },
              child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 80, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('No contacts found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _contacts.length + 2, // +2 for header items
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('New group', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              onTap: () {},
            ),
          );
        }

        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.textPrimary, size: 20),
              ),
              title: const Text('New contact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              onTap: () {},
            ),
          );
        }

        final contact = _contacts[index - 2];
        return ContactTile(
          name: contact['username'] ?? 'Unknown',
          avatarUrl: contact['image_url'] ?? '',
          about: contact['about'] ?? 'Available',
          onTap: () => _startChat(contact),
        );
      },
    );
  }
}
