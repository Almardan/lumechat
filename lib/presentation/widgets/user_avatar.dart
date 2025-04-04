import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.divider,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => Image.asset(
                  AppImages.defaultAvatar,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                ),
              )
            : Image.asset(
                AppImages.defaultAvatar,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
              ),
      ),
    );
  }
}
