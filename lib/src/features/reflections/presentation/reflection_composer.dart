import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../memes/domain/calm_meme.dart';
import '../../memes/presentation/meme_gallery_modal.dart';

/// Intent / tone tags available in the dropdown
const kToneOptions = [
  '[Prayer Request]',
  '[Comfort Only]',
  '[Bible Deep Dive]',
  '[Special Interest]',
  '[Autism & Faith Meme]',
  '[Praise Report]',
];

/// Composes unhurried reflections using declarative Flutter Hooks for text editing controllers.
class ReflectionComposer extends HookWidget {
  final String selectedSpace;
  final Color primaryColor;
  final bool isContrast;
  final Future<void> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
  })
  onSubmit;

  const ReflectionComposer({
    super.key,
    required this.selectedSpace,
    required this.primaryColor,
    required this.isContrast,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTone = useState('[Prayer Request]');
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

      final specialInterest = specialInterestController.text.trim().isNotEmpty
          ? specialInterestController.text.trim()
          : (selectedTone.value.contains('Meme') ? 'Faith & Neurodiversity' : null);

      contentController.clear();
      specialInterestController.clear();
      attachedMeme.value = null;

      await onSubmit(
        content: text,
        toneTag: selectedTone.value,
        specialInterestTag: specialInterest,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isContrast ? Colors.white : Theme.of(context).dividerColor,
          width: isContrast ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Intent Tag: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedTone.value,
                isDense: true,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                underline: const SizedBox(),
                items: kToneOptions.map((tone) {
                  return DropdownMenuItem(value: tone, child: Text(tone));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedTone.value = val;
                },
              ),
            ],
          ),
          if (selectedTone.value.contains('Special Interest') ||
              selectedTone.value.contains('Meme') ||
              selectedSpace == 'special_interests') ...[
            const SizedBox(height: 6),
            TextField(
              controller: specialInterestController,
              decoration: InputDecoration(
                hintText:
                    'Special Interest tag (e.g. Church Acoustics, Markan Chiasms, Liturgy)...',
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
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isContrast ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                onPressed: handlePublish,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Publish Reflection',
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
