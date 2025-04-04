import 'package:equatable/equatable.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

// States for the chat list (home page)
class ChatListInitial extends ChatState {}

class ChatListLoading extends ChatState {}

class ChatListLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatListError extends ChatState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

// States for the individual chat page
class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final UserModel receiver;

  const ChatLoaded({
    required this.messages,
    required this.receiver,
  });

  @override
  List<Object?> get props => [messages, receiver];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageSending extends ChatState {}

class MessageSent extends ChatState {}

class MessageError extends ChatState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}