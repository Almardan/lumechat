import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/data_time_helper.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../routes/app_routes.dart';
import '../user_avatar.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String otherUserId;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    final chatRepository = ChatRepository();
    final currentUserId = chatRepository.currentUserId;
    final unreadCount = chat.getUnreadCountForUser(currentUserId);
    final hasUnreadMessages = unreadCount > 0;
    
    return FutureBuilder(
      future: chatRepository.getUser(otherUserId),
      builder: (context, snapshot) {
        // Get user info for display
        String userName = 'User';
        String userImage = '';
        
        if (snapshot.hasData && snapshot.data != null) {
          userName = snapshot.data!.name;
          userImage = snapshot.data!.profileImage;
        }
        
        return ListTile(
          leading: Stack(
            children: [
              UserAvatar(
                imageUrl: userImage,
                radius: 24,
              ),
              // Only show new message indicator if there are unread messages
              if (hasUnreadMessages)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            userName,
            style: TextStyle(
              fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: hasUnreadMessages ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateTimeHelper.formatChatListTime(chat.lastUpdated),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnreadMessages ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              // Add a visual indicator for new messages
              if (hasUnreadMessages)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.chat,
              arguments: {
                'chatId': chat.chatId,
                'receiverId': otherUserId,
              },
            );
          },
        );
      },
    );
  }
}