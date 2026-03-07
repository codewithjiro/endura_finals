import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';

/// Horizontal scrollable row of photo thumbnails.
class PhotoGallery extends StatelessWidget {
  final List<String> photoPaths;
  final double height;
  final VoidCallback? onAddTap;
  final void Function(int index)? onRemove;

  const PhotoGallery({
    super.key,
    required this.photoPaths,
    this.height = 100,
    this.onAddTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoPaths.length + (onAddTap != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (onAddTap != null && index == 0) {
            return _AddPhotoTile(height: height, onTap: onAddTap!);
          }
          final photoIndex = onAddTap != null ? index - 1 : index;
          return _PhotoTile(
            path: photoPaths[photoIndex],
            height: height,
            onRemove: onRemove != null ? () => onRemove!(photoIndex) : null,
            onTap: () => _showFullScreen(context, photoPaths, photoIndex),
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, List<String> paths, int initial) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPhoto(paths: paths, initialIndex: initial),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final double height;
  final VoidCallback onTap;

  const _AddPhotoTile({required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: height,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          CupertinoIcons.camera_fill,
          color: AppTheme.primary,
          size: 28,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final double height;
  final VoidCallback? onRemove;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.path,
    required this.height,
    this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Image.file(
              File(path),
              width: height,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: height,
                height: height,
                color: CupertinoColors.systemGrey5,
                child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey3),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullScreenPhoto extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _FullScreenPhoto({required this.paths, required this.initialIndex});

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xCC000000),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        itemBuilder: (_, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.file(
                File(widget.paths[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}


