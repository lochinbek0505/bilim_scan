import 'package:flutter/material.dart';
import '../../services/api_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AuthenticatedImage extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color borderColor;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.name,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderColor = AppColors.goldPrimary,
  });

  String _getInitials(String? text) {
    if (text == null || text.trim().isEmpty) return '?';
    final parts = text.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (imageUrl == null || imageUrl!.isEmpty) {
      avatarChild = _buildInitialsFallback();
    } else {
      final fullUrl = ApiConfig.getFileUrl(imageUrl);
      print(fullUrl);
      avatarChild = Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: AppColors.inputBackground,
                child: Center(
                  child: SizedBox(
                    width: width * 0.35,
                    height: height * 0.35,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildInitialsFallback();
        },
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(child: avatarChild),
    );
  }

  Widget _buildInitialsFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor.withValues(alpha: 0.15),
      ),
      child: Center(
        child: name != null && name!.trim().isNotEmpty
            ? Text(
                _getInitials(name),
                style: AppTextStyles.badgeText.copyWith(
                  fontSize: width * 0.36,
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                Icons.person,
                size: width * 0.5,
                color: borderColor,
              ),
      ),
    );
  }
}
