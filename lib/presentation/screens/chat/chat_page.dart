import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/data_time_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/chat/media_picker_bottom_sheet.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/user_avatar.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String receiverId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  
  UserModel? _receiver;
  bool _isLoading = true;
  bool _isSendingMedia = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceiverInfo();
  }

  Future<void> _loadReceiverInfo() async {
    try {
      final receiver = await _chatRepository.getUser(widget.receiverId);
      if (mounted) {
        setState(() {
          _receiver = receiver;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user info: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (Validators.isValidMessage(text)) {
      _messageController.clear();
      
      try {
        await _chatRepository.sendMessage(
          chatId: widget.chatId,
          receiverId: widget.receiverId,
          text: text,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaPickerBottomSheet(
        onMediaSelected: _sendMediaMessage,
      ),
    );
  }
  
  void _sendMediaMessage(File file, String? caption) async {
    try {
      setState(() {
        _isSendingMedia = true;
      });
      
      await _chatRepository.sendMediaMessage(
        chatId: widget.chatId,
        receiverId: widget.receiverId,
        file: file,
        caption: caption ?? '',
      );
      
      setState(() {
        _isSendingMedia = false;
      });
    } catch (e) {
      setState(() {
        _isSendingMedia = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isLoading
            ? const Text('Loading...')
            : Row(
                children: [
                  UserAvatar(
                    imageUrl: _receiver?.profileImage ?? '',
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receiver?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_receiver != null)
                          Text(
                            DateTimeHelper.formatLastSeen(_receiver!.lastSeen),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // Future calling features can be added here
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options to be implemented later
            },
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : Stack(
              children: [
                Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: StreamBuilder<List<MessageModel>>(
                        stream: _chatRepository.getMessages(widget.chatId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading messages: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final messages = snapshot.data ?? [];

                          if (messages.isEmpty) {
                            return const Center(
                              child: Text(
                                'No messages yet. Say hello!',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Display newest messages at the bottom
                            padding: const EdgeInsets.all(8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isSentByMe = message.senderId == _chatRepository.currentUserId;

                              return ChatBubble(
                                message: message,
                                isSentByMe: isSentByMe,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Message input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Media attachment button
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            color: AppColors.primary,
                            onPressed: _showMediaPicker,
                          ),
                          // Message input field
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendTextMessage(),
                            ),
                          ),
                          // Send button
                          IconButton(
                            icon: const Icon(Icons.send, color: AppColors.primary),
                            onPressed: _sendTextMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Media sending overlay
                if (_isSendingMedia)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Uploading media...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}