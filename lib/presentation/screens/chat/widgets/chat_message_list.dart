import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/message_model.dart';
import '../../../widgets/chat_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final List<MessageModel> messages;
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true, // Display newest messages at the bottom
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSentByMe = message.senderId == 'user1'; // Replace with dynamic user ID

        return ChatBubble(
          message: message,
          isSentByMe: isSentByMe,
        );
      },
    );
  }
}