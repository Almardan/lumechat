import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import 'cloudinary_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  
  factory ProfileService() {
    return _instance;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  ProfileService._internal();
  
  // Get the current user ID
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUserId.isEmpty) return null;
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUserId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Error getting current user profile: $e');
    }
    
    return null;
  }
  
  // Get any user's profile by ID
  Future<UserModel> getUserInfo(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Error getting user info: $e');
      throw Exception('Failed to get user info: $e');
    }
    
    // Return a placeholder user if not found
    return UserModel(
      userId: userId,
      name: 'User $userId',
      profileImage: '',
      lastSeen: Timestamp.now(),
    );
  }
  
  // Update user name
  Future<bool> updateUserName(String newName) async {
    if (currentUserId.isEmpty) return false;
    
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'name': newName,
      });
      
      // Also update the display name in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
      }
      
      return true;
    } catch (e) {
      print('Error updating user name: $e');
      return false;
    }
  }
  
  // Update user status
  Future<bool> updateUserStatus(String newStatus) async {
    if (currentUserId.isEmpty) return false;
    
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'status': newStatus,
      });
      
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }
  
  // Update profile image
  Future<String?> updateProfileImage(File imageFile) async {
    if (currentUserId.isEmpty) return null;
    
    try {
      // Upload to Cloudinary
      final mediaUrl = await _cloudinaryService.uploadFile(
        imageFile, 
        MediaType.image,
      );
      
      if (mediaUrl == null) {
        return null;
      }
      
      // Update Firestore
      await _firestore.collection('users').doc(currentUserId).update({
        'profileImage': mediaUrl,
      });
      
      // Also update the photo URL in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(mediaUrl);
      }
      
      return mediaUrl;
    } catch (e) {
      print('Error updating profile image: $e');
      return null;
    }
  }
  
  // Update last seen
  Future<void> updateLastSeen() async {
    if (currentUserId.isEmpty) return;
    
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'lastSeen': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }
}