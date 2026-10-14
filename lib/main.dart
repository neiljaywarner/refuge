import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanctuary_server_client/sanctuary_server_client.dart' as sp;

/// Visual ergonomics matching calm-tech accessibility and low-stimulation standards.
enum SensoryMode { clean, sage, charcoal, contrast }

/// Domain model representing an asynchronous reflection with tone clarification.
class Post {
  final String id;
  final String authorName;
  final String spaceKey;
  final String toneTag;
  final String? specialInterestTag;
  final String content;
  final DateTime timestamp;
  final Map<String, int> reactions;

  const Post({
    required this.id,
    required this.authorName,
    required this.spaceKey,
    required this.toneTag,
    this.specialInterestTag,
    required this.content,
    required this.timestamp,
    required this.reactions,
  });

  Post copyWith({
    String? id,
    String? authorName,
    String? spaceKey,
    String? toneTag,
    String? specialInterestTag,
    String? content,
    DateTime? timestamp,
    Map<String, int>? reactions,
  }) {
    return Post(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      spaceKey: spaceKey ?? this.spaceKey,
      toneTag: toneTag ?? this.toneTag,
      specialInterestTag: specialInterestTag ?? this.specialInterestTag,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? Map<String, int>.from(this.reactions),
    );
  }
}

/// Abstract contract decoupling the UI from local SQLite, in-memory, or Serverpod WebSockets.
abstract class PostRepository {
  Future<List<Post>> getPosts({required String spaceKey});
  Future<Post> createPost(Post post);
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  });
  Stream<List<Post>> watchPosts({required String spaceKey});
  Future<String?> getQuietDigest({required String spaceKey});
}

/// Resilient local-first implementation with asynchronous broadcast streams.
class LocalPostRepository implements PostRepository {
  final List<Post> _store = [];
  final StreamController<List<Post>> _controller =
      StreamController<List<Post>>.broadcast();

  LocalPostRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _store.addAll([
      Post(
        id: '1',
        authorName: 'David M. (UK)',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content:
            'Please pray for peace of mind this week. Transitioning to a new routine has been disorienting. Reminding myself that rest is spiritual.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        reactions: {'pray': 6, 'peace': 4},
      ),
      Post(
        id: '2',
        authorName: 'Elena R. (Colorado)',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content:
            'Heavy sensory fatigue after errands today with fluorescent glare. Just needed to share in a safe room. No advice needed, just glad this quiet space exists.',
        timestamp: now.subtract(const Duration(hours: 2)),
        reactions: {'pray': 11, 'peace': 14},
      ),
      Post(
        id: '3',
        authorName: 'Pastor Thomas (Melbourne)',
        spaceKey: 'study',
        toneTag: '[Question]',
        content:
            'In Psalm 23, David reflects on "quiet waters." How does that specific imagery ground your mental peace during hectic workdays?',
        timestamp: now.subtract(const Duration(hours: 5)),
        reactions: {'pray': 5, 'peace': 8},
      ),
      Post(
        id: '4',
        authorName: 'Nathan K. (Texas)',
        spaceKey: 'special_interests',
        toneTag: '[Autism & Faith Meme]',
        specialInterestTag: 'Church Acoustics',
        content:
            'When the pastor says "make a joyful noise unto the Lord" and my autistic brain starts calculating the sanctuary\'s 432Hz reverberation decay. Praise God for loop earplugs in worship! 😄🎧',
        timestamp: now.subtract(const Duration(minutes: 15)),
        reactions: {'pray': 4, 'peace': 8, 'relatable': 18},
      ),
      Post(
        id: '5',
        authorName: 'Sarah L. (Oxford)',
        spaceKey: 'study',
        toneTag: '[Bible Deep-Dive]',
        specialInterestTag: 'Markan Chiasms',
        content:
            'My special interest is literary chiasms in Mark. Did you know Mark 2:27 ("The Sabbath was made for man, not man for the Sabbath") is a perfect inverted parallel structure ABBA? Jesus loved systematic clarity!',
        timestamp: now.subtract(const Duration(hours: 1)),
        reactions: {'pray': 7, 'peace': 9, 'relatable': 14},
      ),
    ]);
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_store));
  }

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    return _store.where((p) => p.spaceKey == spaceKey).toList();
  }

  @override
  Future<Post> createPost(Post post) async {
    _store.insert(0, post);
    _notify();
    return post;
  }

  @override
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  }) async {
    final index = _store.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _store[index];
      final currentCount = post.reactions[reactionType] ?? 0;
      final updatedReactions = Map<String, int>.from(post.reactions);
      updatedReactions[reactionType] = currentCount + 1;
      _store[index] = post.copyWith(reactions: updatedReactions);
      _notify();
    }
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) async* {
    yield _store.where((p) => p.spaceKey == spaceKey).toList();
    yield* _controller.stream.map(
      (posts) => posts.where((p) => p.spaceKey == spaceKey).toList(),
    );
  }

  @override
  Future<String?> getQuietDigest({required String spaceKey}) async {
    final posts = _store.where((p) => p.spaceKey == spaceKey).toList();
    if (posts.isEmpty) {
      return 'A quiet, unhurried space awaiting the first community reflection.';
    }
    final totalReactions = posts.fold<int>(
      0,
      (sum, p) => sum + p.reactions.values.fold<int>(0, (a, b) => a + b),
    );
    return 'Gathered in peace • ${posts.length} reflections shared with $totalReactions care affirmations.';
  }
}

