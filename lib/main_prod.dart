import 'main.dart';

/// Production flavor entrypoint (`flutter build web -t lib/main_prod.dart`).
/// Used for `https://belongonthespectrum.web.app` production deployments.
void main() async {
  await bootstrapBelongApp(flavor: AppFlavor.prod);
}
