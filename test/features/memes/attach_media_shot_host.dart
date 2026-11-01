import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refuge4serverpod/src/core/build/build_identity.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_build_stamp.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_refuge_dialog.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_remote_settings.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_sdk_picker.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_search.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_surface.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

/// Dev-only frame host for Attach media screenshots. Not a production entry.
///
/// Synthetic GIF titles only. The fixture key is never sent to Giphy.
///
/// ```bash
/// flutter run -d web-server -t test/features/memes/attach_media_shot_host.dart --web-port 8099
/// ```
void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.ensureSemantics();
  runApp(const _ShotHost());
}

const _tealStill =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGNwa6qgCmIYNWjUoFGDRg0aNWjUoIE3CADmqdAf59hpwwAAAABJRU5ErkJggg==';
const _amberStill =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGM4MsWLKohh1KBRg0YNGjVo1KBRgwbeIAAcBKyubmnaIwAAAABJRU5ErkJggg==';

class _ShotHost extends StatefulWidget {
  const _ShotHost();

  @override
  State<_ShotHost> createState() => _ShotHostState();
}

class _ShotHostState extends State<_ShotHost> {
  var _native = false;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_native),
      overrides: [
        giphySurfaceProvider.overrideWithValue(
          _native ? GiphySurface.nativeSdk : GiphySurface.webApi,
        ),
        giphySearchProvider.overrideWithValue(_ShotGiphySearch()),
        giphyRemoteSettingsProvider.overrideWithValue(
          const GiphyRemoteSettings(apiKey: 'shot-host-not-a-giphy-key', rating: 'pg'),
        ),
        giphySdkLauncherProvider.overrideWithValue(({
          required apiKey,
          required rating,
          required onSelected,
        }) {
          onSelected(
            const CalmMeme(
              title: 'quiet clip',
              icon: '🎬',
              subtitle: 'GIPHY clip · rated PG',
              tag: 'Memes',
              body: 'quiet clip',
              imageUrl: 'https://media.giphy.com/media/shot-host-clip/200.gif',
            ),
          );
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: ListView(
            children: [
              ReflectionComposer(
                selectedSpace: 'memes',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: true,
                onSubmit: ({
                  required content,
                  required toneTag,
                  specialInterestTag,
                  imageUrl,
                }) async {},
              ),
              TextButton(
                key: const Key('shot_host_surface'),
                onPressed: () => setState(() => _native = !_native),
                child: Text(_native ? 'Show web GIF search' : 'Show native Open Giphy'),
              ),
              Builder(
                builder: (context) => TextButton(
                  key: const Key('shot_host_about'),
                  onPressed: () => showAboutRefugeDialog(
                    context,
                    primaryColor: Colors.teal,
                    isContrast: false,
                    buildIdentity: const BuildIdentity(),
                    loadVersion: () async => AppVersionLabel.unknown,
                    onOpenFeedback: () {},
                  ),
                  child: const Text('About'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotGiphySearch implements GiphySearch {
  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      GiphyGif(
        id: 'chapel',
        title: 'quiet chapel',
        stillUrl: _tealStill,
        gifUrl: 'https://media.giphy.com/media/shot-host-chapel/200.gif',
      ),
      GiphyGif(
        id: 'bread',
        title: 'warm bread',
        stillUrl: _amberStill,
        gifUrl: 'https://media.giphy.com/media/shot-host-bread/200.gif',
      ),
    ];
  }
}
