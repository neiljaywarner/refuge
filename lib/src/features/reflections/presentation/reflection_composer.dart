import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../domain/calm_meme.dart';
import 'meme_gallery_modal.dart';

/// Unhurried reflection composer widget with tone selectors and optional calm meme/GIF picker.
class ReflectionComposer extends HookWidget {
  final String selectedSpace;
  final Color primaryColor;
  final bool isContrast;
  final Future<void> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
    String? imageUrl,
  }) onSubmit;

  const ReflectionComposer({
    super.key,
    required this.selectedSpace,
    required this.primaryColor,
    required this.isContrast,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final initialTone = selectedSpace == 'memes'
        ? '[Autism & Faith Meme]'
        : '[Prayer Request]';
    final selectedTone = useState(initialTone);
    final attachedMeme = useState<CalmMeme?>(null);
    final contentController = useTextEditingController();
    final specialInterestController = useTextEditingController();

    void handleSelectMeme(CalmMeme meme) {
      attachedMeme.value = meme;
      selectedTone.value = '[Autism & Faith Meme]';
      specialInterestController.text = meme.tag;
      if (contentController.text.trim().isEmpty) {
        contentController.text = '${meme.icon} "${meme.title}"\n\n${meme.body}';
      }
    }

    Future<void> handlePublish() async {
      final text = contentController.text.trim();
      if (text.isEmpty) return;

      await onSubmit(
        content: text,
        toneTag: selectedTone.value,
        specialInterestTag: specialInterestController.text.trim().isEmpty
            ? null
            : specialInterestController.text.trim(),
        imageUrl: attachedMeme.value?.imageUrl,
      );

      contentController.clear();
      specialInterestController.clear();
      attachedMeme.value = null;
    }

    final toneOptions = selectedSpace == 'memes'
        ? const ['[Autism & Faith Meme]', '[Special Interest]', '[Humor & Grace]']
        : const [
            '[Prayer Request]',
            '[Praise & Joy]',
            '[Comfort Only]',
            '[Question]',
            '[Bible Deep-Dive]',
            '[Special Interest]',
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isContrast
              ? Colors.white
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Intent / Tone:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isContrast ? Colors.yellow : primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTone.value,
                    isDense: true,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    items: toneOptions
                        .map((tone) => DropdownMenuItem(
                              value: tone,
                              child: Text(tone),
                            ))
                        .toList(),
                    onChanged: (newTone) {
                      if (newTone != null) selectedTone.value = newTone;
                    },
                  ),
                ),
              ),
            ],
          ),
          if (selectedTone.value.contains('Special Interest') ||
              selectedTone.value.contains('Meme') ||
              selectedSpace == 'special_interests' ||
              selectedSpace == 'memes') ...[
            const SizedBox(height: 6),
            TextField(
              controller: specialInterestController,
              decoration: InputDecoration(
                hintText:
                    'Special Interest tag (e.g. Church Acoustics, Markan Chiasms, Biblical Maps)...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            key: const Key('reflection_composer_input'),
            controller: contentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share an unhurried thought, Scripture insight, or relatable reflection...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
          ),
          const SizedBox(height: 8),
          if (attachedMeme.value != null) ...[
            Container(
              key: const Key('attached_meme_banner'),
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  if (attachedMeme.value!.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Container(
                        width: 24,
                        height: 24,
                        color: Colors.amber.withValues(alpha: 0.2),
                        child: Image.network(
                          attachedMeme.value!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Text(attachedMeme.value!.icon, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                    )
                  else
                    Text(attachedMeme.value!.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: ${attachedMeme.value!.title}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.yellow : Colors.amber.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    key: const Key('remove_attached_meme_button'),
                    onTap: () => attachedMeme.value = null,
                    child: const Icon(Icons.close, size: 14),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                key: const Key('add_meme_gif_button'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(
                    color: isContrast ? Colors.white : Theme.of(context).dividerColor,
                  ),
                ),
                onPressed: () => showMemeGalleryModal(context, onSelectedMeme: handleSelectMeme),
                icon: const Icon(Icons.sentiment_very_satisfied_outlined, size: 14),
                label: Text(
                  attachedMeme.value != null ? 'Change Meme' : 'Add Meme / GIF',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('publish_reflection_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isContrast ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: handlePublish,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Share Reflection',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
