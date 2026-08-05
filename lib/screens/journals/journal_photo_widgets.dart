import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/journal_photo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class JournalPhotoAttachment extends StatelessWidget {
  const JournalPhotoAttachment({
    required this.onRemove,
    required this.onPreview,
    required this.semanticLabel,
    super.key,
    this.bytes,
    this.photo,
    this.uploading = false,
  }) : assert(bytes != null || photo != null);

  final Uint8List? bytes;
  final JournalPhoto? photo;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;
  final String semanticLabel;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onPreview != null,
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Material(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPreview,
                child: bytes != null
                    ? _MemoryPhoto(bytes: bytes!)
                    : JournalPhotoImage(photo: photo!),
              ),
            ),
            if (uploading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 3,
                right: 3,
                child: Semantics(
                  button: true,
                  label: 'Remove photo',
                  child: IconButton.filled(
                    onPressed: onRemove,
                    tooltip: 'Remove photo',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .62),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 40),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class JournalPhotoImage extends StatelessWidget {
  const JournalPhotoImage({
    required this.photo,
    super.key,
    this.fit = BoxFit.cover,
  });

  final JournalPhoto photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = photo.signedUrl;
    if (url == null || url.isEmpty) return const _UnavailablePhoto();
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: 'Attached journal photo',
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final expected = progress.expectedTotalBytes;
        return Center(
          child: CircularProgressIndicator(
            value: expected == null
                ? null
                : progress.cumulativeBytesLoaded / expected,
          ),
        );
      },
      errorBuilder: (_, _, _) => const _UnavailablePhoto(),
    );
  }
}

Future<void> showJournalPhotoPreview(
  BuildContext context, {
  Uint8List? bytes,
  JournalPhoto? photo,
}) {
  assert(bytes != null || photo != null);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .86),
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: const Color(0xFF101713),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 4,
                child: Center(
                  child: bytes != null
                      ? Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const _UnavailablePhoto(onDark: true),
                        )
                      : JournalPhotoImage(photo: photo!, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(dialogContext),
                tooltip: 'Close photo preview',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .52),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MemoryPhoto extends StatelessWidget {
  const _MemoryPhoto({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const _UnavailablePhoto(),
    );
  }
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white70 : AppColors.secondaryText;
    return ColoredBox(
      color: onDark ? const Color(0xFF101713) : AppColors.surfaceMuted,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: color),
              const SizedBox(height: 6),
              Text(
                'Photo unavailable',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
