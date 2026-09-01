import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

/// Thrown for any non-2xx response or an `{ "success": false }` envelope.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.errorCode});

  final int statusCode;
  final String message;
  final String? errorCode;

  bool get isConflict => statusCode == 409;
  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Minimal REST client for coffee-meet-api. Attaches the Firebase ID token as
/// a Bearer header and unwraps the API's `{ success, data, message }`
/// envelope, surfacing failures as [ApiException].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final Duration timeout;
  final http.Client _http;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  /// GET where the response envelope's `data` is a JSON array
  /// (the "list" endpoints — `/coffee-shops/nearby`, `/meetings/upcoming`, …).
  Future<List<dynamic>> getList(String path) async {
    final envelope = await _sendRaw('GET', path);
    final data = envelope['data'];
    return data is List ? data : const [];
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final envelope = await _sendRaw(method, path, body: body);
    final data = envelope['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Runs the request and returns the full decoded envelope, throwing
  /// [ApiException] for any non-2xx or `{ "success": false }` response.
  Future<Map<String, dynamic>> _sendRaw(
    String method,
    String path, {
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await tokenProvider();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      final future = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: encodedBody),
        'PUT' => _http.put(uri, headers: headers, body: encodedBody),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };
      response = await future.timeout(timeout);
    } on TimeoutException {
      throw ApiException(0, 'The request timed out. Check your connection.');
    } catch (_) {
      throw ApiException(
          0, "Couldn't reach Coffee Meet. Check your connection.");
    }

    return _parseRaw(response);
  }

  /// Multipart upload of a single file field (`fieldName`) at [path].
  Future<Map<String, dynamic>> upload(
    String path, {
    required String fieldName,
    required String filePath,
  }) async {
    final token = await tokenProvider();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..files.add(await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        // The `http` package's own mime guess is unreliable (often
        // application/octet-stream), which the API rejects — derive it from
        // the extension ourselves and default to JPEG.
        contentType: _imageMediaType(filePath),
      ));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(0, 'The upload timed out. Check your connection.');
    } catch (_) {
      throw ApiException(
          0, "Couldn't reach Coffee Meet. Check your connection.");
    }

    return _parse(response);
  }

  MediaType _imageMediaType(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
      case 'heif':
        return MediaType('image', 'heic');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Used by [upload] — same contract as [get]/[post]: the envelope's `data`
  /// object, or `{}`.
  Map<String, dynamic> _parse(http.Response response) {
    final envelope = _parseRaw(response);
    final data = envelope['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Map<String, dynamic> _parseRaw(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = const {};
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && decoded['success'] == true) {
      return decoded;
    }

    throw ApiException(
      response.statusCode,
      _messageFrom(decoded) ?? 'Something went wrong. Please try again.',
      errorCode: decoded['errorCode'] as String?,
    );
  }

  String? _messageFrom(Map<String, dynamic> decoded) {
    final message = decoded['message'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return null;
  }

  void close() => _http.close();
}
