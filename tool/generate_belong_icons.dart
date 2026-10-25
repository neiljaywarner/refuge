import 'dart:io';

/// Pure-Dart multi-platform icon generator for **Belong on the Spectrum** (#19).
///
/// Follows Apple Human Interface Guidelines & Android Adaptive Icon best practices:
/// 1. **iOS & macOS**: Flattens onto opaque `#F3EFE6` warm cream (`rgb24`, zero alpha channel)
///    so App Store Connect never rejects for alpha transparency.
/// 2. **Android Adaptive Icons (API 26+) & Web Maskable Icons**: Insets the 1024x1024
///    Belong Cross + Gold Infinity mark into the 66% safe zone (`676x676` centered inside
///    `1024x1024` `#F3EFE6`) so circular, squircle, and teardrop launcher masks never
///    clip the vertical `BELONG` letters or gold `∞` loop.
Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    Directory.current = Directory(args.first);
  }
  const src = 'assets/images/belong_logo.png';
  const ffmpeg = '/opt/homebrew/bin/ffmpeg';

  if (!File(src).existsSync()) {
    stderr.writeln('Missing source logo at $src');
    exit(1);
  }

  Directory('build/icon_gen').createSync(recursive: true);
  const opaqueMaster = 'build/icon_gen/belong_opaque_1024.png';
  const safeZoneMaster = 'build/icon_gen/belong_safezone_1024.png';

  // 1. Generate 1024x1024 opaque master (RGB24, #F2EEE2 background, zero alpha)
  await _run(ffmpeg, [
    '-y',
    '-f',
    'lavfi',
    '-i',
    'color=c=0xF2EEE2:s=1024x1024',
    '-i',
    src,
    '-filter_complex',
    '[1:v]scale=920:920:force_original_aspect_ratio=decrease[fg];[0:v][fg]overlay=(W-w)/2:(H-h)/2,format=rgb24',
    '-frames:v',
    '1',
    opaqueMaster,
  ]);

  // 2. Generate 1024x1024 Android Adaptive / Web Maskable safe-zone master (66% safe zone = 676px)
  await _run(ffmpeg, [
    '-y',
    '-f',
    'lavfi',
    '-i',
    'color=c=0xF2EEE2:s=1024x1024',
    '-i',
    src,
    '-filter_complex',
    '[1:v]scale=676:676:force_original_aspect_ratio=decrease[fg];[0:v][fg]overlay=(W-w)/2:(H-h)/2,format=rgb24',
    '-frames:v',
    '1',
    safeZoneMaster,
  ]);

  // 3. Web & PWA Icons
  await _scale(opaqueMaster, 'web/favicon.png', 48);
  await _scale(opaqueMaster, 'web/icons/Icon-192.png', 192);
  await _scale(opaqueMaster, 'web/icons/Icon-512.png', 512);
  await _scale(safeZoneMaster, 'web/icons/Icon-maskable-192.png', 192);
  await _scale(safeZoneMaster, 'web/icons/Icon-maskable-512.png', 512);

  // 4. Android Legacy + Adaptive Foreground Mipmaps
  const androidSizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  const androidAdaptiveSizes = <String, int>{
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
  };

  for (final entry in androidSizes.entries) {
    final dir = 'android/app/src/main/res/${entry.key}';
    Directory(dir).createSync(recursive: true);
    await _scale(opaqueMaster, '$dir/ic_launcher.png', entry.value);
  }
  for (final entry in androidAdaptiveSizes.entries) {
    final dir = 'android/app/src/main/res/${entry.key}';
    Directory(dir).createSync(recursive: true);
    await _scale(safeZoneMaster, '$dir/ic_launcher_foreground.png', entry.value);
  }

  // 4b. Android Native Splash Screen Logo (pre-API 31 & API 31+ SplashScreen API)
  const drawableDir = 'android/app/src/main/res/drawable';
  Directory(drawableDir).createSync(recursive: true);
  await _scale(safeZoneMaster, '$drawableDir/launch_logo.png', 288);

  // 5. iOS AppIcon.appiconset (Opaque RGB24 per Apple HIG)
  const iosIcons = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };
  for (final entry in iosIcons.entries) {
    await _scale(
      opaqueMaster,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}',
      entry.value,
    );
  }

  // 6. macOS AppIcon.appiconset
  const macosIcons = <String, int>{
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
  };
  for (final entry in macosIcons.entries) {
    await _scale(
      opaqueMaster,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}',
      entry.value,
    );
  }

  Directory('build/icon_gen').deleteSync(recursive: true);
  stdout.writeln(
    '==> Successfully generated all Belong multi-platform icons (Android Adaptive, iOS HIG opaque, macOS, and Web PWA)!',
  );
}

Future<void> _scale(String input, String output, int size) async {
  await _run('/opt/homebrew/bin/ffmpeg', [
    '-y',
    '-i',
    input,
    '-vf',
    'scale=$size:$size:flags=lanczos,format=rgb24',
    '-frames:v',
    '1',
    output,
  ]);
}

Future<void> _run(String exe, List<String> args) async {
  final res = await Process.run(exe, args);
  if (res.exitCode != 0) {
    stderr.writeln('Command failed: $exe ${args.join(' ')}\n${res.stderr}');
    exit(res.exitCode);
  }
}
