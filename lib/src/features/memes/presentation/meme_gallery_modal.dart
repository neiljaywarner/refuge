import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../../core/widgets/calm_media_image.dart';
import '../../profile/data/avatar_upload_service.dart';
import '../../profile/domain/avatar_models.dart';
import '../../profile/presentation/belong_image_crop_page.dart';
import '../domain/calm_meme.dart';
import 'giphy_search_panel.dart';

/// Opens the modal bottom sheet allowing members to select an unhurried, calm-tech meme,
/// search GIFs, attach a custom GIF or image URL, or upload/capture a photo.
void showMemeGalleryModal(BuildContext context, {required ValueChanged<CalmMeme> onSelectedMeme}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: .vertical(top: .circular(20.0))),
    builder: (ctx) =>
        SystemBottomInset(child: _MemeGalleryModalContent(onSelectedMeme: onSelectedMeme)),
  );
}

class _MemeGalleryModalContent extends ConsumerStatefulWidget {
  final ValueChanged<CalmMeme> onSelectedMeme;

  const _MemeGalleryModalContent({required this.onSelectedMeme});

  @override
  ConsumerState<_MemeGalleryModalContent> createState() => _MemeGalleryModalContentState();
}

class _MemeGalleryModalContentState extends ConsumerState<_MemeGalleryModalContent> {
  int _activeTabIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _uploadCaptionController = TextEditingController();

  Uint8List? _uploadedBytes;
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

