import 'package:flutter/material.dart';

import '../../../core/widgets/calm_media_image.dart';

/// Feed image for a reflection post. Uses [CalmMediaImage] so data-URI uploads render
/// on web, and hides the attachment chrome when the URL cannot be loaded (#695).
class ReflectionPostMedia extends StatefulWidget {
  const ReflectionPostMedia({
    super.key,
    required this.postId,
    required this.imageUrl,
    required this.isMeme,
    required this.isContrast,
    this.semanticLabel,
  });

  final String postId;
  final String imageUrl;
  final bool isMeme;
  final bool isContrast;
  final String? semanticLabel;

  /// True when the client can attempt to decode or fetch this attachment.
  @visibleForTesting
  static bool isRenderableUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image/') ||
        trimmed.startsWith('assets/');
  }

  @override
  State<ReflectionPostMedia> createState() => _ReflectionPostMediaState();
}

class _ReflectionPostMediaState extends State<ReflectionPostMedia> {
  var _loadFailed = false;

  void _markFailed() {
    if (!_loadFailed && mounted) {
      setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        key: Key('post_meme_image_${widget.postId}'),
        constraints: const BoxConstraints(maxHeight: 280),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: widget.isMeme
                ? Colors.amber.shade300
                : (widget.isContrast ? Colors.white70 : Colors.grey.shade300),
          ),
        ),
        child: CalmMediaImage(
          imageUrl: widget.imageUrl,
          fit: widget.isMeme ? BoxFit.cover : BoxFit.contain,
          semanticLabel: widget.semanticLabel ?? 'Community reflection image',
          fallbackWidget: _MediaLoadFailureNotifier(onFailed: _markFailed),
        ),
      ),
    );
  }
}

class _MediaLoadFailureNotifier extends StatefulWidget {
  const _MediaLoadFailureNotifier({required this.onFailed});

  final VoidCallback onFailed;

  @override
  State<_MediaLoadFailureNotifier> createState() => _MediaLoadFailureNotifierState();
}

class _MediaLoadFailureNotifierState extends State<_MediaLoadFailureNotifier> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFailed());
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
