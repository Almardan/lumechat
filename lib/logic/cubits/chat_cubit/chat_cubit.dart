import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository = ChatRepository();
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatCubit() : super(ChatListInitial());

  String get currentUserId => _chatRepository.currentUserId;

  // Load all chats for the home page
  void loadChats() {
    emit(ChatListLoading());

    try {
      _chatsSubscription?.cancel();
      _chatsSubscription = _chatRepository.getChats().listen(
        (chats) {
          emit(ChatListLoaded(chats));
        },
        onError: (error) {
          emit(ChatListError('Failed to load chats: $error'));
        },
      );
    } catch (e) {
      emit(ChatListError('Failed to load chats: $e'));
    }
  }

  // Load messages for a specific chat
  void loadMessages(String chatId, String receiverId) async {
    emit(ChatLoading());

    try {
      // Get user info for the receiver
      final receiver = await _chatRepository.getUser(receiverId);

      // Listen to messages
      _messagesSubscription?.cancel();
      _messagesSubscription = _chatRepository.getMessages(chatId).listen(
        (messages) {
          emit(ChatLoaded(messages: messages, receiver: receiver));
        },
        onError: (error) {
          emit(ChatError('Failed to load messages: $error'));
        },
      );
    } catch (e) {
      emit(ChatError('Failed to load chat: $e'));
    }
  }

  // Send a new message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    try {
      emit(MessageSending());
      await _chatRepository.sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        text: text,
      );
      emit(MessageSent());
    } catch (e) {
      emit(MessageError('Failed to send message: $e'));
    }
  }

  // Create or get a chat with another user
  Future<String> createOrGetChat(String otherUserId) async {
    return await _chatRepository.createOrGetChat(otherUserId);
  }
  
  // Get user information
  Future<UserModel> getUser(String userId) async {
    return await _chatRepository.getUser(userId);
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}