import 'main.dart';

/// BEMA discussion-group build. Same dev Firebase project as `main_dev.dart`.
///
/// ```bash
/// flutter build web -t lib/main_bema.dart \
///   --dart-define=BRAND=bema \
///   --dart-define=FLAVOR=dev \
///   --dart-define=STREAM_VIDEO_PREVIEW=true \
///   --dart-define=STREAM_TOKEN_ENDPOINT="$STREAM_TOKEN_ENDPOINT"
/// ```
void main() {
  const brand = String.fromEnvironment('BRAND', defaultValue: 'belong');
  if (brand != 'bema') {
    throw StateError('Build lib/main_bema.dart with --dart-define=BRAND=bema');
  }
  bootstrapBelongApp(flavor: AppFlavor.dev);
}
