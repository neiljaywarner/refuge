import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../storage/data/storage_repository.dart';
import '../data/feature_voting_repository.dart';
import '../domain/feedback_and_voting_models.dart';
import 'feedback_drawing_canvas.dart';

/// State notifier managing community feature votes via the pluggable
/// [FeatureVotingRepository] (`InMemory`, `Serverpod`, `Appwrite`, or `Firebase`).
class FeatureVotingNotifier extends Notifier<List<VotableFeatureItem>> {
  StreamSubscription<List<VotableFeatureItem>>? _subscription;

  @override
  List<VotableFeatureItem> build() {
    final repo = ref.watch(featureVotingRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.watchFeatures().listen((updatedList) {
      final currentMap = {for (final item in state) item.id: item};
      state = [
        for (final remote in updatedList)
          if (currentMap.containsKey(remote.id))
            remote.copyWith(userVoted: currentMap[remote.id]!.userVoted)
          else
            remote,
      ];
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return repo.loadInitialFeatures();
  }

  void toggleVote(String featureId) {
    final repo = ref.read(featureVotingRepositoryProvider);
    state = repo.toggleVote(state, featureId);
  }

  void proposeFeature({
    required String title,
    required String description,
  }) {
    final repo = ref.read(featureVotingRepositoryProvider);
    state = repo.proposeFeature(
      state,
      title: title,
      description: description,
    );
  }

  Future<void> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  }) {
    final repo = ref.read(featureVotingRepositoryProvider);
    return repo.submitFeedback(
      sentiment: sentiment,
      message: message,
      rating: rating,
      contactEmail: contactEmail,
      attachmentUrl: attachmentUrl,
      screenshotAttachment: screenshotAttachment,
    );
  }
}

/// Provider for the Belong Feature Voting Board.
final featureVotingProvider =
    NotifierProvider<FeatureVotingNotifier, List<VotableFeatureItem>>(
      FeatureVotingNotifier.new,
    );

/// Clean, neurodivergent-affirming modal sheet combining:
/// 1. **Feature Voting & WIP Roadmap** (so members testing the preview tonight
///    can see what is actively in progress before Oct 31 and upvote priorities).
/// 2. **Literal 3-Intent Feedback Funnel ("Private Feedback, Public Praise")**
///    evaluated in ADR-0007 (`docs/adr/0007-neurodivergent-first-ux-and-feedback-evaluation.md`).
class BelongFeedbackAndVotingSheet extends HookConsumerWidget {
  const BelongFeedbackAndVotingSheet({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        top: false,
        bottom: true,
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: BelongFeedbackAndVotingSheet(initialTabIndex: initialTabIndex),
        ),
      ),
    );
  }

  static String starLiteralDescription(int stars) {
    return switch (stars) {
      5 => '5 ★ · Love it! Works great',
      4 => '4 ★ · Good experience',
      3 => "3 ★ · It's okay, could be better",
      2 => '2 ★ · Frustrating / Needs work',
      _ => '1 ★ · Broken / Very confusing',
    };
  }

  static FeedbackSentiment sentimentForStars(int stars) {
    if (stars >= 4) return FeedbackSentiment.happy;
    if (stars == 3) return FeedbackSentiment.neutral;
    return FeedbackSentiment.sad;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(
      initialLength: 2,
      initialIndex: initialTabIndex,
    );
    final selectedSentiment = useState<FeedbackSentiment>(
      FeedbackSentiment.happy,
    );
    final selectedStarRating = useState<int>(5);
    final feedbackController = useTextEditingController();
    final contactController = useTextEditingController();
    final drawingAttachment = useState<Uint8List?>(null);
    final isSubmitting = useState<bool>(false);
    final submittedMessage = useState<String?>(null);

    final features = ref.watch(featureVotingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final listPadding = EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Icon(Icons.how_to_vote_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belong Roadmap & Feedback',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '1-tap feature voting + literal, low-pressure feedback',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              key: Key('tab_feature_voting'),
              icon: Icon(Icons.thumb_up_alt_outlined, size: 18),
              text: 'Vote on Features (WIP)',
            ),
            Tab(
              key: Key('tab_private_feedback'),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
              text: 'Share Feedback',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // TAB 1: Feature Voting & Active WIP Board
              ListView(
                padding: listPadding,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap the thumb to upvote! Features with the most community support are built first.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in features)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: item.userVoted
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: item.userVoted ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.stage ==
                                              FeatureStage.workInProgress
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.15,
                                            )
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.stage.badgeLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: item.stage ==
                                                FeatureStage.workInProgress
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: item.userVoted
                                      ? 'Remove your vote'
                                      : (item.votes == 0
                                          ? 'Be the first to vote'
                                          : 'Vote for this feature'),
                                  child: OutlinedButton.icon(
                                    key: Key('vote_button_${item.id}'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: item.userVoted
                                          ? colorScheme.primaryContainer
                                          : null,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      ref
                                          .read(featureVotingProvider.notifier)
                                          .toggleVote(item.id);
                                    },
                                    icon: Icon(
                                      item.userVoted
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_alt_outlined,
                                      size: 16,
                                      color: item.userVoted
                                          ? colorScheme.primary
                                          : null,
                                    ),
                                    label: Text(
                                      '${item.votes}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.userVoted
                                            ? colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // TAB 2: Industry-Standard 1-5 Star Rating + Literal 3-Intent Feedback Funnel (PWA, Web & Mobile)
              ListView(
                padding: listPadding,
                children: [
                  // 1-5 Star Rating Card ("How do you like Belong on the Spectrum?")
                  Card(
                    key: const Key('star_rating_bar'),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'How do you like Belong on the Spectrum?',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a star (1–5) or pick a category below. Every star has a clear literal meaning — works on Web, PWA, Android & iOS:',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int star = 1; star <= 5; star++)
                                IconButton(
                                  key: Key('star_rating_$star'),
                                  tooltip: starLiteralDescription(star),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    selectedStarRating.value = star;
                                    selectedSentiment.value = sentimentForStars(
                                      star,
                                    );
                                    submittedMessage.value = null;
                                  },
                                  iconSize: 32,
                                  icon: Icon(
                                    star <= selectedStarRating.value
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: star <= selectedStarRating.value
                                        ? Colors.amber.shade600
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Container(
                              key: const Key('star_rating_literal_label'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                starLiteralDescription(
                                  selectedStarRating.value,
                                ),
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sentiment Cards (Works Great / Idea / Bug)
                  for (final sentiment in FeedbackSentiment.values)
                    Card(
                      key: Key('sentiment_${sentiment.name}'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: selectedSentiment.value == sentiment
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: selectedSentiment.value == sentiment ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      color: selectedSentiment.value == sentiment
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          selectedSentiment.value = sentiment;
                          selectedStarRating.value = switch (sentiment) {
                            FeedbackSentiment.happy =>
                              selectedStarRating.value >= 4
                                  ? selectedStarRating.value
                                  : 5,
                            FeedbackSentiment.neutral => 3,
                            FeedbackSentiment.sad =>
                              selectedStarRating.value <= 2
                                  ? selectedStarRating.value
                                  : 1,
                          };
                          feedbackController.clear();
                          submittedMessage.value = null;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(
                                sentiment.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sentiment.label,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      sentiment.subtitle,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedSentiment.value == sentiment)
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Feedback Form
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSentiment.value.promptTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('feedback_message_input'),
                            controller: feedbackController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: selectedSentiment.value.promptHint,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            key: const Key('feedback_contact_input'),
                            controller: contactController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Optional name or email (if you would like a reply)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Scribble / Drawing Attachment affordance
                          if (drawingAttachment.value != null) ...[
                            Container(
                              key: const Key('attached_scribble_preview_container'),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      drawingAttachment.value!,
                                      key: const Key('attached_scribble_thumbnail'),
                                      width: 60,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Scribble Annotated Screenshot',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${drawingAttachment.value!.lengthInBytes ~/ 1024} KB attached for private triage',
                                          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('remove_scribble_attachment_button'),
                                    tooltip: 'Remove scribble',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => drawingAttachment.value = null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ] else ...[
                            OutlinedButton.icon(
                              key: const Key('open_feedback_drawing_button'),
                              onPressed: () async {
                                final result = await FeedbackDrawingDialog.show(context);
                                if (result != null && result.isNotEmpty) {
                                  drawingAttachment.value = result;
                                }
                              },
                              icon: const Icon(Icons.draw_outlined, size: 18),
                              label: const Text('Draw / Annotate on Screenshot', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (submittedMessage.value != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                submittedMessage.value!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                key: const Key('submit_feedback_button'),
                                onPressed: isSubmitting.value
                                    ? null
                                    : () async {
                                        final text = feedbackController.text.trim();
                                        if (text.isEmpty) {
                                          submittedMessage.value =
                                              'Please enter a short note above so we can read your thoughts.';
                                          return;
                                        }
                                        isSubmitting.value = true;
                                        try {
                                          final sentiment = selectedSentiment.value;
                                          final contact = contactController.text.trim();
                                          String? attachmentUrl;
                                          final attachmentBytes = drawingAttachment.value;

                                          if (attachmentBytes != null) {
                                            final storageRepo = ref.read(storageRepositoryProvider);
                                            attachmentUrl = await storageRepo.uploadFeedbackAttachment(
                                              bytes: attachmentBytes,
                                              filename: 'scribble_${DateTime.now().millisecondsSinceEpoch}.png',
                                            );
                                          }

                                          await ref
                                              .read(featureVotingProvider.notifier)
                                              .submitFeedback(
                                                sentiment: sentiment,
                                                message: text,
                                                rating: selectedStarRating.value,
                                                contactEmail:
                                                    contact.isNotEmpty ? contact : null,
                                                attachmentUrl: attachmentUrl,
                                                screenshotAttachment: attachmentBytes,
                                              );

                                          final summary =
                                              '[Belong ${selectedStarRating.value}★ · ${sentiment.label} (${sentiment.subtitle})] '
                                              '$text '
                                              '${contact.isNotEmpty ? "(From: $contact)" : ""}'
                                              '${attachmentUrl != null ? " [Attachment: $attachmentUrl]" : ""}';
                                          try {
                                            await Clipboard.setData(
                                              ClipboardData(text: summary),
                                            ).timeout(const Duration(milliseconds: 100));
                                          } catch (_) {}

                                          submittedMessage.value = sentiment.isPrivateTriage
                                              ? 'Thank you! Your note was securely routed to our private triage queue (belong_feedback) so your privacy is 100% protected.'
                                              : 'Thank you for your encouragement! Your praise was recorded and shared with our organizers.';
                                          feedbackController.clear();
                                          drawingAttachment.value = null;
                                        } catch (e) {
                                          submittedMessage.value = 'Could not submit feedback: $e';
                                        } finally {
                                          isSubmitting.value = false;
                                        }
                                      },
                                icon: isSubmitting.value
                                    ? const Icon(Icons.hourglass_empty_rounded, size: 18)
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  selectedSentiment.value.isPrivateTriage
                                      ? 'Send Private Feedback'
                                      : 'Share Praise & Encouragement',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}