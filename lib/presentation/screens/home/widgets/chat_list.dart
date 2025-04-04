import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/chat_model.dart';
import 'chat_list_item.dart';

class ChatList extends StatelessWidget {
  final List<ChatModel> chats;

  const ChatList({
    super.key,
    required this.chats,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: chats.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        // Get the other participant's ID (not the current user)
        final otherUserId = chat.participants.firstWhere(
          (id) => id != 'user1', // Replace with dynamic user ID later
          orElse: () => 'unknown',
        );
        
        return ChatListItem(
          chat: chat,
          otherUserId: otherUserId,
        );
      },
    );
  }
}