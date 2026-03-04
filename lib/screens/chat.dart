import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;

  User? user;
  Map<String, dynamic>? profileData;
  String? avatarUrl;

  int _bottomIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // 1️⃣ Fetch user profile from database
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user!.id)
          .single();

      // 2️⃣ Generate avatar URL from bucket
      final imagePath = 'user_images/${user!.id}.jpg';

      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl(imagePath);

      setState(() {
        profileData = response;
        avatarUrl = publicUrl;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Chatify",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "People",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            label: "Calls",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_bottomIndex == 0) {
      return const Center(child: Text("Chats Coming Soon"));
    }
    if (_bottomIndex == 1) {
      return const Center(child: Text("All Contacts"));
    }
    if (_bottomIndex == 2) {
      return const Center(child: Text("Recent Calls"));
    }
    return _buildProfileTab();
  }

  Widget _buildProfileTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.black12,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),

          const SizedBox(height: 20),

          Text(
            profileData?['username'] ?? "No Name",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            user?.email ?? "No Email",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}