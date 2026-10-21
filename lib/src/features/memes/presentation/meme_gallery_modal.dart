import 'package:flutter/material.dart';

import '../domain/calm_meme.dart';

/// Opens the modal bottom sheet allowing members to select an unhurried, calm-tech meme
/// or attach a custom GIF or image URL.
void showMemeGalleryModal(
  BuildContext context, {
  required ValueChanged<CalmMeme> onSelectedMeme,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (ctx) => _MemeGalleryModalContent(onSelectedMeme: onSelectedMeme),
  );
}

class _MemeGalleryModalContent extends StatefulWidget {
  final ValueChanged<CalmMeme> onSelectedMeme;

  const _MemeGalleryModalContent({required this.onSelectedMeme});

  @override
  State<_MemeGalleryModalContent> createState() => _MemeGalleryModalContentState();
}

class _MemeGalleryModalContentState extends State<_MemeGalleryModalContent> {
  int _activeTabIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          // Tab Switcher
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  key: const Key('tab_curated_memes'),
                  label: const Center(
                    child: Text('Curated Calm Memes', style: TextStyle(fontSize: 12)),
                  ),
                  selected: _activeTabIndex == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _activeTabIndex = 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  key: const Key('tab_custom_meme'),
                  label: const Center(
                    child: Text('Attach Custom GIF / URL', style: TextStyle(fontSize: 12)),
                  ),
                  selected: _activeTabIndex == 1,
                  onSelected: (selected) {
                    if (selected) setState(() => _activeTabIndex = 1);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _activeTabIndex == 0 ? _buildCuratedList() : _buildCustomMemeForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedList() {
    return ListView.separated(
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
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.amber.withValues(alpha: 0.08),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.amber.withValues(alpha: 0.2),
                      child: Image.network(
                        m.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
  }

  Widget _buildCustomMemeForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sensory Safety Notice
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
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
                      label: const Text('🧩 Special Interest Deep Dive', style: TextStyle(fontSize: 11)),
                      onPressed: () => _applyPreset(
                        title: 'Autistic Deep-Dive PowerPoint Mode',
                        subtitle: 'Special Interests as Divine Design',
                        url: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600',
                        tag: 'Special Interests',
                      ),
                    ),
                    ActionChip(
                      key: const Key('preset_quiet_waters'),
                      label: const Text('🌊 Quiet Waters & Stillness', style: TextStyle(fontSize: 11)),
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
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.shade700),
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.amber.withValues(alpha: 0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview Attached Meme / GIF:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: Image.network(
                              _urlController.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
  }
}
