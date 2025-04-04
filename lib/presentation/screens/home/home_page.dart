import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/cubits/auth_cubit/auth_cubit.dart';
import '../../../logic/cubits/auth_cubit/auth_state.dart';
import '../../../logic/cubits/chat_cubit/chat_cubit.dart';
import '../../../logic/cubits/chat_cubit/chat_state.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/home/new_chat_dialog.dart';
import 'widgets/chat_list.dart';
import 'widgets/empty_chat_list.dart';
import 'widgets/home_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    _chatCubit = BlocProvider.of<ChatCubit>(context);
    _loadChats();
  }

  void _loadChats() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _chatCubit.loadChats();
    } else {
      // If not authenticated, navigate to login
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }
  
  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewChatDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state is ChatListLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ChatListLoaded) {
              final chats = state.chats;
              
              if (chats.isEmpty) {
                return const EmptyChatList();
              }
              
              return ChatList(chats: chats);
            } else if (state is ChatListError) {
              // More user-friendly error display
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load chats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _chatCubit.loadChats(); // Retry loading
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewChatDialog,
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}