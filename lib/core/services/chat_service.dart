import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import 'cloudinary_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  // Get the current user ID dynamically
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get all users who have registered (for user selection)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.userId != currentUserId) // Exclude current user
          .toList();
    });
  }

  // Get all chats for the current user
  Stream<List<ChatModel>> getChats() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    // When opening a chat, mark messages as read
    _markChatAsRead(chatId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  // Mark a chat as read for the current user
  Future<void> _markChatAsRead(String chatId) async {
    if (currentUserId.isEmpty) return;
    
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        // Get the current unreadCount map
        final data = chatDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        
        // Set the current user's unread count to 0
        unreadCount[currentUserId] = 0;
        
        // Update the chat document
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCount': unreadCount,
        });
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    if (currentUserId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel.createTextMessage(
      messageId: messageRef.id,
      senderId: currentUserId,
      receiverId: receiverId,
      text: text,
    );

    await _updateChatWithMessage(chatId, text);
    await messageRef.set(message.toFirestore());
  }
  
  // Send a media message (image, video, document)
  Future<void> sendMediaMessage({
    required String chatId,
    required String receiverId,
    required File file,
    String caption = '',
  }) async {
    if (currentUserId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    // Determine media type
    final mediaType = CloudinaryService.getMediaTypeFromExtension(file.path);
    
    // Upload to Cloudinary
    final mediaUrl = await _cloudinaryService.uploadFile(file, mediaType);
    
    if (mediaUrl == null) {
      throw Exception('Failed to upload media');
    }
    
    // Create message reference
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    
    // Get file name and size
    final fileName = path.basename(file.path);
    final fileSize = await file.length();
    
    // Convert media type to message type
    MessageType messageType;
    switch (mediaType) {
      case MediaType.image:
        messageType = MessageType.image;
        break;
      case MediaType.video:
        messageType = MessageType.video;
        break;
      case MediaType.document:
        messageType = MessageType.document;
        break;
    }
    
    // Create message model
    final message = MessageModel.createMediaMessage(
      messageId: messageRef.id,
      senderId: currentUserId,
      receiverId: receiverId,
      type: messageType,
      mediaUrl: mediaUrl,
      mediaName: fileName,
      mediaSize: fileSize,
      text: caption,
    );
    
    // Determine preview text based on media type
    String previewText;
    switch (messageType) {
      case MessageType.image:
        previewText = caption.isNotEmpty ? '📷 $caption' : '📷 Image';
        break;
      case MessageType.video:
        previewText = caption.isNotEmpty ? '🎥 $caption' : '🎥 Video';
        break;
      case MessageType.document:
        previewText = caption.isNotEmpty ? '📄 $caption' : '📄 Document';
        break;
      default:
        previewText = caption;
    }
    
    // Update chat and store message
    await _updateChatWithMessage(chatId, previewText);
    await messageRef.set(message.toFirestore());
  }
  
  // Common method to update chat metadata when sending any type of message
  Future<void> _updateChatWithMessage(String chatId, String previewText) async {
    // Get current chat to update unread counts
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    Map<String, dynamic> unreadCount = {};
    
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      
      // Initialize unreadCount if it doesn't exist
      if (!data.containsKey('unreadCount')) {
        final List<String> participants = List<String>.from(data['participants'] ?? []);
        for (final participant in participants) {
          unreadCount[participant] = participant == currentUserId ? 0 : 1;
        }
      } else {
        unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        
        // For each participant who isn't the sender, increment unread count
        final List<String> participants = List<String>.from(data['participants'] ?? []);
        for (final participant in participants) {
          if (participant != currentUserId) {
            unreadCount[participant] = (unreadCount[participant] ?? 0) + 1;
          }
        }
      }
    }

    // Update the chat with the last message and unread counts
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': previewText,
      'lastUpdated': Timestamp.now(),
      'unreadCount': unreadCount,
    });
  }

  // Create a new chat or get an existing one
  Future<String> createOrGetChat(String otherUserId) async {
    if (currentUserId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    // Create a deterministic chat ID by combining user IDs in a sorted manner
    final List<String> userIds = [currentUserId, otherUserId];
    userIds.sort(); // Sort to ensure the same order regardless of who initiates
    final String chatId = '${userIds[0]}_${userIds[1]}';
    
    // Check if chat exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      // Initialize unreadCount map with 0 for both participants
      Map<String, int> unreadCount = {
        currentUserId: 0,
        otherUserId: 0,
      };
      
      // Create new chat with the combined ID
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': userIds,
        'lastMessage': '',
        'lastUpdated': Timestamp.now(),
        'unreadCount': unreadCount,
      });
    } else {
      // Check if unreadCount exists, if not, add it
      final data = chatDoc.data() as Map<String, dynamic>;
      if (!data.containsKey('unreadCount')) {
        Map<String, int> unreadCount = {
          currentUserId: 0,
          otherUserId: 0,
        };
        
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCount': unreadCount,
        });
      }
      
      // Mark as read for current user
      await _markChatAsRead(chatId);
    }
    
    return chatId;
  }

  // Get user information
  Future<UserModel> getUser(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    
    if (docSnapshot.exists) {
      return UserModel.fromFirestore(docSnapshot);
    } else {
      // Return a placeholder user if not found
      return UserModel(
        userId: userId,
        name: 'User $userId',
        profileImage: '',
        lastSeen: Timestamp.now(),
      );
    }
  }
}