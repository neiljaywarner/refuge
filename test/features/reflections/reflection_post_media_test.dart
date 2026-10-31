import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_post_media.dart';

void main() {
  group('ReflectionPostMedia.isRenderableUrl', () {
    test('accepts https and data URIs', () {
      expect(
        ReflectionPostMedia.isRenderableUrl('https://example.com/meme.png'),
        isTrue,
      );
      expect(
        ReflectionPostMedia.isRenderableUrl('data:image/png;base64,abc'),
        isTrue,
      );
    });

    test('rejects empty or unsupported schemes', () {
      expect(ReflectionPostMedia.isRenderableUrl(null), isFalse);
      expect(ReflectionPostMedia.isRenderableUrl('   '), isFalse);
      expect(ReflectionPostMedia.isRenderableUrl('ftp://example.com/x'), isFalse);
    });
  });
}
