import 'dart:io';
import 'package:chat_app/main.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _chatService = ChatService();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _chatService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAvatar() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 500,
    );
    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);
    final userId = _chatService.currentUserId;
    final imagePath = "$userId.jpg";

    try {
      await _supabase.storage.from('avatars').upload(
        imagePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(imagePath);
      await _chatService.updateProfile(imageUrl: "$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}");
      _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating avatar: $e')),
        );
      }
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter your ${field == 'username' ? 'name' : field}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: field == 'about' ? 139 : 25,
          decoration: InputDecoration(
            hintText: 'Type your ${field == 'username' ? 'name' : field} here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (field == 'username') {
        await _chatService.updateProfile(username: result);
      } else if (field == 'about') {
        await _chatService.updateProfile(about: result);
      }
      _loadProfile();
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
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final username = _profile?['username'] ?? 'User';
    final email = _supabase.auth.currentUser?.email ?? 'No email';
    final about = _profile?['about'] ?? 'Available';
    final avatarUrl = _profile?['image_url'] ?? '';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 32),
        // Profile header
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _updateAvatar,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Hero(
                        tag: 'avatar_$username',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.background,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? const Icon(Icons.person_rounded, size: 50, color: AppColors.secondary)
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        const Text(
          "Personal Information",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _settingsTile(
          icon: Icons.person_outline_rounded,
          title: 'Name',
          subtitle: username,
          onTap: () => _editField('username', username),
        ),
        _settingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: about,
          onTap: () => _editField('about', about),
        ),

        const SizedBox(height: 32),
        const Text(
          "Application Settings",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _settingsTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Sounds & Haptics'),
        _settingsTile(icon: Icons.lock_outline_rounded, title: 'Privacy & Security', subtitle: 'Chat Encryption'),
        _settingsTile(icon: Icons.storage_rounded, title: 'Network & Data', subtitle: 'Usage statistics'),

        const SizedBox(height: 48),
        // Logout
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          onTap: () async {
            await _supabase.auth.signOut();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),

        const SizedBox(height: 60),
        Center(
          child: Opacity(
            opacity: 0.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_rounded, size: 14, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'CHATIFY V1.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        tileColor: AppColors.background,
        leading: Icon(icon, color: AppColors.textPrimary, size: 24),
        title: Text(
          title, 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)
        ),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.secondary),
      ),
    );
  }
}
