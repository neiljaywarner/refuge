import 'package:refuge4serverpod/src/core/geometry/point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Point primary constructor stores coordinates', () {
    const origin = Point(0, 0);
    const corner = Point(1, 1);
    expect(origin.x, 0);
    expect(origin.y, 0);
    expect(corner.x, 1);
    expect(corner.y, 1);
  });
}
