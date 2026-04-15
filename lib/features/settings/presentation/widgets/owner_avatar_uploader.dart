import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../media/controller/media_upload_controller.dart';
import '../../../media/presentation/widgets/uploaded_image_display.dart';
import '../../../media/service/media_upload_service.dart';

// ============================================================================
// OwnerAvatarUploader
// Circular avatar with tap-to-upload, instant preview, animated progress ring
// ============================================================================

class OwnerAvatarUploader extends StatefulWidget {
  const OwnerAvatarUploader({
    super.key,
    this.initialImageUrl,
    this.initialAssetId,
    this.radius = 52,
    this.onUploaded,
    this.name,
  });

  final String? initialImageUrl;
  final String? initialAssetId;
  final double radius;
  final void Function(String assetId, String? cdnUrl)? onUploaded;
  final String? name;

  @override
  State<OwnerAvatarUploader> createState() => _OwnerAvatarUploaderState();
}

class _OwnerAvatarUploaderState extends State<OwnerAvatarUploader>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final MediaUploadController _controller =
      MediaUploadController(service: MediaUploadService());

  bool _isUploading = false;
  double _progress = 0;
  String? _localPath;
  String? _uploadedAssetId;
  String? _uploadedCdnUrl;
  bool _hasError = false;

  late AnimationController _pulseAnim;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SourceSheet(),
    );
    if (src == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: src,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    HapticFeedback.mediumImpact();
    _pulseAnim.repeat(reverse: true);

    setState(() {
      _localPath = picked.path;
      _isUploading = true;
      _progress = 0;
      _hasError = false;
    });

    try {
      final bytes = await picked.readAsBytes();
      final contentType = _guessContentType(picked.name);

      final result = await _controller.uploadOwnerAvatar(
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: true,
      );

      if (!mounted) return;

      _pulseAnim.stop();
      _pulseAnim.reset();

      setState(() {
        _isUploading = false;
        _uploadedAssetId = result.assetId;
        _uploadedCdnUrl = result.cdnUrl;
        _progress = 1.0;
      });

      HapticFeedback.lightImpact();
      widget.onUploaded?.call(result.assetId ?? '', result.cdnUrl);
    } catch (e) {
      if (!mounted) return;
      _pulseAnim.stop();
      _pulseAnim.reset();
      setState(() {
        _isUploading = false;
        _hasError = true;
      });
    }
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  bool get _hasImage =>
      _localPath != null ||
      widget.initialImageUrl != null ||
      widget.initialAssetId != null;

  String? get _initials {
    final name = widget.name;
    if (name == null || name.isEmpty) return null;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFF00C896);
    final size = widget.radius * 2;

    return GestureDetector(
      onTap: _pick,
      child: ScaleTransition(
        scale: _isUploading ? _pulse : const AlwaysStoppedAnimation(1.0),
        child: Stack(
          children: [
            // Avatar circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hasError
                      ? cs.error.withValues(alpha: 0.5)
                      : _isUploading
                          ? accent.withValues(alpha: 0.3)
                          : accent.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _hasImage
                    ? _buildImage(size)
                    : _buildInitials(size, cs, accent),
              ),
            ),

            // Progress ring
            if (_isUploading)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _progress),
                  duration: const Duration(milliseconds: 200),
                  builder: (_, val, _) => CircularProgressIndicator(
                    value: _progress > 0 ? val : null,
                    strokeWidth: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),

            // Camera badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isUploading ? cs.surfaceContainerHighest : accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: _isUploading
                    ? Center(
                        child: Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(
                        _hasError
                            ? Icons.refresh_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double size) {
    if (_localPath != null) {
      return Image.file(
        File(_localPath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) =>
            _buildInitials(size, Theme.of(context).colorScheme, const Color(0xFF00C896)),
      );
    }
    return UploadedImageDisplay(
      assetId: _uploadedAssetId ?? widget.initialAssetId,
      image: _uploadedCdnUrl ?? widget.initialImageUrl,
      height: size,
      width: size,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInitials(double size, ColorScheme cs, Color accent) {
    return Container(
      width: size,
      height: size,
      color: accent.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          _initials ?? '?',
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Source sheet
// ============================================================================

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Update Profile Photo',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
