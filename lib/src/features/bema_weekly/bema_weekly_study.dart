import '../reflections/domain/post.dart';

/// The episode the weekly BEMA group is discussing.
///
/// Next week: add a `bemaEpisodeNNN` value below, then point
/// [currentBemaWeeklyStudy] at it. The feed, the This Week card, and the
/// discussion post all read that one value. The gathering line is
/// [BemaWeeklyStudy.gatheringLabel] on the same value.
///
/// Links are the ones published on the episode page. Episode 183 does not
/// publish a separate show-notes URL or a presentation PDF (episode 182 does).
/// Show notes for 183 are the episode page itself. Its Apple Podcasts control
/// opens the show, not an episode id. The RSS item has no episode Apple URL.
class const BemaWeeklyStudy({
  required final int episodeNumber,
  required final String title,
  required final String subtitle,
  required final String publishedLabel,
  required final String durationLabel,
  required final String gatheringLabel,
  required final String listenUrl,
  required final String showNotesUrl,
  required final String transcriptUrl,
  required final String discussionVideoUrl,
  final String? presentationUrl,
  final String? applePodcastsUrl,
  required final int followsEpisodeNumber,
  required final String followsTitle,
  required final String followsUrl,
  required final String callRoom,
  required final String spaceKey,
  required final List<String> standardQuestions,
  required final List<String> episodeQuestions,
}) {
  /// Stable discussion-post id. A new episode number is a new post.
  String get discussionPostId => 'bema-week-$episodeNumber';

  List<String> get questions => [...standardQuestions, ...episodeQuestions];
}

/// Change this line for next week's episode.
const BemaWeeklyStudy currentBemaWeeklyStudy = bemaEpisode183;

/// Every episode the weekly post can still link, including past weeks.
const List<BemaWeeklyStudy> kBemaWeeklyStudies = [bemaEpisode183];

/// Study record for a seeded discussion post, matched by episode number.
BemaWeeklyStudy? weeklyStudyForPostId(String id) {
  if (!isWeeklyDiscussionPostId(id)) return null;
  final raw = id.substring('bema-week-'.length);
  final number = int.tryParse(raw);
  if (number == null) return null;
  for (final study in kBemaWeeklyStudies) {
    if (study.episodeNumber == number) return study;
  }
  return null;
}

/// BEMA 183, verified 22 Nov 2026 from https://www.bemadiscipleship.com/183.
///
/// Standard questions are from the group-start guide:
/// https://bemadiscipleship.s3.us-east-2.amazonaws.com/How+to+Start+a+BEMA+Discussion+Group.pdf
const BemaWeeklyStudy bemaEpisode183 = BemaWeeklyStudy(
  episodeNumber: 183,
  title: 'Revelation — Seals from Scripture',
  subtitle: 'The Return of the Horses',
  publishedLabel: '27 August 2020',
  durationLabel: '21 min',
  gatheringLabel: 'Sunday — time TBD',
  listenUrl: 'https://www.bemadiscipleship.com/183',
  showNotesUrl: 'https://www.bemadiscipleship.com/183',
  transcriptUrl: 'https://docs.google.com/document/d/e/2PACX-1vSGLBFW5q1hmjuBRFR2D4SkPi5tTyHoHMaHJR9AoTyFgm_FRIIxrtvfLuXTgNFnhH2c_l92fVSYXR4o/pub',
  discussionVideoUrl: 'https://www.youtube.com/watch?v=q4RSOhwDV4M',
  applePodcastsUrl: 'https://podcasts.apple.com/us/podcast/the-bema-podcast/id1148115183',
  followsEpisodeNumber: 182,
  followsTitle: 'Revelation — The Throne Room',
  followsUrl: 'https://www.bemadiscipleship.com/182',
  callRoom: 'bema-weekly',
  spaceKey: 'study',
  standardQuestions: [
    'What are the problems I see in this story? What sticks out to me?',
    'Is there anything that radically changes by viewing this with eastern eyes?',
    'What new truth did I learn in this podcast?',
  ],
  episodeQuestions: [
    'The episode looks at the context behind the seals of the scroll, and the apocalyptic chaos that follows when they are opened. What stood out as the horses returned?',
    'This conversation follows the throne room in episode 182. How does opening the seals continue what John is shown there?',
  ],
);

/// True for the seeded weekly discussion rows, including earlier episodes.
bool isWeeklyDiscussionPostId(String id) => id.startsWith('bema-week-');

/// Body of the auto-posted Weekly Study reflection.
String weeklyDiscussionBody(BemaWeeklyStudy study) {
  final buffer = StringBuffer()
    ..writeln('BEMA ${study.episodeNumber} — ${study.title}')
    ..writeln(study.subtitle)
    ..writeln()
    ..writeln('Gathering: ${study.gatheringLabel}')
    ..writeln('Follows episode ${study.followsEpisodeNumber}, ${study.followsTitle}.')
    ..writeln('Listen: ${study.listenUrl}')
    ..writeln('Show notes: ${study.showNotesUrl}')
    ..writeln('Transcript: ${study.transcriptUrl}')
    ..writeln('Discussion video: ${study.discussionVideoUrl}');
  final apple = study.applePodcastsUrl;
  if (apple != null && apple.isNotEmpty) {
    buffer.writeln('Apple Podcasts: $apple');
  }
  final presentation = study.presentationUrl;
  if (presentation != null && presentation.isNotEmpty) {
    buffer.writeln('Presentation: $presentation');
  }
  buffer
    ..writeln()
    ..writeln('Discussion questions');
  for (var i = 0; i < study.questions.length; i++) {
    buffer.writeln('${i + 1}. ${study.questions[i]}');
  }
  return buffer.toString().trimRight();
}

/// The current week's discussion post. Same id on every device, so replies
/// attach to one thread. [isDemo] stays false so a signed-in feed keeps it.
Post weeklyDiscussionPost(BemaWeeklyStudy study) => Post(
  id: study.discussionPostId,
  authorName: 'Weekly Study',
  spaceKey: study.spaceKey,
  toneTag: '[Question]',
  content: weeklyDiscussionBody(study),
  timestamp: DateTime.utc(2026, 11, 22, 15),
  reactions: const {},
  isDemo: false,
);
