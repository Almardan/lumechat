import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String profileImage;
  final Timestamp lastSeen;
  final String status; // Added status field for WhatsApp-like profile

  UserModel({
    required this.userId,
    required this.name,
    required this.profileImage,
    required this.lastSeen,
    this.status = 'Hey there! I am using Flutter Chat', // Default status
  });

  // Create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      profileImage: data['profileImage'] ?? '',
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
      status: data['status'] ?? 'Hey there! I am using Flutter Chat',
    );
  }

  // Convert a UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'profileImage': profileImage,
      'lastSeen': lastSeen,
      'status': status,
    };
  }

  // Create updated user model
  UserModel copyWith({
    String? name,
    String? profileImage,
    Timestamp? lastSeen,
    String? status,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
    );
  }
}