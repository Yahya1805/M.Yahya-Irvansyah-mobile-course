import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/format.dart';

void main() {
  test('formatDate returns a zero-padded date', () {
    expect(formatDate(DateTime(2026, 9, 7)), '07/09/2026');
  });

  test('parseRoute returns the URI path without query or fragment', () {
    expect(parseRoute('/notes?source=push#latest'), '/notes');
  });

  test('parseRoute returns null for a missing route', () {
    expect(parseRoute(null), isNull);
  });
}
