import 'dart:io';
import '../models/user_model.dart';
import '../../core/services/profile_service.dart';

class ProfileRepository {
  final ProfileService _profileService = ProfileService();
  
  // Get current user ID
  String get currentUserId => _profileService.currentUserId;
  
  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    return await _profileService.getCurrentUserProfile();
  }
  
  // Get info for any user by ID
  Future<UserModel> getUserInfo(String userId) async {
    return await _profileService.getUserInfo(userId);
  }
  
  // Update user name
  Future<bool> updateUserName(String newName) async {
    return await _profileService.updateUserName(newName);
  }
  
  // Update user status
  Future<bool> updateUserStatus(String newStatus) async {
    return await _profileService.updateUserStatus(newStatus);
  }
  
  // Update profile image
  Future<String?> updateProfileImage(File imageFile) async {
    return await _profileService.updateProfileImage(imageFile);
  }
  
  // Update last seen
  Future<void> updateLastSeen() async {
    await _profileService.updateLastSeen();
  }
}