import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

void main() {
  testWidgets('non-meme photo reflections use BoxFit.contain (#696)', (tester) async {
    final post = Post(
      id: 'photo_1',
      authorName: 'Community Member',
      spaceKey: 'prayer',
      toneTag: '[Comfort Only]',
      specialInterestTag: 'Community Photo Reflection',
      content: 'Quiet moment at the library.',
      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
      timestamp: DateTime.now(),
      reactions: const {},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
  });
}
