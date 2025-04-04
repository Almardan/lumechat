import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:path/path.dart' as path;

enum MediaType {
  image,
  video,
  document,
}

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  
  factory CloudinaryService() {
    return _instance;
  }
  
  late final Cloudinary cloudinary;
  
  CloudinaryService._internal() {
    
    cloudinary = Cloudinary.signedConfig(
      apiKey: '793569786998382',
      apiSecret: 'ixVDsy979K9Lb4BeYNJVB8TnL24',
      cloudName: 'dblstanf3',
    );
  }
  
  Future<String?> uploadFile(File file, MediaType type) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      final folder = _getFolderName(type);
      
      // Create a unique filename using timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Upload the file
      final response = await cloudinary.upload(
        file: file.path,
        resourceType: _getResourceType(type),
        folder: folder,
        fileName: fileName,
        progressCallback: (count, total) {
          print('Uploading: ${(count / total) * 100}%');
        },
      );
      
      if (response.isSuccessful) {
        print('Upload successful: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        print('Upload failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  // Get the appropriate folder name based on media type
  String _getFolderName(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'images';
      case MediaType.video:
        return 'videos';
      case MediaType.document:
        return 'documents';
    }
  }
  
  // Get the appropriate resource type for Cloudinary
  CloudinaryResourceType _getResourceType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return CloudinaryResourceType.image;
      case MediaType.video:
        return CloudinaryResourceType.video;
      case MediaType.document:
        return CloudinaryResourceType.raw;
    }
  }
  
  // Helper method to determine media type from file extension
  static MediaType getMediaTypeFromExtension(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'].contains(extension)) {
      return MediaType.image;
    } else if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm', '.mkv'].contains(extension)) {
      return MediaType.video;
    } else {
      return MediaType.document;
    }
  }
}