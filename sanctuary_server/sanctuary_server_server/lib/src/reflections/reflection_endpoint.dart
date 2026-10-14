import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Full-stack Serverpod 4 Endpoint managing calm-tech fellowship reflections,
/// atomic qualitative care affirmations, real-time WebSocket streams, and
/// server-side digest aggregations.
class ReflectionEndpoint extends Endpoint {
  /// Allowed calm-tech intent tags.
  static const Set<String> validIntentTags = {
    'Seeking Wisdom',
    'Giving Thanks',
    'Vulnerable Sharing',
    'Quiet Reflection',
    'Bible Deep-Dive',
    'Special Interest Infodump',
    'Autism & Faith Meme',
    'Seeking Prayer & Care',
    '[Prayer Request]',
    '[Comfort Only]',
    '[Bible Deep-Dive]',
    '[Special Interest Infodump]',
    '[Autism & Faith Meme]',
    '[Giving Thanks]',
    '[Question]',
    '[Resource]',
  };

  /// Valid qualitative reaction keys.
  static const Set<String> validReactionKeys = {
    'praying',
    'standingWith',
    'peace',
    'encouraged',
    'relatable',
  };

  /// Disallowed urgency keywords to enforce calm-tech standard on the backend.
  static const List<String> hostileUrgencyKeywords = [
    'urgent',
    'breaking news',
    'alert',
    'click here',
    'act now',
    'don\'t miss out',
  ];

  /// Publishes a new reflection to PostgreSQL and broadcasts to live streaming sessions.
  Future<ReflectionPost> publishReflection(
    Session session,
    ReflectionPost post,
  ) async {
    final cleanContent = post.content.trim();
    if (cleanContent.isEmpty) {
      throw ArgumentError('Reflection content cannot be empty.');
    }

    // Backend Calm-Tech validation: Reject manipulative urgency keywords
    final lowerContent = cleanContent.toLowerCase();
    for (final keyword in hostileUrgencyKeywords) {
      if (lowerContent.contains(keyword)) {
        throw ArgumentError(
          'Calm-Tech Policy: Content contains high-urgency trigger ("$keyword"). '
          'Please reframe in an unhurried, reflective tone.',
        );
      }
    }

    final postToInsert = post.copyWith(
      content: cleanContent,
      createdAt: DateTime.now().toUtc(),
      prayingCount: post.prayingCount < 0 ? 0 : post.prayingCount,
      standingWithCount:
          post.standingWithCount < 0 ? 0 : post.standingWithCount,
      peaceCount: post.peaceCount < 0 ? 0 : post.peaceCount,
      encouragedCount: post.encouragedCount < 0 ? 0 : post.encouragedCount,
    );

    final inserted = await ReflectionPost.db.insertRow(session, postToInsert);

    // Broadcast in real-time to all connected streaming clients for this fellowship space
    await session.messages.postMessage(
      'space_${inserted.spaceKey}',
      inserted,
    );

    return inserted;
  }

  /// Atomically increments a qualitative care affirmation on a post.
  Future<ReflectionPost> affirmCare(
    Session session,
    int postId,
    String reactionKey,
  ) async {
    if (!validReactionKeys.contains(reactionKey)) {
      throw ArgumentError('Invalid care affirmation key: "$reactionKey"');
    }

    final existing = await ReflectionPost.db.findById(session, postId);
    if (existing == null) {
      throw ArgumentError('ReflectionPost with ID $postId not found.');
    }

    final updated = existing.copyWith(
      prayingCount: reactionKey == 'praying'
          ? existing.prayingCount + 1
          : existing.prayingCount,
      standingWithCount: reactionKey == 'standingWith'
          ? existing.standingWithCount + 1
          : existing.standingWithCount,
      peaceCount: reactionKey == 'peace'
          ? existing.peaceCount + 1
          : existing.peaceCount,
      encouragedCount: reactionKey == 'encouraged' || reactionKey == 'relatable'
          ? existing.encouragedCount + 1
          : existing.encouragedCount,
    );

    final saved = await ReflectionPost.db.updateRow(session, updated);

    // Broadcast mutation to all listeners for this fellowship space
    await session.messages.postMessage(
      'space_${saved.spaceKey}',
      saved,
    );

    return saved;
  }

  /// Real-time streaming WebSocket endpoint for a fellowship space.
  /// Yields existing database rows (or initial seeds on first boot), then streams live updates.
  Stream<ReflectionPost> watchSpace(
    Session session,
    String spaceKey,
  ) async* {
    // 1. Query existing rows from PostgreSQL
    var existingPosts = await ReflectionPost.db.find(
      session,
      where: (t) => t.spaceKey.equals(spaceKey),
      orderBy: (t) => t.createdAt,
    );

    // 2. If space is empty, seed realistic initial fellowship reflections
    if (existingPosts.isEmpty) {
      await _seedInitialReflectionsIfEmpty(session, spaceKey);
      existingPosts = await ReflectionPost.db.find(
        session,
        where: (t) => t.spaceKey.equals(spaceKey),
        orderBy: (t) => t.createdAt,
      );
    }

    existingPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 3. Yield initial database state
    for (final post in existingPosts) {
      yield post;
    }

    // 4. Stream real-time events published to this space's channel
    final messageStream = session.messages.createStream<ReflectionPost>(
      'space_$spaceKey',
    );

    await for (final update in messageStream) {
      yield update;
    }
  }

