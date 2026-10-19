import 'main.dart';

/// Development flavor entrypoint (`flutter run -t lib/main_dev.dart`).
/// Ensures developer testing and preview channels never clash with `prod`.
void main() {
  bootstrapBelongApp(flavor: AppFlavor.dev);
}
