import 'package:flutter/material.dart';

import '../../../core/presentation/coming_soon_view.dart';

/// Placeholder for Actually Autistic Events (Issue #28 / #689).
///
/// The Spaces directory marks this item **Coming Soon** until live event data
/// and RSVP sync ship in v1.1.0 (GitHub epic #28).
class ActuallyAutisticEventsView extends StatelessWidget {
  const ActuallyAutisticEventsView({super.key, this.onBackToSpaces});

  final VoidCallback? onBackToSpaces;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actually Autistic Events'),
        leading: onBackToSpaces != null
            ? IconButton(
                key: const Key('events-back-button'),
                tooltip: 'Back to Spaces',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToSpaces,
              )
            : null,
      ),
      body: ComingSoonView(
        title: 'Actually Autistic Events',
        emoji: '🗓️',
        description: 'Upcoming sensory-friendly meetups & gatherings',
        trackedIssueNumber: 28,
        onBackToFeed: onBackToSpaces,
      ),
    );
  }
}
