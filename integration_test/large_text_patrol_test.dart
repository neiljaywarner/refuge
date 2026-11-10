import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// Walks home, messages, and feedback at Android font scale 2.0.
///
/// Sets the scale with the platform settings binary, the same command as
/// `adb shell settings put system font_scale 2.0`, and restores it. Display
/// density is raised the same way and restored. Group-call join is not on
/// this branch (PR #905).
void main() {
  patrolTest('large system text: home, messages, and feedback stay usable', ($) async {
    if (!Platform.isAndroid) {
      markTestSkipped('font_scale via adb/settings needs an Android device or emulator');
      return;
    }

    final previousFont = await _settingsGet('font_scale');
    final previousDensity = await _readDensity();
    try {
      await _settingsPut('font_scale', '2.0');
      await _setLargerDensity(previousDensity);
      await pumpDevReadOnlyHome($);
      expect($('Vote & Feedback'), findsOneWidget);
      expect($('Home'), findsOneWidget);
      expect($('Belong'), findsWidgets);

      await $('Messages').tap();
      expect($('Direct Messages'), findsOneWidget);
      await $('Home').tap();
      await $('Vote & Feedback').tap();
      expect($('Belong Roadmap & Feedback'), findsOneWidget);
    } finally {
      await _settingsPut('font_scale', previousFont.isEmpty ? '1.0' : previousFont);
      await _restoreDensity(previousDensity);
    }
  });
}

Future<ProcessResult> _run(String executable, List<String> args) => Process.run(executable, args);

Future<String> _settingsGet(String key) async {
  final result = await _run('/system/bin/settings', ['get', 'system', key]);
  if (result.exitCode != 0) {
    throw StateError('settings get system $key failed: ${result.stderr} ${result.stdout}');
  }
  return '${result.stdout}'.trim();
}

Future<void> _settingsPut(String key, String value) async {
  final result = await _run('/system/bin/settings', ['put', 'system', key, value]);
  if (result.exitCode != 0) {
    throw StateError('settings put system $key $value failed: ${result.stderr} ${result.stdout}');
  }
}

class _Density {
  const _Density({required this.physical, this.override});

  final int physical;
  final int? override;

  int get effective => override ?? physical;
}

Future<_Density> _readDensity() async {
  final result = await _run('/system/bin/wm', ['density']);
  if (result.exitCode != 0) {
    throw StateError('wm density failed: ${result.stderr} ${result.stdout}');
  }
  final text = '${result.stdout}';
  final physical = RegExp(r'Physical density:\s*(\d+)').firstMatch(text);
  final override = RegExp(r'Override density:\s*(\d+)').firstMatch(text);
  if (physical == null) {
    throw StateError('wm density did not report a physical density: $text');
  }
  return _Density(
    physical: int.parse(physical.group(1)!),
    override: override == null ? null : int.parse(override.group(1)!),
  );
}

Future<void> _setLargerDensity(_Density current) async {
  // About 1.15x matches a larger Android display size without leaving the
  // emulator's UI unusable. This is separate from font_scale.
  final next = (current.effective * 1.15).round();
  final result = await _run('/system/bin/wm', ['density', '$next']);
  if (result.exitCode != 0) {
    throw StateError('wm density $next failed: ${result.stderr} ${result.stdout}');
  }
}

Future<void> _restoreDensity(_Density previous) async {
  if (previous.override == null) {
    final result = await _run('/system/bin/wm', ['density', 'reset']);
    if (result.exitCode != 0) {
      throw StateError('wm density reset failed: ${result.stderr} ${result.stdout}');
    }
    return;
  }
  final result = await _run('/system/bin/wm', ['density', '${previous.override}']);
  if (result.exitCode != 0) {
    throw StateError('wm density restore failed: ${result.stderr} ${result.stdout}');
  }
}
