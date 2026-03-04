import 'package:flutter/material.dart';
import 'package:chat_app/skeleton/chathome.dart';
import 'chat.dart';

class ChatLoaderScreen extends StatefulWidget {
  const ChatLoaderScreen({super.key});

  @override
  State<ChatLoaderScreen> createState() => _ChatLoaderScreenState();
}

class _ChatLoaderScreenState extends State<ChatLoaderScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ChatHomeSkeleton();
    }

    return const ChatScreen();
  }
}