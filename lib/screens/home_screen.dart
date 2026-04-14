import 'package:chat_app/screens/chat_list_screen.dart';
import 'package:chat_app/screens/contacts_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatService.updateLastSeen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {
              // Show settings/profile menu
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const ChatListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactsScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
