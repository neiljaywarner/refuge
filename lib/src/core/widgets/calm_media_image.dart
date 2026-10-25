import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Sensory-safe, resilient image widget supporting network URLs (HTTP/HTTPS),
/// inline base64 data URIs (`data:image/...;base64,...`), and asset paths.
class CalmMediaImage extends StatelessWidget {
  const CalmMediaImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.fallbackWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? fallbackWidget;

  Widget _buildFallback(BuildContext context) {
    if (fallbackWidget != null) return fallbackWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.amber.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
    );
  }

  @visibleForTesting
  static Widget buildLoadingProgress({
    required BuildContext context,
    required Widget child,
    ImageChunkEvent? loadingProgress,
    double? width,
    double? height,
  }) {
    if (loadingProgress == null) return child;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Colors.amber.withValues(alpha: 0.05),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();

    // 1. Base64 Data URI
    if (trimmed.startsWith('data:image/')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64String = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
          errorBuilder: (_, __, ___) => _buildFallback(context),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    }

    // 2. Direct Network URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        loadingBuilder: (context, child, loadingProgress) => buildLoadingProgress(
          context: context,
          child: child,
          loadingProgress: loadingProgress,
          width: width,
          height: height,
        ),
        errorBuilder: (_, __, ___) => _buildFallback(context),
      );
    }

    // 3. Asset Image
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, __, ___) => _buildFallback(context),
      );
    }

    // Fallback if URL format unrecognized
    return _buildFallback(context);
  }
}
