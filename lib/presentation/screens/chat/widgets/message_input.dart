import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../logic/cubits/chat_cubit/chat_cubit.dart';
import '../../../../logic/cubits/chat_cubit/chat_state.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final String chatId;
  final String receiverId;

  const MessageInput({
    super.key,
    required this.controller,
    required this.chatId,
    required this.receiverId,
  });

  void _sendMessage(BuildContext context) {
    final text = controller.text.trim();
    if (Validators.isValidMessage(text)) {
      BlocProvider.of<ChatCubit>(context).sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        text: text,
      );
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Message input field
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: AppStrings.messageHint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(context),
            ),
          ),
          // Send button
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final bool isSending = state is MessageSending;
              
              return IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.send, color: AppColors.primary),
                onPressed: isSending ? null : () => _sendMessage(context),
              );
            },
          ),
        ],
      ),
    );
  }
}