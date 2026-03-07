import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';

/// Circular avatar widget — loads local image or shows initials.
class EnduraAvatar extends StatelessWidget {
  final String? imagePath;
  final String? name;
  final double radius;

  const EnduraAvatar({
    super.key,
    this.imagePath,
    this.name,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primarySurface,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage ? _buildImage() : _buildInitials(context),
    );
  }

  Widget _buildImage() {
    final file = File(imagePath!);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildInitialsFallback(),
    );
  }

  Widget _buildInitials(BuildContext context) {
    return _buildInitialsFallback();
  }

  Widget _buildInitialsFallback() {
    final initials = _getInitials();
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}


