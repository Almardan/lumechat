import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastUpdated;
  final Map<String, int> unreadCount; // Track unread message count for each user

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastUpdated,
    required this.unreadCount,
  });

  // Create a ChatModel from a Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert unreadCount map from Firestore
    Map<String, int> unreadCountMap = {};
    if (data['unreadCount'] != null) {
      final Map<String, dynamic> rawMap = data['unreadCount'];
      rawMap.forEach((key, value) {
        unreadCountMap[key] = value as int;
      });
    }
    
    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
      unreadCount: unreadCountMap,
    );
  }

  // Convert a ChatModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdated': lastUpdated,
      'unreadCount': unreadCount,
    };
  }
  
  // Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }
  
  // Create a copy with updated fields
  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    Timestamp? lastUpdated,
    Map<String, int>? unreadCount,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}