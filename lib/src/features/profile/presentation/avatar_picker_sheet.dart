import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../storage/data/storage_repository.dart';
import '../data/avatar_upload_service.dart';
import '../domain/avatar_models.dart';
import '../domain/member_profile.dart';
import 'belong_image_crop_page.dart';

/// Modal bottom sheet allowing members to capture, pick, crop, and update their profile avatar,
/// or handle camera/photo library permission denials gracefully.
class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SystemBottomInset(child: AvatarPickerSheet()),
    );
  }

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet> {
  bool _isLoading = false;
  String? _permissionDeniedMessage;

  Future<void> _handleImageSelection(AvatarImageSource source) async {
    final avatarService = ref.read(avatarUploadServiceProvider);
    final storageRepo = ref.read(storageRepositoryProvider);
    final profile = ref.read(memberProfileProvider);

    setState(() {
      _isLoading = true;
      _permissionDeniedMessage = null;
    });

    try {
      final initialStatus = await avatarService.checkPermission(source);

      if (initialStatus.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showPermanentDenialDialog(context, source);
        return;
      }

      var currentStatus = initialStatus;
      if (!currentStatus.isGranted) {
        currentStatus = await avatarService.requestPermission(source);
      }

      if (currentStatus.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showPermanentDenialDialog(context, source);
        return;
      }

      if (!currentStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _permissionDeniedMessage =
              '${source.label} permission was denied. Please allow access if you wish to use a photo.';
        });
        return;
      }

      // Permission granted: proceed to pick and crop
      final rawBytes = await avatarService.pickImage(source);
      if (rawBytes == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      final framed = await BelongImageCropPage.show(
        context,
        bytes: rawBytes,
        circular: true,
      );
      if (framed == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final croppedBytes = await avatarService.cropSquare(framed);
      final userId = profile.email.isNotEmpty ? profile.email : 'member_guest';
      final downloadUrl = await storageRepo.uploadAvatar(
        userId: userId,
        bytes: croppedBytes,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      ref.read(memberProfileProvider.notifier).setAvatarUrl(downloadUrl);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated peacefully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDeniedMessage = 'Could not update avatar: $e';
      });
    }
  }

  void _showPermanentDenialDialog(
    BuildContext context,
    AvatarImageSource source,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Permission Needed', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '${source.label} permission has been permanently denied. '
          'To take or select an avatar photo, please enable access in your device settings.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            key: const Key('avatar_denial_cancel_button'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            key: const Key('open_app_settings_button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(avatarUploadServiceProvider).openAppSettings();
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final profile = ref.watch(memberProfileProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      color: primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profile Avatar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_permissionDeniedMessage != null)
              Container(
                key: const Key('avatar_permission_denied_banner'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _permissionDeniedMessage!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else ...[
              ListTile(
                key: const Key('avatar_source_camera'),
                leading: CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Take Photo with Camera',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Square circular crop automatically applied',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () => _handleImageSelection(AvatarImageSource.camera),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('avatar_source_gallery'),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Choose from Photos / Gallery',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Select an existing photo from your device',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () => _handleImageSelection(AvatarImageSource.gallery),
              ),
              if (profile.avatarUrl != null &&
                  profile.avatarUrl!.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  key: const Key('avatar_remove_button'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Remove Avatar Photo',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  subtitle: const Text(
                    'Revert back to your initials badge',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    ref.read(memberProfileProvider.notifier).setAvatarUrl(null);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
