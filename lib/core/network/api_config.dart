/// Base URL for [oma_be](https://github.com/evander006/oma_be) FastAPI.
///
/// Default: hosted Render instance.
/// Override: `--dart-define=API_BASE_URL=https://...`
abstract final class ApiConfig {
  static const _defined = String.fromEnvironment('API_BASE_URL');
  static const useMock =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

  /// Production / demo API: https://oma-be-85l2.onrender.com
  static const defaultBaseUrl = 'https://oma-be-85l2.onrender.com';

  static const apiPrefix = '/api/v1';

  static String get baseUrl {
    if (_defined.isNotEmpty) return _defined.replaceAll(RegExp(r'/$'), '');
    return defaultBaseUrl;
  }

  static String absoluteUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) return '$baseUrl$pathOrUrl';
    return '$baseUrl/$pathOrUrl';
  }
}
