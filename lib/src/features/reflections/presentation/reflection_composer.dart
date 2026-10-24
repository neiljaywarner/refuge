import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/widgets/calm_media_image.dart';
import '../../fellowship_spaces/domain/fellowship_space.dart';
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
  final bool isImagePost;
  final bool isModal;
  final Future<void> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
    String? imageUrl,
  })
  onSubmit;

  const ReflectionComposer({
    super.key,
    required this.selectedSpace,
    required this.primaryColor,
    required this.isContrast,
    this.isImagePost = false,
    this.isModal = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final initialTone = isImagePost
        ? (selectedSpace == 'memes'
              ? '[Autism & Faith Meme]'
              : '[Special Interest]')
        : (selectedSpace == 'memes'
              ? '[Autism & Faith Meme]'
              : '[Prayer Request]');
    final selectedTone = useState(initialTone);
    final attachedMeme = useState<CalmMeme?>(null);
    final isExpanded = useState(isModal || isImagePost);
    final contentController = useTextEditingController();
    final specialInterestController = useTextEditingController();
    final imageUrlController = useTextEditingController();
    final altTextController = useTextEditingController();
    final customImageUrl = useState<String>('');

    useEffect(() {
      void listener() {
        customImageUrl.value = imageUrlController.text.trim();
      }

      imageUrlController.addListener(listener);
      return () => imageUrlController.removeListener(listener);
    }, [imageUrlController]);

    void handleSelectMeme(CalmMeme meme) {
      attachedMeme.value = meme;
      if (meme.imageUrl != null) {
        imageUrlController.text = meme.imageUrl!;
      }
      selectedTone.value = '[Autism & Faith Meme]';
      specialInterestController.text = meme.tag;
      if (altTextController.text.trim().isEmpty) {
        altTextController.text = meme.title;
      }
      if (contentController.text.trim().isEmpty) {
        contentController.text = '${meme.icon} "${meme.title}"\n\n${meme.body}';
      }
    }

    Future<void> handlePublish() async {
      var text = contentController.text.trim();
      final effectiveImageUrl = customImageUrl.value.isNotEmpty
          ? customImageUrl.value
          : attachedMeme.value?.imageUrl;

      // Bug #321 fix: Check if text is empty with zero user feedback
      if (text.isEmpty) {
        if (effectiveImageUrl != null && effectiveImageUrl.isNotEmpty) {
          text = 'Shared an image reflection';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: const Key('empty_reflection_warning_snackbar'),
              content: const Text(
                'Please write a thought or reflection before publishing.',
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      final altText = altTextController.text.trim();
      if (altText.isNotEmpty) {
        text = '$text\n\n[Image Description: $altText]';
      }

      final specialInterest = specialInterestController.text.trim().isNotEmpty
          ? specialInterestController.text.trim()
          : (selectedTone.value.contains('Meme')
                ? 'Faith & Neurodiversity'
                : null);

      contentController.clear();
      specialInterestController.clear();
      imageUrlController.clear();
      altTextController.clear();
      attachedMeme.value = null;

      await onSubmit(
        content: text,
        toneTag: selectedTone.value,
        specialInterestTag: specialInterest,
        imageUrl: effectiveImageUrl,
      );

      if (!isModal) {
        isExpanded.value = false;
      }
    }

    final hasActiveImage =
        customImageUrl.value.isNotEmpty ||
        (attachedMeme.value?.imageUrl != null);

    if (!isExpanded.value) {
      return Container(
        key: const Key('reflection_composer_card'),
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isContrast ? Colors.white : Theme.of(context).dividerColor,
            width: isContrast ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                identifier: 'reflection_composer',
                child: TextField(
                  key: const Key('reflection_composer_input'),
                  controller: contentController,
                  onTap: () {
                    isExpanded.value = true;
                  },
                  onChanged: (val) {
                    if (val.trim().isNotEmpty && !isExpanded.value) {
                      isExpanded.value = true;
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Share an unhurried thought in #${kFellowshipSpaces[selectedSpace] ?? selectedSpace}...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            IconButton(
              key: const Key('composer_add_meme_compact_button'),
              tooltip: 'Add Meme / GIF',
              icon: const Icon(Icons.sentiment_very_satisfied_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                isExpanded.value = true;
                showMemeGalleryModal(
                  context,
                  onSelectedMeme: handleSelectMeme,
                );
              },
            ),
            IconButton(
              key: const Key('composer_expand_button'),
              tooltip: 'Expand',
              icon: const Icon(Icons.open_in_full_rounded, size: 16),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                isExpanded.value = true;
              },
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('reflection_composer_card'),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
      padding: const EdgeInsets.all(10.0),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                underline: const SizedBox(),
                items: kToneOptions.map((tone) {
                  return DropdownMenuItem(value: tone, child: Text(tone));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedTone.value = val;
                },
              ),
              const Spacer(),
              if (!isModal)
                IconButton(
                  key: const Key('composer_collapse_button'),
                  tooltip: 'Collapse',
                  icon: const Icon(Icons.close_fullscreen_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    isExpanded.value = false;
                  },
                ),
            ],
          ),
          if (isImagePost ||
              selectedTone.value.contains('Special Interest') ||
              selectedTone.value.contains('Meme') ||
              selectedSpace == 'special_interests' ||
              selectedSpace == 'memes') ...[
            const SizedBox(height: 6),
            TextField(
              key: const Key('special_interest_tag_input'),
              controller: specialInterestController,
              decoration: InputDecoration(
                hintText: isImagePost
                    ? 'Image Tag / Topic (e.g. Christian Memes, Scripture Art, Church Architecture)...'
                    : 'Special Interest tag (e.g. Church Acoustics, Markan Chiasms, Biblical Maps)...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ],
          if (isImagePost) ...[
            const SizedBox(height: 6),
            TextField(
              key: const Key('image_post_url_input'),
              controller: imageUrlController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded, size: 16),
                hintText: 'Paste Image URL (https://...) or tap Add Meme below',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('image_post_alt_text_input'),
              controller: altTextController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.accessibility_new_rounded,
                  size: 16,
                ),
                hintText: 'Image description / alt-text (for screen readers & sensory comfort)...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ],
          if (hasActiveImage) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('image_post_preview_container'),
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      customImageUrl.value.isNotEmpty
                          ? customImageUrl.value
                          : attachedMeme.value!.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: const Text(
                          '🖼️ [Image Attached]',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      key: const Key('remove_image_button'),
                      onTap: () {
                        imageUrlController.clear();
                        attachedMeme.value = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Semantics(
            identifier: 'reflection_composer',
            child: Tooltip(
              message: 'Share an unhurried thought',
              triggerMode: TooltipTriggerMode.manual,
              child: TextField(
                key: const Key('reflection_composer_input'),
                controller: contentController,
                maxLines: isImagePost ? 2 : 3,
                decoration: InputDecoration(
                  hintText: isImagePost
                      ? 'Add an optional caption, thought, or context for this image...'
                      : 'Share an unhurried thought, Scripture insight, or relatable reflection...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12.0),
                ),
              ),
            ),
          ),
          if (attachedMeme.value != null && !isImagePost) ...[
            Container(
              key: const Key('attached_meme_banner'),
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
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
                        child: CalmMediaImage(
                          imageUrl: attachedMeme.value!.imageUrl!,
                          fit: BoxFit.cover,
                          fallbackWidget: Center(
                            child: Text(
                              attachedMeme.value!.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      attachedMeme.value!.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: ${attachedMeme.value!.title}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isContrast
                            ? Colors.yellow
                            : Colors.amber.shade900,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('add_meme_gif_button'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: isContrast
                            ? Colors.white
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    onPressed: () => showMemeGalleryModal(
                      context,
                      onSelectedMeme: handleSelectMeme,
                    ),
                    icon: const Icon(
                      Icons.sentiment_very_satisfied_outlined,
                      size: 14,
                    ),
                    label: Text(
                      attachedMeme.value != null
                          ? 'Change Meme'
                          : 'Add Meme / GIF',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isModal)
                    TextButton.icon(
                      key: const Key('composer_collapse_bottom_button'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: () => isExpanded.value = false,
                      icon: const Icon(Icons.unfold_less_rounded, size: 14),
                      label: const Text(
                        'Collapse',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('publish_reflection_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isContrast ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: handlePublish,
                icon: Icon(
                  isImagePost
                      ? Icons.photo_library_outlined
                      : Icons.send_rounded,
                  size: 14,
                ),
                label: Text(
                  isImagePost ? 'Publish Image Post' : 'Publish Reflection',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