/// Serverpod-backed post repository with live WebSocket streaming and resilient offline fallback.
class ServerpodPostRepository implements PostRepository {
  final String serverUrl;
  final LocalPostRepository _fallback;
  final sp.Client _client;
  bool _isLiveConnected = false;

  bool get isLiveConnected => _isLiveConnected;

  ServerpodPostRepository({
    String? serverUrl,
    LocalPostRepository? fallback,
  })  : serverUrl = serverUrl ??
            const String.fromEnvironment(
              'SERVERPOD_URL',
              defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
            ),
        _fallback = fallback ?? LocalPostRepository(),
        _client = sp.Client(
          serverUrl ??
              const String.fromEnvironment(
                'SERVERPOD_URL',
                defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
              ),
        );

  String _mapSpaceKey(String key) {
    switch (key) {
      case 'prayer':
        return 'prayer_care';
      case 'study':
        return 'bible_study';
      case 'special_interests':
        return 'special_interests';
      case 'general':
        return 'main_hall';
      case 'announcements':
        return 'quiet_room';
      default:
        return key;
    }
  }

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    return _fallback.getPosts(spaceKey: spaceKey);
  }

  @override
  Future<Post> createPost(Post post) async {
    try {
      final spPost = sp.ReflectionPost(
        authorName: post.authorName,
        spaceKey: _mapSpaceKey(post.spaceKey),
        intentTag: post.toneTag,
        specialInterestTag: post.specialInterestTag,
        content: post.content,
        createdAt: post.timestamp.toUtc(),
        prayingCount: post.reactions['pray'] ?? 0,
        standingWithCount: post.reactions['standing'] ?? 0,
        peaceCount: post.reactions['peace'] ?? 0,
        encouragedCount: post.reactions['encouraged'] ?? 0,
      );

      final result = await _client.reflection
          .publishReflection(spPost)
          .timeout(const Duration(milliseconds: 1200));

      _isLiveConnected = true;

      return Post(
        id: result.id?.toString() ?? post.id,
        authorName: result.authorName,
        spaceKey: post.spaceKey,
        toneTag: result.intentTag,
        specialInterestTag: result.specialInterestTag,
        content: result.content,
        timestamp: result.createdAt.toLocal(),
        reactions: {
          'pray': result.prayingCount,
          'standing': result.standingWithCount,
          'peace': result.peaceCount,
          'encouraged': result.encouragedCount,
          'relatable': result.encouragedCount,
        },
      );
    } catch (_) {
      _isLiveConnected = false;
      return _fallback.createPost(post);
    }
  }

  @override
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  }) async {
    final parsedId = int.tryParse(postId);
    if (parsedId != null) {
      try {
        final keyMap = {
          'pray': 'praying',
          'standing': 'standingWith',
          'peace': 'peace',
          'encouraged': 'encouraged',
          'relatable': 'relatable',
        };
        await _client.reflection
            .affirmCare(parsedId, keyMap[reactionType] ?? reactionType)
            .timeout(const Duration(milliseconds: 1200));
        _isLiveConnected = true;
        return;
      } catch (_) {
        _isLiveConnected = false;
      }
    }
    return _fallback.addReaction(postId: postId, reactionType: reactionType);
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) async* {
    // 1. Instantly yield local fallback so user never sees a blank screen or loading spinner
    yield await _fallback.getPosts(spaceKey: spaceKey);

    // 2. Try to connect to Serverpod streaming endpoint
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      final stream = _client.reflection
          .watchSpace(mappedSpace)
          .timeout(const Duration(milliseconds: 800));

      final livePosts = <Post>[];

      await for (final spPost in stream) {
        _isLiveConnected = true;
        final post = Post(
          id: spPost.id?.toString() ?? UniqueKey().toString(),
          authorName: spPost.authorName,
          spaceKey: spaceKey,
          toneTag: spPost.intentTag,
          specialInterestTag: spPost.specialInterestTag,
          content: spPost.content,
          timestamp: spPost.createdAt.toLocal(),
          reactions: {
            'pray': spPost.prayingCount,
            'standing': spPost.standingWithCount,
            'peace': spPost.peaceCount,
            'encouraged': spPost.encouragedCount,
            'relatable': spPost.encouragedCount,
          },
        );

        final existingIdx = livePosts.indexWhere((p) => p.id == post.id);
        if (existingIdx >= 0) {
          livePosts[existingIdx] = post;
        } else {
          livePosts.insert(0, post);
        }
        yield List<Post>.from(livePosts);
      }
    } catch (_) {
      // 3. Fallback gracefully to local stream
      _isLiveConnected = false;
      yield* _fallback.watchPosts(spaceKey: spaceKey);
    }
  }

  @override
  Future<String?> getQuietDigest({required String spaceKey}) async {
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      final digest = await _client.reflection
          .getQuietDigest(mappedSpace)
          .timeout(const Duration(milliseconds: 800));
      _isLiveConnected = true;
      return digest.summaryMessage;
    } catch (_) {
      _isLiveConnected = false;
      return _fallback.getQuietDigest(spaceKey: spaceKey);
    }
  }
}

