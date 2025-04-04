import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';

enum MediaSource { camera, gallery, document }

class MediaPickerBottomSheet extends StatelessWidget {
  final Function(File file, String? caption) onMediaSelected;

  const MediaPickerBottomSheet({
    super.key,
    required this.onMediaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Share Media',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildOption(
                context,
                Icons.camera_alt,
                'Camera',
                () => _pickMedia(context, MediaSource.camera),
              ),
              _buildOption(
                context,
                Icons.photo,
                'Gallery',
                () => _pickMedia(context, MediaSource.gallery),
              ),
              _buildOption(
                context,
                Icons.insert_drive_file,
                'Document',
                () => _pickMedia(context, MediaSource.document),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(BuildContext context, MediaSource source) async {
    File? pickedFile;
    
    try {
      switch (source) {
        case MediaSource.camera:
          final imagePicker = ImagePicker();
          final pickedImage = await imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 70,
          );
          if (pickedImage != null) {
            pickedFile = File(pickedImage.path);
          }
          break;
          
        case MediaSource.gallery:
          final imagePicker = ImagePicker();
          final pickedImage = await imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 70,
          );
          if (pickedImage != null) {
            pickedFile = File(pickedImage.path);
          }
          break;
          
        case MediaSource.document:
          final result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.isNotEmpty) {
            pickedFile = File(result.files.first.path!);
          }
          break;
      }
      
      if (pickedFile != null) {
        // First close the bottom sheet
        Navigator.pop(context);
        
        // Then show caption dialog
        _showCaptionDialog(context, pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking media: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  void _showCaptionDialog(BuildContext context, File file) {
    final TextEditingController captionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Caption'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(
            hintText: 'Add a caption (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onMediaSelected(file, captionController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}