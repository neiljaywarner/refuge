import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../../core/widgets/calm_media_image.dart';
import '../../profile/data/avatar_upload_service.dart';
import '../../profile/domain/avatar_models.dart';
import '../../profile/presentation/belong_image_crop_page.dart';
import '../domain/calm_meme.dart';
import 'giphy_search_panel.dart';

/// Opens one Attach media sheet: GIF search first, with Belong memes, a
/// pasted link, and a photo under More.
void showMemeGalleryModal(BuildContext context, {required ValueChanged<CalmMeme> onSelectedMeme}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: .vertical(top: .circular(20.0))),
    builder: (ctx) => _AttachMediaSheet(onSelectedMeme: onSelectedMeme),
  );
}

/// Sizes the sheet to the space above the keyboard so GIF results stay bounded.
class _AttachMediaSheet extends StatelessWidget {
  const _AttachMediaSheet({required this.onSelectedMeme});

  final ValueChanged<CalmMeme> onSelectedMeme;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = SystemInsets.bottom(media);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;
        final available = math.max(0.0, maxHeight - bottom);
        // Use the full gap above the keyboard on a short phone. On a tall
        // screen, leave a sliver of the page visible so the sheet can dismiss.
        final height = available < 420 ? available : available * 0.94;
        return Padding(
          padding: .only(bottom: bottom),
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(bottom: 0),
              viewPadding: media.viewPadding.copyWith(bottom: 0),
              viewInsets: media.viewInsets.copyWith(bottom: 0),
            ),
            child: SizedBox(
              height: height,
              child: _MemeGalleryModalContent(onSelectedMeme: onSelectedMeme),
            ),
          ),
        );
      },
    );
  }
}

enum _AttachMoreSection { none, memes, link, photo }

class _MemeGalleryModalContent extends ConsumerStatefulWidget {
  final ValueChanged<CalmMeme> onSelectedMeme;

  const _MemeGalleryModalContent({required this.onSelectedMeme});

  @override
  ConsumerState<_MemeGalleryModalContent> createState() => _MemeGalleryModalContentState();
}

