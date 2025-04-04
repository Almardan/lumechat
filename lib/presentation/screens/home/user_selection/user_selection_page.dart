import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../logic/cubits/auth_cubit/auth_cubit.dart';
import '../../../../logic/cubits/auth_cubit/auth_state.dart';
import '../../../../logic/cubits/profile_cubit/profile_cubit.dart';
import '../../../../logic/cubits/profile_cubit/profile_state.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/user_avatar.dart';


class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  final ChatRepository _chatRepository = ChatRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  bool _isLoading = false;
  UserModel? _currentUser;
  bool _includeCurrentUser = false; // Toggle for showing current user
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final user = await _profileRepository.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading current user profile: $e');
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }
    
    return users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) || 
             user.status.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          // When profile is updated, reload the current user profile
          if (state is ProfileUpdateSuccess || state is ProfileLoaded) {
            _loadCurrentUserProfile();
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Profile Card at the top when not searching
              if (_currentUser != null && !_isSearching) _buildProfileCard(),
              
              // User List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadCurrentUserProfile();
                    // Trigger a setState to refresh the UI
                    setState(() {});
                  },
                  child: StreamBuilder<List<UserModel>>(
                    stream: _chatRepository.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      
                      List<UserModel> users = snapshot.data ?? [];
                      
                      // If toggle is on and we have current user data, add the current user to the list
                      if (_includeCurrentUser && _currentUser != null) {
                        // Check if current user is already in the list to avoid duplication
                        bool isCurrentUserInList = users.any((user) => user.userId == _currentUser!.userId);
                        
                        if (!isCurrentUserInList) {
                          // Add current user with "You" in the name to make it clear
                          UserModel userWithYouTag = UserModel(
                            userId: _currentUser!.userId,
                            name: "${_currentUser!.name} (You)",
                            profileImage: _currentUser!.profileImage,
                            lastSeen: _currentUser!.lastSeen,
                            status: _currentUser!.status,
                          );
                          
                          // Add current user at the beginning of the list
                          users = [userWithYouTag, ...users];
                        }
                      }
                      
                      // Filter users based on search query
                      final filteredUsers = _filterUsers(users);
                      
                      if (filteredUsers.isEmpty) {
                        if (_searchQuery.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found for "$_searchQuery"',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const Center(
                          child: Text('No users found'),
                        );
                      }
                      
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isCurrentUser = user.userId == _currentUser?.userId;
                          
                          return ListTile(
                            leading: Stack(
                              children: [
                                UserAvatar(
                                  imageUrl: user.profileImage,
                                  radius: 24,
                                ),
                                if (isCurrentUser)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              user.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: isCurrentUser 
                                ? const Chip(
                                    label: Text(
                                      'You',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  )
                                : null,
                            onTap: () => _startChatWithUser(user),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: AppColors.primary,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search for users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          cursorColor: Colors.white,
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSearch,
          ),
        ],
      );
    }
    
    return AppBar(
      title: const Text('Select User'),
      backgroundColor: AppColors.primary,
      actions: [
        // Toggle switch for including current user
        Row(
          children: [
            const Text('Include me', style: TextStyle(fontSize: 12)),
            Switch(
              value: _includeCurrentUser,
              onChanged: (value) {
                setState(() {
                  _includeCurrentUser = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: AppColors.accent,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context);
            } else if (value == 'profile') {
              _navigateToProfile();
            } else if (value == 'refresh') {
              _loadCurrentUserProfile();
              setState(() {});
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Text('Profile'),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Text('Refresh'),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Text('Settings'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _navigateToProfile() async {
    // Navigate to profile and wait for result
    final result = await Navigator.of(context).pushNamed(AppRoutes.profile);
    // When returning from profile page, refresh the current user data
    _loadCurrentUserProfile();
  }

  Widget _buildProfileCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _navigateToProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: _currentUser?.profileImage ?? '',
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.name ?? 'Your Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.status ?? 'Your Status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                ),
                onPressed: _navigateToProfile,
                tooltip: 'Edit Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChatWithUser(UserModel user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create or get chat using the user's ID
      final chatId = await _chatRepository.createOrGetChat(user.userId);
      
      if (!mounted) return;
      
      // Navigate to chat screen
      Navigator.of(context).pushNamed(
        AppRoutes.chat,
        arguments: {
          'chatId': chatId,
          'receiverId': user.userId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}