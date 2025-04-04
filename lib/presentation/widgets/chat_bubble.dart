import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/data_time_helper.dart';
import '../../data/models/message_model.dart';
import 'chat/image_message_bubble.dart';
import 'chat/video_message_bubble.dart';
import 'chat/document_message_bubble.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSentByMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    // Choose the appropriate bubble based on message type
    switch (message.type) {
      case MessageType.image:
        return ImageMessageBubble(message: message, isSentByMe: isSentByMe);
      case MessageType.video:
        return VideoMessageBubble(message: message, isSentByMe: isSentByMe);
      case MessageType.document:
        return DocumentMessageBubble(message: message, isSentByMe: isSentByMe);
      case MessageType.text:
      default:
        return _buildTextBubble(context);
    }
  }

  Widget _buildTextBubble(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSentByMe ? AppColors.chatBubbleSent : AppColors.chatBubbleReceived,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateTimeHelper.formatMessageTime(message.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}