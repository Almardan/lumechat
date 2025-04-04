import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/cubits/profile_cubit/profile_cubit.dart';
import '../../../logic/cubits/profile_cubit/profile_state.dart';
import '../../widgets/user_avatar.dart';
import '../../../data/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  File? _selectedImage;
  bool _isImageUploading = false;
  bool _isStatusUpdating = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
        _isImageUploading = true;
      });

      try {
        await context.read<ProfileCubit>().updateProfileImage(_selectedImage!);
      } finally {
        if (mounted) {
          setState(() {
            _isImageUploading = false;
          });
        }
      }
    }
  }

  void _showEditNameDialog(String? currentName) {
    _nameController.text = currentName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                context.read<ProfileCubit>().updateUserName(newName);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditStatusDialog(String? currentStatus) async {
    _statusController.text = currentStatus ?? '';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Status'),
        content: TextField(
          controller: _statusController,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStatus = _statusController.text.trim();
              if (newStatus.isNotEmpty) {
                Navigator.pop(context, newStatus);
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _isStatusUpdating = true;
      });
      
      try {
        await context.read<ProfileCubit>().updateUserStatus(result);
      } finally {
        if (mounted) {
          setState(() {
            _isStatusUpdating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            
            // Clear local loading states when we get success
            if (mounted) {
              setState(() {
                _isImageUploading = false;
                _isStatusUpdating = false;
              });
            }
            
            // Reload profile to ensure we have the latest data
            context.read<ProfileCubit>().loadUserProfile();
          } else if (state is ProfileUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            
            // Clear local loading states on error too
            if (mounted) {
              setState(() {
                _isImageUploading = false;
                _isStatusUpdating = false;
              });
            }
          }
        },
        builder: (context, state) {
          // Show full loading spinner only on initial load
          if (state is ProfileInitial || (state is ProfileLoading && state is! ProfileLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Get user data if available
          UserModel? user;
          bool isUpdatingStatus = _isStatusUpdating;
          bool isUpdatingImage = _isImageUploading;
          
          if (state is ProfileLoaded) {
            user = state.user;
          } 
          
          // Check if we're in an updating state
          if (state is ProfileUpdating) {
            // Get the previous state to access user data
            final previousState = context.read<ProfileCubit>().state;
            if (previousState is ProfileLoaded) {
              // Get user from previous state if not already set
              user ??= previousState.user;
            }
            
            // Update loading flags based on what's being updated
            if (state.updateType == 'status') {
              isUpdatingStatus = true;
            } else if (state.updateType == 'image') {
              isUpdatingImage = true;
            }
          }
          
          // If we couldn't get user data, show loading
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile image section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Stack(
                      children: [
                        // Profile image with loading indicator when needed
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            UserAvatar(
                              imageUrl: isUpdatingImage ? '' : (user.profileImage),
                              radius: 80,
                            ),
                            if (isUpdatingImage)
                              const CircularProgressIndicator(),
                          ],
                        ),
                        
                        // Edit button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: InkWell(
                              onTap: isUpdatingImage ? null : _pickImage,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Info section
                Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name section
                      ListTile(
                        leading: const Icon(Icons.person, color: AppColors.primary),
                        title: const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        trailing: const Icon(Icons.edit, color: AppColors.primary),
                        onTap: () => _showEditNameDialog(user!.name),
                      ),
                      
                      const Divider(height: 1),
                      
                      // Status section with loading indicator when needed
                      ListTile(
                        leading: const Icon(Icons.info, color: AppColors.primary),
                        title: const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: isUpdatingStatus
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Updating status...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                user.status,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                        trailing: const Icon(Icons.edit, color: AppColors.primary),
                        onTap: isUpdatingStatus ? null : () => _showEditStatusDialog(user!.status),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // About section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'LumeChat is a WhatsApp-like messaging application built with Flutter and Firebase.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}