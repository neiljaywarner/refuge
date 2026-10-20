import 'package:flutter/material.dart';

/// Calm Notification Bell view (Issue #27).
/// Presents unhurried, digestible notifications without high-stress red dots or urgency badges.
class CalmNotificationsView extends StatelessWidget {
  const CalmNotificationsView({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final notifications = [
      _NotificationItem(
        id: 'notif-1',
        title: 'Sensory Game Night This Friday',
        body: 'Details updated with dim lighting schedule & quiet breakout room info.',
        timeAgo: '1 hour ago',
        icon: Icons.calendar_today_outlined,
        category: 'Actually Autistic Events',
      ),
      _NotificationItem(
        id: 'notif-2',
        title: 'New Reflection in Welcome Space',
        body: 'Jordan shared: "Found this soothing lo-fi playlist for deep focus work."',
        timeAgo: '3 hours ago',
        icon: Icons.eco_outlined,
        category: 'Welcome & Introductions',
      ),
      _NotificationItem(
        id: 'notif-3',
        title: 'Calm Daily Digest Ready',
        body: '3 new discussions were posted across your joined fellowship rooms today.',
        timeAgo: 'Yesterday',
        icon: Icons.spa_outlined,
        category: 'Daily Digest',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calm Notifications'),
        leading: onBackToHome != null
            ? IconButton(
                key: const Key('notif-back-button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToHome,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCECE4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_paused_outlined, color: Color(0xFF2E6B56), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All notifications are delivered gently without intrusive sound alerts or badges.',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1E4638)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...notifications.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: const Color(0xFFFAFAFA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 18, color: const Color(0xFF2C3E50)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                item.timeAgo,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.body,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.icon,
    required this.category,
  });

  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final IconData icon;
  final String category;
}
