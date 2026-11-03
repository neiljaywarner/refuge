import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/widgets/calm_media_image.dart';
import '../domain/post.dart';
import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../../memes/domain/calm_meme.dart';
import '../../memes/presentation/meme_gallery_modal.dart';

/// Intent / tone tags available in the dropdown
const kToneOptions = [
  '[General Chat]',
  '[Fellowship]',
  '[Prayer Request]',
  '[Comfort Only]',
  '[Bible Deep Dive]',
  '[Special Interest]',
  '[Autism & Faith Meme]',
  '[Praise Report]',
  '[Other]',
];

/// Composes unhurried reflections using declarative Flutter Hooks for text editing controllers.
class ReflectionComposer extends HookWidget {
  final String selectedSpace;
  final Color primaryColor;
  final bool isContrast;
  final bool isImagePost;
  final bool isModal;
  final Future<PostPublishStatus> Function({
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
        ? (selectedSpace == 'memes' ? '[Autism & Faith Meme]' : '[Special Interest]')
        : (selectedSpace == 'prayer'
              ? '[Prayer Request]'
              : (selectedSpace == 'study' ? '[Bible Deep Dive]' : '[General Chat]'));

    final selectedTone = useState<String>(initialTone);
    final isComposing = useState<bool>(false);
    final controller = useTextEditingController();
    final customImageUrl = useState<String>('');
    final attachedMeme = useState<CalmMeme?>(null);
    final focusNode = useFocusNode();

    // Re-synchronize selected tone when switching spaces if still default
    useEffect(() {
      if (!isImagePost) {
        selectedTone.value = selectedSpace == 'prayer'
            ? '[Prayer Request]'
            : (selectedSpace == 'study' ? '[Bible Deep Dive]' : '[General Chat]');
      }
      return null;
    }, [selectedSpace]);

    Future<void> handlePublish() async {
      final text = controller.text.trim();
      final hasImage = customImageUrl.value.isNotEmpty || attachedMeme.value != null;

      if (text.isEmpty && !hasImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a thoughtful reflection or attach an image.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      isComposing.value = true;
      try {
        final result = await onSubmit(
          content: text,
          toneTag: selectedTone.value,
          imageUrl: customImageUrl.value.isNotEmpty
              ? customImageUrl.value
              : attachedMeme.value?.imageUrl,
        );

        if (context.mounted) {
          switch (result) {
            case PostPublishStatus.success:
              controller.clear();
              customImageUrl.value = '';
              attachedMeme.value = null;
              focusNode.unfocus();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Peacefully shared to ${getBelongSpaceInfo(selectedSpace).title}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (isModal) Navigator.of(context).pop();
            case PostPublishStatus.emptyContent:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a reflection before publishing.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            case PostPublishStatus.banned:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account cannot currently post to the community.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            case PostPublishStatus.unverifiedEmail:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please verify your email address to post reflections.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            case PostPublishStatus.rateLimited:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Taking a calm breath. Please wait a moment before posting again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            case PostPublishStatus.serverError:
            case PostPublishStatus.networkError:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to reach Sanctuary servers. Please try again in a moment.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        }
      } finally {
        isComposing.value = false;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isContrast
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF30363D) : Colors.black12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Intent / Tone:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF30363D) : Colors.black12,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTone.value,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                      items: kToneOptions
                          .map(
                            (tone) => DropdownMenuItem(
                              value: tone,
                              child: Text(tone),
                            ),
                          )
                          .toList(),
                      onChanged: (newTone) {
                        if (newTone != null) selectedTone.value = newTone;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: isModal ? 6 : 3,
            minLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Share an unhurried thought, prayer request, or special interest...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
          if (attachedMeme.value != null || customImageUrl.value.isNotEmpty) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    customImageUrl.value.isNotEmpty
                        ? customImageUrl.value
                        : attachedMeme.value!.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: const Text('🖼️ [Image Attached]', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () {
                      customImageUrl.value = '';
                      attachedMeme.value = null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Attach sensory-friendly meme or image',
                icon: const Icon(Icons.image_outlined, size: 20),
                onPressed: () async {
                  final picked = await showModalBottomSheet<CalmMeme>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => const MemeGalleryModal(),
                  );
                  if (picked != null) {
                    attachedMeme.value = picked;
                    if (selectedTone.value == '[Prayer Request]' ||
                        selectedTone.value == '[General Chat]') {
                      selectedTone.value = '[Autism & Faith Meme]';
                    }
                  }
                },
              ),
              ElevatedButton.icon(
                key: const Key('post_publish_button'),
                icon: isComposing.value
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isComposing.value ? 'Sharing...' : 'Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: isComposing.value ? null : handlePublish,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
