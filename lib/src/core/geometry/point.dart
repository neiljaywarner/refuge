/// Synthetic 2D integer point for style docs and unit tests (#609).
///
/// Prefer primary constructors on small immutable value types like this one.
/// See `docs/wiki/CI-CD-FAQ.md` — Primary constructors.
class const Point(final int x, final int y);
