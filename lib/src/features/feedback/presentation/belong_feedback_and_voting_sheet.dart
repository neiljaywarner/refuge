import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/feature_voting_repository.dart';
import '../domain/feedback_and_voting_models.dart';

/// State notifier managing community feature votes via the pluggable
/// [FeatureVotingRepository] (`InMemory`, `Serverpod`, `Appwrite`, or `Firebase`).
class FeatureVotingNotifier extends Notifier<List<VotableFeatureItem>> {
  @override
  List<VotableFeatureItem> build() {
    final repo = ref.watch(featureVotingRepositoryProvider);
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
    String? contactEmail,
  }) {
    final repo = ref.read(featureVotingRepositoryProvider);
    return repo.submitFeedback(
      sentiment: sentiment,
      message: message,
      contactEmail: contactEmail,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(
      initialLength: 2,
      initialIndex: initialTabIndex,
    );
    final selectedSentiment = useState<FeedbackSentiment>(
      FeedbackSentiment.happy,
    );
    final feedbackController = useTextEditingController();
    final contactController = useTextEditingController();
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
                                Container(
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
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: item.stage ==
                                              FeatureStage.workInProgress
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
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

              // TAB 2: Literal 3-Intent Feedback Funnel
              ListView(
                padding: listPadding,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No 1–5 star ratings or guesswork. Pick what best matches your experience:',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                onPressed: () async {
                                  final text = feedbackController.text.trim();
                                  if (text.isEmpty) {
                                    submittedMessage.value =
                                        'Please enter a short note above so we can read your thoughts.';
                                    return;
                                  }
                                  final sentiment = selectedSentiment.value;
                                  final contact = contactController.text.trim();
                                  await ref
                                      .read(featureVotingProvider.notifier)
                                      .submitFeedback(
                                        sentiment: sentiment,
                                        message: text,
                                        contactEmail:
                                            contact.isNotEmpty ? contact : null,
                                      );
                                  final summary =
                                      '[Belong ${sentiment.label} (${sentiment.subtitle})] '
                                      '$text '
                                      '${contact.isNotEmpty ? "(From: $contact)" : ""}';
                                  await Clipboard.setData(
                                    ClipboardData(text: summary),
                                  );
                                  submittedMessage.value = sentiment.isPrivateTriage
                                      ? 'Thank you! Your note was securely routed to our private triage queue (belong_feedback) so your privacy is 100% protected.'
                                      : 'Thank you for your encouragement! Your praise was recorded and shared with our organizers.';
                                  feedbackController.clear();
                                },
                                icon: const Icon(Icons.send_rounded, size: 18),
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