class _MemeGalleryModalContentState extends ConsumerState<_MemeGalleryModalContent> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _uploadCaptionController = TextEditingController();

  var _moreOpen = false;
  var _moreSection = _AttachMoreSection.none;
  String? _uploadedDataUri;
  bool _isUploading = false;
  String? _permissionDeniedMessage;
  bool _isPermanentDenial = false;

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    _uploadCaptionController.dispose();
    super.dispose();
  }

  void _select(CalmMeme meme) {
    widget.onSelectedMeme(meme);
    Navigator.pop(context);
  }

  void _applyPreset({required String title, required String url}) {
    setState(() {
      _captionController.text = title;
      _urlController.text = url;
    });
  }

  void _submitCustomMeme() {
    final url = _urlController.text.trim();
    final caption = _captionController.text.trim().isNotEmpty
        ? _captionController.text.trim()
        : 'Relatable Faith & Neurodiversity';

    _select(
      CalmMeme(
        title: caption,
        icon: '🖼️',
        subtitle: 'Member Shared Meme / GIF',
        tag: 'Memes',
        body: caption,
        imageUrl: url.isNotEmpty ? url : null,
      ),
    );
  }

  Future<void> _pickImage(AvatarImageSource source) async {
    final avatarService = ref.read(avatarUploadServiceProvider);

    setState(() {
      _isUploading = true;
      _permissionDeniedMessage = null;
      _isPermanentDenial = false;
    });

    try {
      final initialStatus = await avatarService.checkPermission(source);

      if (initialStatus.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _isPermanentDenial = true;
          _permissionDeniedMessage =
              '${source.label} permission is permanently denied. You can enable it peacefully in system settings.';
        });
        return;
      }

      var currentStatus = initialStatus;
      if (!currentStatus.isGranted) {
        currentStatus = await avatarService.requestPermission(source);
      }

      if (currentStatus.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _isPermanentDenial = true;
          _permissionDeniedMessage =
              '${source.label} permission is permanently denied. You can enable it peacefully in system settings.';
        });
        return;
      }

      if (!currentStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _permissionDeniedMessage =
              '${source.label} permission was denied. Please allow access if you wish to use a photo.';
        });
        return;
      }

      final bytes = await avatarService.pickImage(source);
      if (bytes == null) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        return;
      }

      if (!mounted) return;
      final framed = await BelongImageCropPage.show(context, bytes: bytes, circular: false);
      if (framed == null) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        return;
      }

      final base64String = base64Encode(framed);
      final dataUri = 'data:image/png;base64,$base64String';

      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadedDataUri = dataUri;
        if (_uploadCaptionController.text.isEmpty) {
          _uploadCaptionController.text = source == AvatarImageSource.camera
              ? 'Photo Reflection'
              : 'Community Photo Reflection';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _permissionDeniedMessage = 'Could not select photo: $e';
      });
    }
  }

  void _submitUploadedPhoto() {
    if (_uploadedDataUri == null) return;

    final caption = _uploadCaptionController.text.trim().isNotEmpty
        ? _uploadCaptionController.text.trim()
        : 'Photo Reflection';

    _select(
      CalmMeme(
        title: caption,
        icon: '📷',
        subtitle: 'Member Uploaded Photo',
        tag: 'Photos',
        body: caption,
        imageUrl: _uploadedDataUri,
      ),
    );
  }

  void _toggleSection(_AttachMoreSection section) {
    setState(() {
      _moreSection = _moreSection == section ? _AttachMoreSection.none : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetColor =
        Theme.of(context).bottomSheetTheme.modalBackgroundColor ??
        Theme.of(context).bottomSheetTheme.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerLow;

    return Padding(
      padding: const .fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attach media',
                  key: Key('attach_media_title'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                key: const Key('meme_gallery_close_button'),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Focus(
                  canRequestFocus: !_moreOpen,
                  descendantsAreFocusable: !_moreOpen,
                  child: ExcludeSemantics(
                    excluding: _moreOpen,
                    child: IgnorePointer(
                      ignoring: _moreOpen,
                      child: GiphySearchPanel(
                        onSelected: (meme) {
                          widget.onSelectedMeme(meme);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
                if (_moreOpen) Material(color: sheetColor, child: _buildMoreList()),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              identifier: 'attach_media_more',
              button: true,
              child: TextButton.icon(
                key: const Key('attach_media_more'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  final opening = !_moreOpen;
                  setState(() {
                    _moreOpen = opening;
                    if (!opening) _moreSection = _AttachMoreSection.none;
                  });
                  if (opening) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
                  }
                },
                icon: Icon(_moreOpen ? Icons.gif_box_outlined : Icons.expand_more, size: 18),
                label: Text(_moreOpen ? 'Back to GIFs' : 'More'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreList() => ListView(
    key: const Key('attach_media_more_panel'),
    children: [
      _sectionTile(
        key: const Key('attach_media_memes'),
        title: 'Belong memes',
        section: _AttachMoreSection.memes,
      ),
      if (_moreSection == _AttachMoreSection.memes)
        for (final meme in kCuratedCalmMemes) ...[_curatedTile(meme), const SizedBox(height: 8)],
      _sectionTile(
        key: const Key('attach_media_link'),
        title: 'Paste a link',
        section: _AttachMoreSection.link,
      ),
      if (_moreSection == _AttachMoreSection.link) _buildCustomMemeForm(),
      _sectionTile(
        key: const Key('attach_media_photo'),
        title: 'Photo',
        section: _AttachMoreSection.photo,
      ),
      if (_moreSection == _AttachMoreSection.photo) _buildUploadPhotoForm(),
    ],
  );

  Widget _sectionTile({
    required Key key,
    required String title,
    required _AttachMoreSection section,
  }) {
    final open = _moreSection == section;
    return Semantics(
      identifier: switch (section) {
        _AttachMoreSection.memes => 'attach_media_memes',
        _AttachMoreSection.link => 'attach_media_link',
        _AttachMoreSection.photo => 'attach_media_photo',
        _AttachMoreSection.none => 'attach_media_section',
      },
      button: true,
      child: ListTile(
        key: key,
        dense: true,
        contentPadding: .zero,
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: Icon(open ? Icons.expand_less : Icons.expand_more, size: 18),
        onTap: () => _toggleSection(section),
      ),
    );
  }

  Widget _curatedTile(CalmMeme meme) => InkWell(
    onTap: () => _select(meme),
    borderRadius: .circular(12),
    child: Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
        borderRadius: .circular(12),
        color: Colors.amber.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          if (meme.imageUrl != null)
            ClipRRect(
              borderRadius: .circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CalmMediaImage(
                  imageUrl: meme.imageUrl!,
                  fit: BoxFit.cover,
                  fallbackWidget: Center(
                    child: Text(meme.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            )
          else
            Text(meme.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(meme.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  meme.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(meme.body, style: const TextStyle(fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildCustomMemeForm() => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Wholesome, sensory-safe media. Skip flashing animations.',
        style: TextStyle(fontSize: 11, color: Colors.teal.shade900, height: 1.35),
      ),
      const SizedBox(height: 10),
      TextField(
        key: const Key('meme_url_input'),
        controller: _urlController,
        decoration: InputDecoration(
          labelText: 'Image or GIF URL',
          hintText: 'https://.../wholesome_meme.gif',
          hintStyle: const TextStyle(fontSize: 11),
          isDense: true,
          prefixIcon: const Icon(Icons.link, size: 16),
          border: OutlineInputBorder(borderRadius: .circular(10)),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      TextField(
        key: const Key('meme_caption_input'),
        controller: _captionController,
        decoration: InputDecoration(
          labelText: 'Meme Title or Caption',
          hintText: 'e.g. When the sanctuary lights are just right',
          hintStyle: const TextStyle(fontSize: 11),
          isDense: true,
          prefixIcon: const Icon(Icons.title, size: 16),
          border: OutlineInputBorder(borderRadius: .circular(10)),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ActionChip(
            key: const Key('preset_elijah'),
            label: const Text('Elijah Rest & Nap', style: TextStyle(fontSize: 11)),
            onPressed: () => _applyPreset(
              title: 'Elijah Under the Broom Tree (Snack & Nap)',
              url: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
            ),
          ),
          ActionChip(
            key: const Key('preset_special_interest'),
            label: const Text('Special Interest Deep Dive', style: TextStyle(fontSize: 11)),
            onPressed: () => _applyPreset(
              title: 'Autistic Deep-Dive PowerPoint Mode',
              url: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600',
            ),
          ),
          ActionChip(
            key: const Key('preset_quiet_waters'),
            label: const Text('Quiet Waters & Stillness', style: TextStyle(fontSize: 11)),
            onPressed: () => _applyPreset(
              title: 'He Leads Me Beside Quiet Waters',
              url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
            ),
          ),
        ],
      ),
      if (_urlController.text.trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          key: const Key('custom_meme_preview'),
          padding: const .all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.shade700),
            borderRadius: .circular(10),
            color: Colors.amber.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Text(
                'Preview Attached Meme / GIF:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: .circular(8),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CalmMediaImage(
                    imageUrl: _urlController.text.trim(),
                    fit: BoxFit.cover,
                    fallbackWidget: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text(
                          'Image preview unavailable (URL will still be attached)',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('attach_custom_meme_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: .circular(10)),
          ),
          onPressed: _submitCustomMeme,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text(
            'Attach Meme / GIF to Reflection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ],
  );

  Widget _buildUploadPhotoForm() => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Text(
        'A peaceful photo for the fellowship.',
        style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.35),
      ),
      const SizedBox(height: 10),
      if (_permissionDeniedMessage != null) ...[
        Container(
          key: const Key('meme_permission_denied_banner'),
          padding: const .all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: .circular(8),
            border: Border.all(color: Colors.orange.shade400),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _permissionDeniedMessage!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isPermanentDenial) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('meme_open_settings_button'),
                    onPressed: () {
                      ref.read(avatarUploadServiceProvider).openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 14),
                    label: const Text('Open Settings', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('meme_upload_camera_button'),
              style: OutlinedButton.styleFrom(
                padding: const .symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: .circular(10)),
              ),
              onPressed: _isUploading ? null : () => _pickImage(AvatarImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text(
                'Use Camera',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('meme_upload_gallery_button'),
              style: OutlinedButton.styleFrom(
                padding: const .symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: .circular(10)),
              ),
              onPressed: _isUploading ? null : () => _pickImage(AvatarImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text(
                'Choose Photo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      if (_isUploading) ...[
        const SizedBox(height: 12),
        const Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
      if (_uploadedDataUri != null) ...[
        const SizedBox(height: 14),
        Container(
          key: const Key('uploaded_photo_preview'),
          padding: const .all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.shade700),
            borderRadius: .circular(10),
            color: Colors.amber.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  const Text(
                    'Selected Photo Preview:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    key: const Key('remove_uploaded_photo_button'),
                    onTap: () {
                      setState(() => _uploadedDataUri = null);
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: .circular(8),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CalmMediaImage(imageUrl: _uploadedDataUri!, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('meme_upload_caption_input'),
          controller: _uploadCaptionController,
          decoration: InputDecoration(
            labelText: 'Photo Caption or Title',
            hintText: 'e.g. Beautiful sanctuary moment',
            hintStyle: const TextStyle(fontSize: 11),
            isDense: true,
            prefixIcon: const Icon(Icons.title, size: 16),
            border: OutlineInputBorder(borderRadius: .circular(10)),
          ),
        ),
      ],
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('attach_uploaded_photo_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: .circular(10)),
          ),
          onPressed: _uploadedDataUri != null ? _submitUploadedPhoto : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text(
            'Attach Photo to Reflection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}
