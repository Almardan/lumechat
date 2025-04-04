import 'dart:io';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../core/services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  // Get all users who have registered
  Stream<List<UserModel>> getAllUsers() {
    return _chatService.getAllUsers();
  }

  // Get all chats for the current user
  Stream<List<ChatModel>> getChats() {
    return _chatService.getChats();
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatService.getMessages(chatId);
  }

  // Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    await _chatService.sendMessage(
      chatId: chatId,
      receiverId: receiverId,
      text: text,
    );
  }
  
  // Send a media message (image, video, document)
  Future<void> sendMediaMessage({
    required String chatId,
    required String receiverId,
    required File file,
    String caption = '',
  }) async {
    await _chatService.sendMediaMessage(
      chatId: chatId,
      receiverId: receiverId,
      file: file,
      caption: caption,
    );
  }

  // Create a new chat or get an existing one
  Future<String> createOrGetChat(String otherUserId) async {
    return await _chatService.createOrGetChat(otherUserId);
  }

  // Get user information
  Future<UserModel> getUser(String userId) async {
    return await _chatService.getUser(userId);
  }
  
  // Check if user exists
  Future<bool> checkUserExists(String userId) async {
    try {
      final user = await _chatService.getUser(userId);
      return user.userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Get the current user ID
  String get currentUserId => _chatService.currentUserId;
}