import 'package:flutter_test/flutter_test.dart';
import 'package:oma/core/network/api_config.dart';

/// Confirms client is pointed at oma_be.
/// Live HTTP is exercised outside `flutter test` (binding stubs HttpClient).
void main() {
  test('oma_be wiring is configured to default Render host', () {
    expect(ApiConfig.defaultBaseUrl, contains('oma-be'));
    expect(ApiConfig.apiPrefix, '/api/v1');
    expect(ApiConfig.useMock, isFalse);
  });
}
