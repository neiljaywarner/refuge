import 'main.dart';

/// Production flavor entrypoint (`flutter build web -t lib/main_prod.dart`).
/// Used for `belongonthespectrum.com` production deployments.
void main() {
  bootstrapBelongApp(flavor: AppFlavor.prod);
}
