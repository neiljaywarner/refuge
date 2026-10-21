import 'package:flutter/foundation.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'main.dart';

/// Development flavor entrypoint (`flutter run -t lib/main_dev.dart`).
/// Ensures developer testing and preview channels never clash with `prod`.
///
/// In debug/profile builds this also installs the Marionette binding so AI
/// agents can drive the app through the Marionette MCP server or CLI (see
/// `docs/driving_pixels.md`). Release builds and `main_prod.dart` never
/// include it.
void main() async {
  if (!kReleaseMode) {
    MarionetteBinding.ensureInitialized();
  }
  await bootstrapBelongApp(flavor: AppFlavor.dev);
}
