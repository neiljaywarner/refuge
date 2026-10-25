import 'package:flutter/foundation.dart';

/// Represents a sensory-friendly event for autistic community members (Issue #28).
@immutable
class SensoryEvent {
  const SensoryEvent({
    required this.id,
    required this.title,
    required this.dateDescription,
    required this.timeDescription,
    required this.location,
    required this.description,
    required this.lightingLevel,
    required this.soundLevel,
    required this.quietRoomAvailable,
    required this.maskingPolicy,
    this.rsvpCount = 0,
    this.userRsvpd = false,
  });

  final String id;
  final String title;
  final String dateDescription;
  final String timeDescription;
  final String location;
  final String description;

  /// Literal sensory indicators
  final String lightingLevel; // e.g., "Soft / Dimmable", "Natural"
  final String soundLevel; // e.g., "Quiet / Ambient", "Low Volume"
  final bool quietRoomAvailable;
  final String
  maskingPolicy; // e.g., "Masking-free zone / Zero social pressure"

  final int rsvpCount;
  final bool userRsvpd;

  SensoryEvent copyWith({
    String? id,
    String? title,
    String? dateDescription,
    String? timeDescription,
    String? location,
    String? description,
    String? lightingLevel,
    String? soundLevel,
    bool? quietRoomAvailable,
    String? maskingPolicy,
    int? rsvpCount,
    bool? userRsvpd,
  }) => SensoryEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    dateDescription: dateDescription ?? this.dateDescription,
    timeDescription: timeDescription ?? this.timeDescription,
    location: location ?? this.location,
    description: description ?? this.description,
    lightingLevel: lightingLevel ?? this.lightingLevel,
    soundLevel: soundLevel ?? this.soundLevel,
    quietRoomAvailable: quietRoomAvailable ?? this.quietRoomAvailable,
    maskingPolicy: maskingPolicy ?? this.maskingPolicy,
    rsvpCount: rsvpCount ?? this.rsvpCount,
    userRsvpd: userRsvpd ?? this.userRsvpd,
  );

  /// Default seed events for pre-alpha community schedule.
  static List<SensoryEvent> sampleEvents() => const [
    SensoryEvent(
      id: 'event-weekly-online',
      title: 'Actually Autistic Weekly Online Fellowship',
      dateDescription: 'Every Tuesday',
      timeDescription: '7:00 PM – 8:00 PM CDT',
      location: 'Online Zoom (Link in Pinned Space)',
      description: 'A welcoming, unhurried space for autistic adults. Cameras optional, chat-only welcome, zero masking expectations.',
      lightingLevel: 'User Controlled (Home)',
      soundLevel: 'Quiet / Turn down volume anytime',
      quietRoomAvailable: true,
      maskingPolicy: 'Come as you are · Masking-Free Zone',
      rsvpCount: 14,
      userRsvpd: false,
    ),
    SensoryEvent(
      id: 'event-board-games',
      title: 'Sensory-Friendly Board Game Night',
      dateDescription: 'Friday, Oct 24',
      timeDescription: '6:30 PM – 8:30 PM CDT',
      location: 'DFW Church Fellowship Hall (Quiet Annex)',
      description: 'Cozy board games (Wingspan, Cascadia, Azul) with dim lighting, quiet background lo-fi, and dedicated quiet recharge rooms.',
      lightingLevel: 'Soft warm lamps (Fluorescents Off)',
      soundLevel: 'Low ambient · Earplugs/Headphones encouraged',
      quietRoomAvailable: true,
      maskingPolicy: 'Stimming welcome · Leave anytime without explanation',
      rsvpCount: 9,
      userRsvpd: false,
    ),
    SensoryEvent(
      id: 'event-silent-cowork',
      title: 'Quiet Co-Working & Special Interests Hour',
      dateDescription: 'Saturday, Oct 25',
      timeDescription: '2:00 PM – 3:30 PM CDT',
      location: 'Discord Voice & Video (Muted by Default)',
      description: 'Work on your favorite hyperfixation, coding project, craft, or reading in silent supportive company.',
      lightingLevel: 'User Controlled',
      soundLevel: 'Muted microphones / Text chat only',
      quietRoomAvailable: true,
      maskingPolicy: 'Zero conversation pressure',
      rsvpCount: 18,
      userRsvpd: true,
    ),
  ];
}
