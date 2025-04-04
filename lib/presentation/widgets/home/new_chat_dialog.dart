import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../routes/app_routes.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a user ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if creating chat with self
      final currentUser = AuthRepository().getCurrentUser();
      if (currentUser?.uid == userId) {
        setState(() {
          _errorMessage = 'Cannot chat with yourself';
          _isLoading = false;
        });
        return;
      }

      // Create or get existing chat
      final chatRepository = ChatRepository();
      final chatId = await chatRepository.createOrGetChat(userId);
      
      if (!mounted) return;

      // Close dialog and navigate to chat screen
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(
        AppRoutes.chat,
        arguments: {
          'chatId': chatId,
          'receiverId': userId,
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create chat: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userIdController,
            decoration: InputDecoration(
              labelText: 'Enter User ID',
              errorText: _errorMessage,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter the user ID of the person you want to chat with.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Start Chat'),
        ),
      ],
    );
  }
}