import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  document,
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final MessageType type;
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaSize; // Size in bytes

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaUrl,
    this.mediaName,
    this.mediaSize,
  });

  // Create a MessageModel from a Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse message type
    MessageType messageType = MessageType.text;
    if (data['type'] != null) {
      final typeStr = data['type'] as String;
      messageType = MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => MessageType.text,
      );
    }
    
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      type: messageType,
      mediaUrl: data['mediaUrl'],
      mediaName: data['mediaName'],
      mediaSize: data['mediaSize'],
    );
  }

  // Convert a MessageModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'mediaName': mediaName,
      'mediaSize': mediaSize,
    };
  }
  
  // Create a text message
  static MessageModel createTextMessage({
    required String messageId,
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    return MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: Timestamp.now(),
      type: MessageType.text,
    );
  }
  
  // Create a media message
  static MessageModel createMediaMessage({
    required String messageId,
    required String senderId,
    required String receiverId,
    required MessageType type,
    required String mediaUrl,
    required String mediaName,
    int? mediaSize,
    String text = '',
  }) {
    return MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: Timestamp.now(),
      type: type,
      mediaUrl: mediaUrl,
      mediaName: mediaName,
      mediaSize: mediaSize,
    );
  }
}