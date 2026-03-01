import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget{
  const ChatScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chatify'),
        ),
        body: const Center(
          child: Text('Logged IN'),
        ),
        
      ),
    );
  }
}