class SensoryThemeData {
  static ThemeData getTheme(SensoryMode mode) {
    switch (mode) {
      case SensoryMode.clean:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            surface: const Color(0xFFFAFAFA),
          ),
          cardColor: Colors.white,
          dividerColor: const Color(0xFFE2E8F0),
        );
      case SensoryMode.sage:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F7F5),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7C59),
            surface: const Color(0xFFE6ECE8),
            primary: const Color(0xFF4A7C59),
          ),
          cardColor: Colors.white,
          dividerColor: const Color(0xFFDDE5E0),
        );
      case SensoryMode.charcoal:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1D20),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF68A67D),
            surface: Color(0xFF24282D),
          ),
          cardColor: const Color(0xFF24282D),
          dividerColor: const Color(0xFF333A42),
        );
      case SensoryMode.contrast:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFEB3B),
            surface: Color(0xFF0F0F0F),
            onSurface: Colors.white,
          ),
          cardColor: Colors.black,
          dividerColor: Colors.white,
        );
    }
  }
}

class ThemeNotifier extends ChangeNotifier {
  SensoryMode _mode = SensoryMode.sage;
  SensoryMode get mode => _mode;

  void setMode(SensoryMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }
}

/// Backend runtime environment determined via --dart-define=BACKEND=...
enum BackendMode { local, serverpod, sqlite }

BackendMode get configuredBackendMode {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'local');
  switch (backend.toLowerCase()) {
    case 'serverpod':
      return BackendMode.serverpod;
    case 'sqlite':
    case 'postgres':
    case 'docker':
      return BackendMode.sqlite;
    case 'local':
    default:
      return BackendMode.local;
  }
}

