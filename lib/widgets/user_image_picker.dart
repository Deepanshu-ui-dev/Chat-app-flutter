import 'dart:io';
import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({
    super.key,
    required this.onPickImage,
  });

  final void Function(File pickedImage) onPickImage;

  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 300,
    );

    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);

    setState(() {
      _pickedImageFile = imageFile;
    });

    widget.onPickImage(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.background,
                backgroundImage: _pickedImageFile != null
                    ? FileImage(_pickedImageFile!)
                    : null,
                child: _pickedImageFile == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: AppColors.secondary,
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_rounded, color: AppColors.primary, size: 20),
          label: const Text(
            'Select Profile Image',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}