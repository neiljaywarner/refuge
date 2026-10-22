/// Sensory-friendly font scaling presets designed to relieve visual crowding
/// and sensory reading fatigue for autistic and low-vision disciples (Issue #277).
enum SensoryFontScale {
  standard(1.0, 'Standard', '100%'),
  comfort(1.15, 'Comfort', '115%'),
  spacious(1.30, 'Spacious', '130%'),
  clarity(1.50, 'Max Clarity', '150%');

  final double scaleFactor;
  final String label;
  final String percentage;

  const SensoryFontScale(this.scaleFactor, this.label, this.percentage);
}
