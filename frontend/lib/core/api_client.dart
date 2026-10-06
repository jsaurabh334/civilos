import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'offline_sync_service.dart';
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

class ValidationException extends ApiException {
  ValidationException(super.message, {super.data}) : super(statusCode: 422);
}

class ApiClient {
  static String get baseUrl {
    const defaultUrl = 'http://localhost:8080/api/v1';
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultUrl);
    return envUrl;
  }

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _multipartTimeout = Duration(seconds: 30);

  String? _token;
  final Map<String, _CachedResponse> _cache = {};
  final Set<String> _inflight = {};

  void setToken(String? token) {
    _token = token;
  }

  void clearCache() {
    _cache.clear();
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$baseUrl$path');
    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params);
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, String>? params, bool forceRefresh = false}) async {
    final cacheKey = path;
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp).inSeconds < 5) {
        return cached.data;
      }
    }

    if (_inflight.contains(cacheKey)) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!.data;
    }

    int attempts = 0;
    const maxAttempts = 2;
    while (true) {
      try {
        _inflight.add(cacheKey);
        final response = await http
            .get(_uri(path, params), headers: _getHeaders())
            .timeout(_timeout);
        _inflight.remove(cacheKey);
        final result = _processResponse(response);
        _cache[cacheKey] = _CachedResponse(result, DateTime.now());
        OfflineSyncService().cacheResponse(cacheKey, result);
        return result;
      } on SocketException {
        _inflight.remove(cacheKey);
        final offlineData = OfflineSyncService().getCachedResponse(cacheKey, maxAge: const Duration(days: 7));
        if (offlineData != null) return offlineData;
        throw NetworkException('No internet connection and no offline data available.');
      } on http.ClientException {
        _inflight.remove(cacheKey);
        final offlineData = OfflineSyncService().getCachedResponse(cacheKey, maxAge: const Duration(days: 7));
        if (offlineData != null) return offlineData;
        throw NetworkException('Connection refused. Is the server running?');
      } catch (e) {
        _inflight.remove(cacheKey);
        attempts++;
        if (attempts >= maxAttempts) {
          if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!.data;
          if (e is ApiException) rethrow;
          throw NetworkException('Connection failed after $maxAttempts attempts: ${e.toString().replaceAll('Exception: ', '')}');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    _cache.remove(path);
    int attempts = 0;
    const maxAttempts = 2;

    final requestHeaders = _getHeaders();
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    if (!OfflineSyncService().isOnline) {
      OfflineSyncService().enqueue('POST', path, body: body);
      return {'message': 'Saved offline. Will sync when connected.', 'queued': true};
    }

    while (true) {
      try {
        final response = await http
            .post(_uri(path), headers: requestHeaders, body: jsonEncode(body))
            .timeout(_timeout);
        return _processResponse(response);
      } on SocketException {
        throw NetworkException('No internet connection. Please check your network.');
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          if (e is ApiException) rethrow;
          throw NetworkException('Connection failed after $maxAttempts attempts: ${e.toString().replaceAll('Exception: ', '')}');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<dynamic> postMultipart(String path, http.MultipartFile file, {Map<String, String>? fields}) async {
    _cache.remove(path);
    final request = http.MultipartRequest('POST', _uri(path));

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(file);
    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = await request.send().timeout(_multipartTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection. Please check your network.');
    } catch (e) {
      throw NetworkException('Upload failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    _cache.remove(path);
    if (!OfflineSyncService().isOnline) {
      OfflineSyncService().enqueue('PUT', path, body: body);
      return {'message': 'Saved offline. Will sync when connected.', 'queued': true};
    }
    
    int attempts = 0;
    const maxAttempts = 2;
    while (true) {
      try {
        final response = await http
            .put(_uri(path), headers: _getHeaders(), body: jsonEncode(body))
            .timeout(_timeout);
        return _processResponse(response);
      } on SocketException {
        throw NetworkException('No internet connection. Please check your network.');
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          if (e is ApiException) rethrow;
          throw NetworkException('Connection failed after $maxAttempts attempts: ${e.toString().replaceAll('Exception: ', '')}');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<dynamic> delete(String path) async {
    _cache.remove(path);
    if (!OfflineSyncService().isOnline) {
      OfflineSyncService().enqueue('DELETE', path);
      return {'message': 'Saved offline. Will sync when connected.', 'queued': true};
    }
    
    int attempts = 0;
    const maxAttempts = 2;
    while (true) {
      try {
        final response = await http
            .delete(_uri(path), headers: _getHeaders())
            .timeout(_timeout);
        return _processResponse(response);
      } on SocketException {
        throw NetworkException('No internet connection. Please check your network.');
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          if (e is ApiException) rethrow;
          throw NetworkException('Connection failed after $maxAttempts attempts: ${e.toString().replaceAll('Exception: ', '')}');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  dynamic _processResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final String body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    String errorMessage = 'Request failed';
    dynamic errorData;
    try {
      final errorJson = jsonDecode(body);
      if (errorJson is Map) {
        errorMessage = errorJson['error']?.toString() ?? errorJson['message']?.toString() ?? 'Unknown error';
        errorData = errorJson;
      }
    } catch (_) {
      errorMessage = body.isNotEmpty ? body : 'Unknown error (status $statusCode)';
    }

    switch (statusCode) {
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 422:
        throw ValidationException(errorMessage, data: errorData);
      default:
        throw ApiException(errorMessage, statusCode: statusCode, data: errorData);
    }
  }

  Future<Map<String, dynamic>> uploadFile(String path, String fileField, List<int> fileBytes, String fileName, {Map<String, String>? fields}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));

    try {
      final streamedResponse = await request.send().timeout(_multipartTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw NetworkException('Connection failed. Check your network.');
    }
  }
}

class _CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  _CachedResponse(this.data, this.timestamp);
}