class PostRepositoryFactory {
  static PostRepository create() {
    final mode = configuredBackendMode;
    switch (mode) {
      case BackendMode.serverpod:
        return ServerpodPostRepository();
      case BackendMode.sqlite:
      case BackendMode.local:
        return LocalPostRepository();
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = PostRepositoryFactory.create();
  runApp(SanctuaryApp(repository: repository));
}

class SanctuaryApp extends StatefulWidget {
  final PostRepository repository;
  const SanctuaryApp({super.key, required this.repository});

  @override
  State<SanctuaryApp> createState() => _SanctuaryAppState();
}

class _SanctuaryAppState extends State<SanctuaryApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sanctuary Digital Clubhouse',
          theme: SensoryThemeData.getTheme(_themeNotifier.mode),
          home: SanctuaryHomeScreen(
            repository: widget.repository,
            themeNotifier: _themeNotifier,
          ),
        );
      },
    );
  }
}

class SanctuaryHomeScreen extends StatefulWidget {
  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  const SanctuaryHomeScreen({
    super.key,
    required this.repository,
    required this.themeNotifier,
  });

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen> {
  String _selectedSpace = 'prayer';
  String _selectedTone = '[Prayer Request]';
  String _activeFilter = 'All';
  String? _quietDigestMessage;
  Map<String, String>? _attachedMeme;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _specialInterestController =
      TextEditingController();
  Stream<List<Post>>? _postStream;

  final Map<String, String> _spaces = const {
    'prayer': '🙏 #prayer-sanctuary',
    'study': '📖 #weekly-study',
    'announcements': '📢 #announcements',
    'special_interests': '🧩 #special-interests-memes',
    'general': '🌿 #main-hall',
  };

  final List<String> _toneOptions = const [
    '[Prayer Request]',
    '[Comfort Only]',
    '[Bible Deep-Dive]',
    '[Special Interest Infodump]',
    '[Autism & Faith Meme]',
    '[Giving Thanks]',
    '[Question]',
    '[Resource]',
  ];

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _specialInterestController.dispose();
    super.dispose();
  }

  void _refreshStream() {
    setState(() {
      _postStream = widget.repository.watchPosts(spaceKey: _selectedSpace);
    });
    widget.repository.getQuietDigest(spaceKey: _selectedSpace).then((digest) {
      if (mounted && digest != null) {
        setState(() {
          _quietDigestMessage = digest;
        });
      }
    });
  }

  void _onSelectSpace(String spaceKey) {
    if (_selectedSpace != spaceKey) {
      _selectedSpace = spaceKey;
      _refreshStream();
    }
  }