  void _applyPreset({
    required String title,
    required String subtitle,
    required String url,
    required String tag,
  }) {
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

    final meme = CalmMeme(
      title: caption,
      icon: '🖼️',
      subtitle: 'Member Shared Meme / GIF',
      tag: 'Memes',
      body: caption,
      imageUrl: url.isNotEmpty ? url : null,
    );

    widget.onSelectedMeme(meme);
    Navigator.pop(context);
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
        _uploadedBytes = bytes;
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

    final meme = CalmMeme(
      title: caption,
      icon: '📷',
      subtitle: 'Member Uploaded Photo',
      tag: 'Photos',
      body: caption,
      imageUrl: _uploadedDataUri,
    );

    widget.onSelectedMeme(meme);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: .only(
      left: 16.0,
      right: 16.0,
      top: 16.0,
      bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
    ),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            const Text(
              '🖼️ Autism & Faith Meme Gallery',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              key: const Key('meme_gallery_close_button'),
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Text(
          'Wholesome, unhurried, relatable neurodivergent Christian humor (Belong on the Spectrum).',
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 12),
        // Tab Switcher (Curated, Custom URL, Upload / Camera, Giphy search)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              key: const Key('tab_curated_memes'),
              label: const Text('Curated Calm Memes', style: TextStyle(fontSize: 12)),
              selected: _activeTabIndex == 0,
              onSelected: (selected) {
                if (selected) setState(() => _activeTabIndex = 0);
              },
            ),
            ChoiceChip(
              key: const Key('tab_custom_meme'),
              label: const Text('Attach Custom GIF / URL', style: TextStyle(fontSize: 12)),
              selected: _activeTabIndex == 1,
              onSelected: (selected) {
                if (selected) setState(() => _activeTabIndex = 1);
              },
            ),
            ChoiceChip(
              key: const Key('tab_upload_photo'),
              label: const Text('Upload Photo / Camera', style: TextStyle(fontSize: 12)),
              selected: _activeTabIndex == 2,
              onSelected: (selected) {
                if (selected) setState(() => _activeTabIndex = 2);
              },
            ),
            ChoiceChip(
              key: const Key('tab_giphy_search'),
              label: const Text('Search GIFs', style: TextStyle(fontSize: 12)),
              selected: _activeTabIndex == 3,
              onSelected: (selected) {
                if (selected) setState(() => _activeTabIndex = 3);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          child: switch (_activeTabIndex) {
            0 => _buildCuratedList(),
            1 => _buildCustomMemeForm(),
            2 => _buildUploadPhotoForm(),
            _ => GiphySearchPanel(
              onSelected: (meme) {
                widget.onSelectedMeme(meme);
                Navigator.pop(context);
              },
            ),
          },
        ),
      ],
    ),
  );

  Widget _buildCuratedList() => ListView.separated(
    shrinkWrap: true,
    itemCount: kCuratedCalmMemes.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, i) {
      final m = kCuratedCalmMemes[i];
      return InkWell(
        onTap: () {
          widget.onSelectedMeme(m);
          Navigator.pop(context);
        },
        borderRadius: .circular(12.0),
        child: Container(
          padding: const .all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
            borderRadius: .circular(12.0),
            color: Colors.amber.withValues(alpha: 0.08),
          ),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              if (m.imageUrl != null)
                ClipRRect(
                  borderRadius: .circular(8.0),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CalmMediaImage(
                      imageUrl: m.imageUrl!,
                      fit: BoxFit.cover,
                      fallbackWidget: Center(
                        child: Text(m.icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                )
              else
                Text(m.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      m.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(m.body, style: const TextStyle(fontSize: 11, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildCustomMemeForm() => Column(
    mainAxisSize: .min,
    children: [
      Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              // Sensory Safety Notice
              Container(
                padding: const .all(10.0),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: .circular(8.0),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belong Calm Policy: Wholesome, sensory-safe memes & GIFs. Avoid flashing strobe animations out of love for sensitive members.',
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // URL Input
              TextField(
                key: const Key('meme_url_input'),
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Image or GIF URL',
                  hintText: 'https://.../wholesome_meme.gif',
                  hintStyle: const TextStyle(fontSize: 11),
                  isDense: true,
                  prefixIcon: const Icon(Icons.link, size: 16),
                  border: OutlineInputBorder(borderRadius: .circular(10.0)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              // Caption Input
              TextField(
                key: const Key('meme_caption_input'),
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Meme Title or Caption',
                  hintText: 'e.g. When the sanctuary lights are just right 🕯️',
                  hintStyle: const TextStyle(fontSize: 11),
                  isDense: true,
                  prefixIcon: const Icon(Icons.title, size: 16),
                  border: OutlineInputBorder(borderRadius: .circular(10.0)),
                ),
              ),
              const SizedBox(height: 10),
              // Presets
              const Text(
                'Or pick a quick calm preset:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    key: const Key('preset_elijah'),
                    label: const Text('🍞 Elijah Rest & Nap', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyPreset(
                      title: 'Elijah Under the Broom Tree (Snack & Nap)',
                      subtitle: '1 Kings 19:5 — Divine Sensory Prescription',
                      url: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
                      tag: 'Burnout & Recovery',
                    ),
                  ),
                  ActionChip(
                    key: const Key('preset_special_interest'),
                    label: const Text(
                      '🧩 Special Interest Deep Dive',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _applyPreset(
                      title: 'Autistic Deep-Dive PowerPoint Mode',
                      subtitle: 'Special Interests as Divine Design',
                      url: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600',
                      tag: 'Special Interests',
                    ),
                  ),
                  ActionChip(
                    key: const Key('preset_quiet_waters'),
                    label: const Text(
                      '🌊 Quiet Waters & Stillness',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _applyPreset(
                      title: 'He Leads Me Beside Quiet Waters',
                      subtitle: 'Psalm 23 — Low Stimulus Sanctuary',
                      url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
                      tag: 'Calm Sanctuary',
                    ),
                  ),
                ],
              ),
              if (_urlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('custom_meme_preview'),
                  padding: const .all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.shade700),
                    borderRadius: .circular(10.0),
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
                        borderRadius: .circular(8.0),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: CalmMediaImage(
                            imageUrl: _urlController.text.trim(),
                            fit: BoxFit.cover,
                            fallbackWidget: Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Row(
                                  mainAxisSize: .min,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Image preview unavailable (URL will still be attached)',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('attach_custom_meme_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: .circular(10.0)),
          ),
          onPressed: _submitCustomMeme,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text(
            'Attach Meme / GIF to Reflection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );

  Widget _buildUploadPhotoForm() => Column(
    mainAxisSize: .min,
    children: [
      Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              // Sensory & Privacy Safety Notice
              Container(
                padding: const .all(10.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: .circular(8.0),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select or take a peaceful photo to share with the Belong fellowship. Zero external storage permissions required.',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Permission Denied Warning Banner
              if (_permissionDeniedMessage != null) ...[
                Container(
                  key: const Key('meme_permission_denied_banner'),
                  padding: const .all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: .circular(8.0),
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

              // Action Buttons: Camera and Gallery
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('meme_upload_camera_button'),
                      style: OutlinedButton.styleFrom(
                        padding: const .symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: .circular(10.0)),
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
                        shape: RoundedRectangleBorder(borderRadius: .circular(10.0)),
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
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                ),
              ],

              // Preview of Selected / Uploaded Photo
              if (_uploadedDataUri != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('uploaded_photo_preview'),
                  padding: const .all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.shade700),
                    borderRadius: .circular(10.0),
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
                              setState(() {
                                _uploadedBytes = null;
                                _uploadedDataUri = null;
                              });
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
                        borderRadius: .circular(8.0),
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
                // Caption Input
                TextField(
                  key: const Key('meme_upload_caption_input'),
                  controller: _uploadCaptionController,
                  decoration: InputDecoration(
                    labelText: 'Photo Caption or Title',
                    hintText: 'e.g. Beautiful sanctuary moment 🕯️',
                    hintStyle: const TextStyle(fontSize: 11),
                    isDense: true,
                    prefixIcon: const Icon(Icons.title, size: 16),
                    border: OutlineInputBorder(borderRadius: .circular(10.0)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('attach_uploaded_photo_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: .circular(10.0)),
          ),
          onPressed: _uploadedDataUri != null ? _submitUploadedPhoto : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text(
            'Attach Photo to Reflection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}
