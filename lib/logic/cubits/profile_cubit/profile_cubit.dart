import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository = ProfileRepository();

  ProfileCubit() : super(ProfileInitial());

  // Load user profile
  Future<void> loadUserProfile() async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.getCurrentUserProfile();
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(const ProfileError('User profile not found'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  // Update user name
  Future<void> updateUserName(String newName) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileUpdating('name'));
      try {
        final success = await _profileRepository.updateUserName(newName);
        if (success) {
          // Update the user object with the new name
          final updatedUser = currentState.user.copyWith(name: newName);
          emit(ProfileLoaded(updatedUser));
          emit(const ProfileUpdateSuccess('Name updated successfully'));
        } else {
          emit(const ProfileUpdateError('Failed to update name'));
        }
      } catch (e) {
        emit(ProfileUpdateError('Error updating name: $e'));
      }
    }
  }

  // Update user status
  Future<void> updateUserStatus(String newStatus) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileUpdating('status'));
      try {
        final success = await _profileRepository.updateUserStatus(newStatus);
        if (success) {
          // Update the user object with the new status
          final updatedUser = currentState.user.copyWith(status: newStatus);
          emit(ProfileLoaded(updatedUser));
          emit(const ProfileUpdateSuccess('Status updated successfully'));
        } else {
          emit(const ProfileUpdateError('Failed to update status'));
        }
      } catch (e) {
        emit(ProfileUpdateError('Error updating status: $e'));
      }
    }
  }

  // Update profile image
  Future<void> updateProfileImage(File imageFile) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileUpdating('image'));
      try {
        final imageUrl = await _profileRepository.updateProfileImage(imageFile);
        if (imageUrl != null) {
          // Update the user object with the new image URL
          final updatedUser = currentState.user.copyWith(profileImage: imageUrl);
          emit(ProfileLoaded(updatedUser));
          emit(const ProfileUpdateSuccess('Profile picture updated successfully'));
        } else {
          emit(const ProfileUpdateError('Failed to update profile picture'));
        }
      } catch (e) {
        emit(ProfileUpdateError('Error updating profile picture: $e'));
      }
    }
  }

  // Update last seen
  Future<void> updateLastSeen() async {
    try {
      await _profileRepository.updateLastSeen();
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }
}