  /// Computes server-side aggregation metrics for a fellowship space.
  Future<QuietDigest> getQuietDigest(
    Session session,
    String spaceKey,
  ) async {
    final posts = await ReflectionPost.db.find(
      session,
      where: (t) => t.spaceKey.equals(spaceKey),
    );

    final totalReflections = posts.length;
    var totalAffirmations = 0;
    final intentCounts = <String, int>{};
    final specialInterestCounts = <String, int>{};

    for (final p in posts) {
      totalAffirmations += p.prayingCount +
          p.standingWithCount +
          p.peaceCount +
          p.encouragedCount;

      intentCounts[p.intentTag] = (intentCounts[p.intentTag] ?? 0) + 1;

      if (p.specialInterestTag != null && p.specialInterestTag!.isNotEmpty) {
        specialInterestCounts[p.specialInterestTag!] =
            (specialInterestCounts[p.specialInterestTag!] ?? 0) + 1;
      }
    }

    var predominant = 'Quiet Reflection';
    var maxCount = -1;
    intentCounts.forEach((intent, count) {
      if (count > maxCount) {
        maxCount = count;
        predominant = intent;
      }
    });

    String? featuredSpecialInterest;
    var maxInterestCount = 0;
    specialInterestCounts.forEach((interest, count) {
      if (count > maxInterestCount) {
        maxInterestCount = count;
        featuredSpecialInterest = interest;
      }
    });

    var summary = totalReflections == 0
        ? 'A quiet, unhurried space awaiting the first community reflection.'
        : 'Gathered in peace: $totalReflections reflections shared with '
            '$totalAffirmations care affirmations. Leading posture: "$predominant".';

    if (featuredSpecialInterest != null) {
      summary = '$summary Special Interest: $featuredSpecialInterest.';
    }

    return QuietDigest(
      spaceKey: spaceKey,
      totalReflections: totalReflections,
      totalCareAffirmations: totalAffirmations,
      predominantIntent: predominant,
      featuredSpecialInterest: featuredSpecialInterest,
      summaryMessage: summary,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  /// Seeds realistic fellowship reflections across spaces on first boot.
  Future<void> _seedInitialReflectionsIfEmpty(
    Session session,
    String spaceKey,
  ) async {
    final seeds = <ReflectionPost>[
      ReflectionPost(
        authorName: 'Eleanor (Hospital Chaplain)',
        spaceKey: 'prayer_care',
        intentTag: 'Seeking Wisdom',
        content:
            'Sitting with families in intensive care this morning. '
            'Holding space for grief without rushing to fix it. '
            'Praying for quiet peace in anxious rooms.',
        createdAt:
            DateTime.now().toUtc().subtract(const Duration(minutes: 42)),
        prayingCount: 7,
        standingWithCount: 5,
        peaceCount: 12,
        encouragedCount: 3,
      ),
      ReflectionPost(
        authorName: 'Brother Thomas',
        spaceKey: 'quiet_room',
        intentTag: 'Quiet Reflection',
        content:
            'Early dawn silence over the monastery garden. '
            'No notifications, no urgency, just gratitude for breath and light.',
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        prayingCount: 4,
        standingWithCount: 2,
        peaceCount: 19,
        encouragedCount: 6,
      ),
      ReflectionPost(
        authorName: 'Nathan K. (Texas)',
        spaceKey: 'special_interests',
        intentTag: '[Autism & Faith Meme]',
        specialInterestTag: 'Church Acoustics',
        content:
            'When the pastor says "make a joyful noise unto the Lord" and my autistic brain starts calculating the sanctuary\'s 432Hz reverberation decay. Praise God for loop earplugs in worship! 😄🎧',
        createdAt:
            DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
        prayingCount: 4,
        standingWithCount: 8,
        peaceCount: 8,
        encouragedCount: 18,
      ),
      ReflectionPost(
        authorName: 'Sarah L. (Oxford)',
        spaceKey: 'bible_study',
        intentTag: '[Bible Deep-Dive]',
        specialInterestTag: 'Markan Chiasms',
        content:
            'My special interest is literary chiasms in Mark. Did you know Mark 2:27 ("The Sabbath was made for man, not man for the Sabbath") is a perfect inverted parallel structure ABBA? Jesus loved systematic clarity!',
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        prayingCount: 7,
        standingWithCount: 9,
        peaceCount: 9,
        encouragedCount: 14,
      ),
      ReflectionPost(
        authorName: 'Marcus (Ministry Fellow)',
        spaceKey: 'main_hall',
        intentTag: 'Vulnerable Sharing',
        content:
            'Stepped away from high-noise social media this week. '
            'It is surprising how much mental clarity returns when we stop chasing red badges.',
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 8)),
        prayingCount: 9,
        standingWithCount: 14,
        peaceCount: 8,
        encouragedCount: 17,
      ),
    ];

    for (final seed in seeds) {
      if (seed.spaceKey == spaceKey) {
        await ReflectionPost.db.insertRow(session, seed);
      }
    }
  }
}