  Future<void> _submitPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    final specialInterest = _specialInterestController.text.trim().isNotEmpty
        ? _specialInterestController.text.trim()
        : (_selectedTone.contains('Meme') ? 'Faith & Neurodiversity' : null);

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Fellowship Member',
      spaceKey: _selectedSpace,
      toneTag: _selectedTone,
      specialInterestTag: specialInterest,
      content: text,
      timestamp: DateTime.now(),
      reactions: {'pray': 1, 'peace': 1, 'encouraged': 1, 'relatable': 1},
    );

    _contentController.clear();
    _specialInterestController.clear();
    setState(() {
      _attachedMeme = null;
    });
    await widget.repository.createPost(newPost);
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = widget.themeNotifier.mode == SensoryMode.contrast;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isLiveServerpod = widget.repository is ServerpodPostRepository &&
        (widget.repository as ServerpodPostRepository).isLiveConnected;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sanctuary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLiveServerpod
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF68A67D),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Calm Tech • ${isLiveServerpod ? "Live" : "Resilient"}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeChip(SensoryMode.clean, 'Clean'),
                _buildThemeChip(SensoryMode.sage, 'Sage'),
                _buildThemeChip(SensoryMode.charcoal, 'Dark'),
                _buildThemeChip(SensoryMode.contrast, 'Contrast'),
                IconButton(
                  tooltip: 'About Sanctuary & Hackathon Credits',
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showAboutSanctuaryDialog(
                    context,
                    primaryColor,
                    isContrast,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              _buildCommunityAnchorBanner(primaryColor, isContrast),
              _buildSpaceNavigation(),
              _buildQuietDigestBanner(primaryColor, isContrast),
              _buildComposerCard(primaryColor, isContrast),
              _buildToneFilterRow(),
              Expanded(child: _buildPostList(isContrast)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityAnchorBanner(Color primaryColor, bool isContrast) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isContrast
            ? Colors.black
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isContrast
              ? Colors.yellow
              : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isContrast
                  ? Colors.yellow.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.15),
            ),
            child: const Text('🧩', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Belong on the Spectrum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.yellow : primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• belongonthespectrum.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '"Fearfully and wonderfully made" (Psalm 139:14)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: isContrast
                        ? Colors.white70
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showAboutSanctuaryDialog(
              context,
              primaryColor,
              isContrast,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isContrast ? Colors.yellow : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSanctuaryDialog(
    BuildContext context,
    Color primaryColor,
    bool isContrast,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('🧩', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sanctuary (Refuge) v0.1.0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isContrast ? Colors.yellow : primaryColor,
                    ),
                  ),
                  Text(
                    'Belong on the Spectrum • belongonthespectrum.com',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.yellow.withValues(alpha: 0.1)
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isContrast
                          ? Colors.yellow
                          : primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    '"I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."\n— Psalm 139:14',
                    style:
                        TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Community Purpose & Calm-Tech Moat:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Created by and for Autistic Disciples of Jesus and their allies.\n'
                  '• Replaces expensive mainstream community SaaS (\$89–\$130/month) with low-cost (<\$5/month) Serverpod compute.\n'
                  '• Zero dopamine manipulation: no red unread badges, no typing indicators, no algorithmic feeds, no notification anxiety.\n'
                  '• Unifying Special Interest: Everyone brings their unique God-given interests while sharing Scripture & following Christ as our anchor.',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
                const Divider(height: 20),
                const Text(
                  'Grateful Appreciation & Hackathon Credits:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '🌟 BuilderBase: For developer cloud credits, deployment infrastructure, and sponsoring the Serverpod Hackathon.\n'
                  '⚡ Serverpod Team & Community: For building an outstanding full-stack Dart framework with typed protocol generation and real-time streaming.\n'
                  '🌿 Belong on the Spectrum: For inspiring our community architecture and showing that neurodiversity in the Church is a gift.',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
                const Divider(height: 20),
                const Text(
                  'Release Log (v0.1.0):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Serverpod 4 (^4.0.4) protocol models (.spy.yaml) & ORM\n'
                  '• Atomic PostgreSQL qualitative care affirmations\n'
                  '• Real-time WebSocket streaming with 800ms resilient offline fallback\n'
                  '• Server-side Quiet Digest aggregation over space reflections\n'
                  '• 4 WCAG AAA-tested sensory modes (Sage, Clean, Dark, Contrast)\n'
                  '• 5 Fellowship spaces with Autism & Faith Meme support\n'
                  '• Public GitHub Repository: neiljaywarner/refuge4serverpod',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietDigestBanner(Color primaryColor, bool isContrast) {
    if (_quietDigestMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isContrast
            ? Colors.yellow.withValues(alpha: 0.1)
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isContrast
              ? Colors.yellow
              : primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_twilight,
            size: 15,
            color: isContrast ? Colors.yellow : primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _quietDigestMessage!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isContrast ? Colors.yellow : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(SensoryMode mode, String label) {
    final isSelected = widget.themeNotifier.mode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        selected: isSelected,
        onSelected: (_) => widget.themeNotifier.setMode(mode),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSpaceNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _spaces.entries.map((entry) {
            final isSelected = _selectedSpace == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: isSelected,
                label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                onSelected: (_) => _onSelectSpace(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComposerCard(Color primaryColor, bool isContrast) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isContrast ? Colors.white : Theme.of(context).dividerColor,
          width: isContrast ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Intent Tag: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedTone,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                underline: const SizedBox(),
                items: _toneOptions.map((tone) {
                  return DropdownMenuItem(value: tone, child: Text(tone));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTone = val);
                },
              ),
            ],
          ),
          if (_selectedTone.contains('Special Interest') ||
              _selectedTone.contains('Meme') ||
              _selectedSpace == 'special_interests') ...[
            const SizedBox(height: 6),
            TextField(
              controller: _specialInterestController,
              decoration: InputDecoration(
                hintText:
                    'Special Interest tag (e.g. Church Acoustics, Markan Chiasms, Liturgy)...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Share an unhurried thought, Scripture insight, or relatable reflection...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
          ),
          const SizedBox(height: 8),
          if (_attachedMeme != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Text(_attachedMeme!['icon'] ?? '🖼️',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: ${_attachedMeme!['title']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isContrast ? Colors.yellow : Colors.amber.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _attachedMeme = null),
                    child: const Icon(Icons.close, size: 14),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(
                    color: isContrast
                        ? Colors.white
                        : Theme.of(context).dividerColor,
                  ),
                ),
                onPressed: _showMemeGalleryModal,
                icon: const Icon(Icons.sentiment_very_satisfied_outlined,
                    size: 14),
                label: Text(
                  _attachedMeme != null ? 'Change Meme' : 'Add Meme / GIF',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isContrast ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _submitPost,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Publish Reflection',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMemeGalleryModal() {
    final memes = [
      {
        'title': 'Elijah Under the Broom Tree',
        'icon': '🍞 💤',
        'subtitle': '1 Kings 19:5 — Snack & Nap',
        'tag': 'Burnout & Recovery',
        'body':
            'When you have severe sensory burnout and think you are done with ministry, but God\'s holy prescription is literally a warm cake of bread and a nap under the broom tree.',
      },
      {
        'title': '2 Hours of Fellowship vs 3 Days in Dark Room',
        'icon': '🕶️ 🤫',
        'subtitle': 'Sensory Math for the Saints',
        'tag': 'Masking & Church',
        'body':
            'Masking through Sunday fellowship hall small talk for 90 minutes = 72 hours of mandatory quiet sensory recharge under a weighted blanket in a dark room.',
      },
      {
        'title': 'Specially Interested by Divine Design',
        'icon': '🧩 🚂',
        'subtitle': 'Psalm 139:14 — Fearfully Made',
        'tag': 'Special Interests',
        'body':
            'When someone asks a casual 5-second question about church history or train switching gears, and my autistic brain prepares a 45-minute PowerPoint with handouts.',
      },
      {
        'title': 'Reading Greek Verbs at 2 AM',
        'icon': '📖 🦉',
        'subtitle': 'Hyperfixation as Worship',
        'tag': 'Bible Deep-Dive',
        'body':
            'Who needs circadian rhythm when the aorist subjunctive in Romans 8:28 is demanding our immediate, uninterrupted hyperfixation until dawn?',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🖼️ Autism & Faith Meme Gallery',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Wholesome, unhurried, relatable neurodivergent Christian humor (Belong on the Spectrum curated collection).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: memes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = memes[i];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _attachedMeme = m;
                            _selectedTone = '[Autism & Faith Meme]';
                            _specialInterestController.text = m['tag']!;
                            if (_contentController.text.trim().isEmpty) {
                              _contentController.text =
                                  '${m['icon']} "${m['title']}"\n\n${m['body']}';
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.amber.shade700
                                    .withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.amber.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['icon']!,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['title']!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      m['subtitle']!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['body']!,
                                      style: const TextStyle(
                                          fontSize: 11, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToneFilterRow() {
    final filters = [
      'All',
      '[Prayer Request]',
      '[Comfort Only]',
      '[Bible Deep-Dive]',
      '[Special Interest Infodump]',
      '[Autism & Faith Meme]',
      '[Giving Thanks]',
      '[Question]',
      '[Resource]',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = _activeFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(f, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(bool isContrast) {
    return StreamBuilder<List<Post>>(
      stream: _postStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        var posts = snapshot.data!;
        if (_activeFilter != 'All') {
          posts = posts.where((p) => p.toneTag == _activeFilter).toList();
        }

        if (posts.isEmpty) {
          return Center(
            child: Text(
              'Space is quiet right now.\nBe the first to share an unhurried thought.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          itemBuilder: (context, index) {
            final p = posts[index];
            final isMeme = p.toneTag.contains('Meme');
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isMeme
                      ? Colors.amber.withValues(alpha: 0.8)
                      : (isContrast
                          ? Colors.white
                          : Theme.of(context).dividerColor),
                  width: isMeme ? 2.0 : (isContrast ? 2.0 : 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.authorName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: isMeme
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          p.toneTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMeme
                                ? Colors.amber.shade800
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (p.specialInterestTag != null &&
                      p.specialInterestTag!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        '🧩 Special Interest: ${p.specialInterestTag}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    p.content,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => widget.repository.addReaction(
                            postId: p.id,
                            reactionType: 'pray',
                          ),
                          icon:
                              const Text('🙏', style: TextStyle(fontSize: 12)),
                          label: Text(
                            '${p.reactions['pray'] ?? 0} Praying',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => widget.repository.addReaction(
                            postId: p.id,
                            reactionType: 'peace',
                          ),
                          icon:
                              const Text('🤍', style: TextStyle(fontSize: 12)),
                          label: Text(
                            '${p.reactions['peace'] ?? 0} Support',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        if (p.reactions.containsKey('encouraged') ||
                            p.reactions.containsKey('relatable')) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () => widget.repository.addReaction(
                              postId: p.id,
                              reactionType: 'encouraged',
                            ),
                            icon: const Text('🌱',
                                style: TextStyle(fontSize: 12)),
                            label: Text(
                              '${p.reactions['encouraged'] ?? 0} Encouraged',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () => widget.repository.addReaction(
                              postId: p.id,
                              reactionType: 'relatable',
                            ),
                            icon: const Text('😄',
                                style: TextStyle(fontSize: 12)),
                            label: Text(
                              '${p.reactions['relatable'] ?? 0} Relatable',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/*
================================================================================
GEMINI 3.8 FLASH ITERATION & AGENTIC TESTING PROMPT (COPY/PASTE OR REFERENCE)
================================================================================
ROLE & OPERATIONAL OBJECTIVE:
You are an ultra-fast, autonomous Staff Flutter & Serverpod Systems Engineer
operating in an agentic IDE (Cursor, Claude Code, Antigravity, or VS Code Copilot).
Your goal is to inspect, launch, verify, test, and iterate on this Sanctuary
codebase without breaking the core architecture.

AVAILABLE MCP SERVERS, SKILLS & TOOLS AT YOUR DISPOSAL:
1. OFFICIAL FLUTTER & DART MCP SERVERS / CLI:
   - Run `flutter analyze` or use the analysis MCP tools to detect zero warnings/errors.
   - Run `dart format .` and `flutter test`.
   - Launch app via `flutter run -d macos` or `flutter run -d chrome`.
2. MARIONETTE MCP SERVER & CLI (Browser & UI Automation):
   - Launch the web build in a headless/automated Chromium window.
   - Inspect the DOM / Widget render tree.
   - Click theme chips ('Clean', 'Sage', 'Dark', 'Contrast') and assert CSS/Theme updates.
   - Fill the content TextField, select an intent tag, submit, and verify the post card appears in the list.
3. PATROL MCP SERVER & CLI (Advanced Integration & Native Testing):
   - Execute `patrol test` to perform robust end-to-end user journeys without flaky pumpAndSettle timeouts.
   - Validate qualitative care reaction counters increment correctly upon clicking.
4. SERVERPOD 4 CLI & SERVERPOD MCP SERVER:
   - Use `serverpod_mcp` for StarGuide official v4 API documentation queries.
   - When migrating to Serverpod:
     a. Scaffold `sanctuary_server/sanctuary_server_server/lib/src/protocol/post.spy.yaml`.
     b. Run `serverpod generate`.
     c. Verify PostgreSQL docker container is up (`docker compose up -d`).
     d. Implement `ServerpodPostRepository implements PostRepository` connecting to `client.post.streamPosts()`.
     e. Update `void main()` in `lib/main.dart` to instantiate `ServerpodPostRepository`.

STRICT NON-NEGOTIABLES:
- NEVER add red unread badge counters, flashing alerts, typing indicators, or read receipts.
- KEEP all data mutations routed strictly through `PostRepository`.
- Maintain single-file runnable integrity whenever requested.
================================================================================
*/
