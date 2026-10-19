import 'package:flutter/material.dart';
import '../domain/sensory_event.dart';

/// Presentation view for Actually Autistic Events Calendar (Issue #28).
/// Features sensory indicators (lighting, sound, quiet room, masking policy)
/// and a 1-tap sensory RSVP button with calm visual feedback.
class ActuallyAutisticEventsView extends StatefulWidget {
  const ActuallyAutisticEventsView({
    super.key,
    this.initialEvents,
    this.onBackToSpaces,
  });

  final List<SensoryEvent>? initialEvents;
  final VoidCallback? onBackToSpaces;

  @override
  State<ActuallyAutisticEventsView> createState() => _ActuallyAutisticEventsViewState();
}

class _ActuallyAutisticEventsViewState extends State<ActuallyAutisticEventsView> {
  late List<SensoryEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.initialEvents ?? SensoryEvent.sampleEvents();
  }

  void _toggleRsvp(String eventId) {
    setState(() {
      _events = _events.map((e) {
        if (e.id == eventId) {
          final newRsvpd = !e.userRsvpd;
          return e.copyWith(
            userRsvpd: newRsvpd,
            rsvpCount: newRsvpd ? e.rsvpCount + 1 : e.rsvpCount - 1,
          );
        }
        return e;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actually Autistic Events'),
        leading: widget.onBackToSpaces != null
            ? IconButton(
                key: const Key('events-back-button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToSpaces,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Sensory Commitment Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCECE4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined, color: Color(0xFF2E6B56), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sensory-Friendly & Masking-Free',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E4638),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Every event lists lighting, sound, and quiet room details so you know what to expect before attending. Stimming and leaving early are always respected.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2C5545),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Event Cards List
          ..._events.map((event) {
            return Card(
              key: Key('event-card-${event.id}'),
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: event.userRsvpd ? const Color(0xFF2E6B56) : Colors.grey.shade200,
                  width: event.userRsvpd ? 1.5 : 1,
                ),
              ),
              color: event.userRsvpd ? const Color(0xFFFAFCFA) : const Color(0xFFFAFAFA),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Date & RSVP Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECEF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.dateDescription} · ${event.timeDescription}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        if (event.userRsvpd)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E6B56),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✅ RSVP Confirmed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      event.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 12),

                    // Sensory Specs Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SensoryBadge(
                          icon: Icons.lightbulb_outline,
                          label: event.lightingLevel,
                        ),
                        _SensoryBadge(
                          icon: Icons.volume_down_outlined,
                          label: event.soundLevel,
                        ),
                        if (event.quietRoomAvailable)
                          const _SensoryBadge(
                            icon: Icons.meeting_room_outlined,
                            label: 'Quiet Room Available',
                          ),
                        _SensoryBadge(
                          icon: Icons.favorite_outline,
                          label: event.maskingPolicy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // RSVP Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${event.rsvpCount} members attending',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        OutlinedButton.icon(
                          key: Key('rsvp-button-${event.id}'),
                          icon: Icon(
                            event.userRsvpd ? Icons.check_circle : Icons.event_available,
                            size: 16,
                            color: event.userRsvpd ? Colors.white : const Color(0xFF2E6B56),
                          ),
                          label: Text(
                            event.userRsvpd ? 'Attending (Quiet RSVP)' : 'RSVP (Sensory-Friendly)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: event.userRsvpd ? Colors.white : const Color(0xFF2E6B56),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                event.userRsvpd ? const Color(0xFF2E6B56) : Colors.transparent,
                            side: const BorderSide(color: Color(0xFF2E6B56)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _toggleRsvp(event.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SensoryBadge extends StatelessWidget {
  const _SensoryBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E6E9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2C3E50)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
