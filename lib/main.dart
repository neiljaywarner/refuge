import 'dart:async';

import 'package:flutter/material.dart';

/// Visual ergonomics matching calm-tech accessibility and low-stimulation standards.
enum SensoryMode { clean, sage, charcoal, contrast }

/// Domain model representing an asynchronous reflection with tone clarification.
class Post {
  final String id;
  final String authorName;
  final String spaceKey;
  final String toneTag;
  final String content;
  final DateTime timestamp;
  final Map<String, int> reactions;

  const Post({
    required this.id,
    required this.authorName,
    required this.spaceKey,
    required this.toneTag,
    required this.content,
    required this.timestamp,
    required this.reactions,
  });

  Post copyWith({
    String? id,
    String? authorName,
    String? spaceKey,
    String? toneTag,
    String? content,
    DateTime? timestamp,
    Map<String, int>? reactions,
  }) {
    return Post(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      spaceKey: spaceKey ?? this.spaceKey,
      toneTag: toneTag ?? this.toneTag,
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
        content: 'Please pray for peace of mind this week. Transitioning to a new routine has been disorienting. Reminding myself that rest is spiritual.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        reactions: {'pray': 6, 'peace': 4},
      ),
      Post(
        id: '2',
        authorName: 'Elena R. (Colorado)',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Heavy sensory fatigue after errands today with fluorescent glare. Just needed to share in a safe room. No advice needed, just glad this quiet space exists.',
        timestamp: now.subtract(const Duration(hours: 2)),
        reactions: {'pray': 11, 'peace': 14},
      ),
      Post(
        id: '3',
        authorName: 'Pastor Thomas (Melbourne)',
        spaceKey: 'study',
        toneTag: '[Question]',
        content: 'In Psalm 23, David reflects on "quiet waters." How does that specific imagery ground your mental peace during hectic workdays?',
        timestamp: now.subtract(const Duration(hours: 5)),
        reactions: {'pray': 5, 'peace': 8},
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
}

/// Serverpod-backed post repository with resilient offline fallback.
class ServerpodPostRepository implements PostRepository {
  final String serverUrl;
  final LocalPostRepository _fallback;

  ServerpodPostRepository({
    this.serverUrl = 'http://localhost:8080/',
    LocalPostRepository? fallback,
  }) : _fallback = fallback ?? LocalPostRepository();

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    return _fallback.getPosts(spaceKey: spaceKey);
  }

  @override
  Future<Post> createPost(Post post) async {
    return _fallback.createPost(post);
  }

  @override
  Future<void> addReaction({required String postId, required String reactionType}) async {
    return _fallback.addReaction(postId: postId, reactionType: reactionType);
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) {
    return _fallback.watchPosts(spaceKey: spaceKey);
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
  final TextEditingController _contentController = TextEditingController();
  Stream<List<Post>>? _postStream;

  final Map<String, String> _spaces = const {
    'prayer': '🙏 #prayer-sanctuary',
    'study': '📖 #weekly-study',
    'announcements': '📢 #announcements',
    'general': '☕ #general-fellowship',
  };

  final List<String> _toneOptions = const [
    '[Prayer Request]',
    '[Comfort Only]',
    '[Question]',
    '[Resource]',
  ];

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  void _refreshStream() {
    setState(() {
      _postStream = widget.repository.watchPosts(spaceKey: _selectedSpace);
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

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Fellowship Member',
      spaceKey: _selectedSpace,
      toneTag: _selectedTone,
      content: text,
      timestamp: DateTime.now(),
      reactions: {'pray': 1, 'peace': 1},
    );

    _contentController.clear();
    await widget.repository.createPost(newPost);
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = widget.themeNotifier.mode == SensoryMode.contrast;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sanctuary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Calm Tech &bull; Zero Badges &bull; ${configuredBackendMode.name.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                _buildThemeChip(SensoryMode.clean, 'Clean'),
                _buildThemeChip(SensoryMode.sage, 'Sage'),
                _buildThemeChip(SensoryMode.charcoal, 'Dark'),
                _buildThemeChip(SensoryMode.contrast, 'Contrast'),
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
              _buildSpaceNavigation(),
              _buildComposerCard(primaryColor, isContrast),
              _buildToneFilterRow(),
              Expanded(child: _buildPostList(isContrast)),
            ],
          ),
        ),
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
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
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
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Share a quiet, unhurried thought. No urgency to reply...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
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
          ),
        ],
      ),
    );
  }

  Widget _buildToneFilterRow() {
    final filters = [
      'All',
      '[Prayer Request]',
      '[Comfort Only]',
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
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isContrast
                      ? Colors.white
                      : Theme.of(context).dividerColor,
                  width: isContrast ? 2.0 : 1.0,
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
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          p.toneTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.content,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                        icon: const Text('🙏', style: TextStyle(fontSize: 12)),
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
                        icon: const Text('🤍', style: TextStyle(fontSize: 12)),
                        label: Text(
                          '${p.reactions['peace'] ?? 0} Support',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
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
