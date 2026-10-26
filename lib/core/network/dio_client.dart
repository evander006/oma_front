import 'package:dio/dio.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/api_exception.dart';

class DioClient {
  DioClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

  final Dio _dio;

  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      return parser != null ? parser(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final res = await _dio.post<dynamic>(path, data: data);
      return parser != null ? parser(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    T Function(dynamic data)? parser,
  }) async {
    try {
      final res = await _dio.delete<dynamic>(path);
      return parser != null ? parser(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    final detail = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : e.message ?? 'Network error';
    return ApiException(detail, statusCode: code);
  }
}
