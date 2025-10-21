import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Lightweight, testable wrapper around the Admin Host HTTP API.
/// - Reuses a single http.Client
/// - Adds timeouts and clear error messages
/// - Normalizes baseUrl (e.g., "http://192.168.1.10:8080")
class ApiNetwork {
  final String baseUrl; // e.g. "http://192.168.1.10:8080"
  final http.Client _client;
  final Duration timeout;

  ApiNetwork(
    String baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : baseUrl = _normalizeBase(baseUrl),
       _client = client ?? http.Client();

  /// Always call this when you’re done (e.g., on dispose).
  void close() => _client.close();

  // ------------------- Public endpoints -------------------

  /// GET /health -> { ok: true }
  Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse('$baseUrl/health');
    final res = await _client.get(uri).timeout(timeout);
    return _decodeJsonOrThrow(res, expectOk: true);
  }

  /// POST /joinMeeting
  /// body: { token?: string, mid: string, deviceFingerprintHash?: string }
  /// returns: { meeting, passId, agenda: [...] }
  Future<Map<String, dynamic>> joinMeeting(Map<String, dynamic> body) async {
    return _postJson('/joinMeeting', body);
  }

  /// POST /ticket (idempotent creation)
  /// body: { passId: string, sessionId: string, deviceFingerprintHash?: string }
  /// returns: { ticketId, sessionId, byPassId }
  Future<Map<String, dynamic>> issueTicket(Map<String, dynamic> body) async {
    return _postJson('/ticket', body);
  }

  /// POST /vote
  /// body: { ticketId, sessionId, questionId, selectedOptionIds: [] }
  /// returns: { ok: true }
  Future<Map<String, dynamic>> sendVote(Map<String, dynamic> body) async {
    return _postJson('/vote', body);
  }

  /// Helper to construct the websocket URL for a meeting.
  /// Example: ws://192.168.1.10:8080/ws?mid=<meetingId>
  Uri wsUri(String meetingId) {
    final isHttps = baseUrl.startsWith('https://');
    final scheme = isHttps ? 'wss' : 'ws';
    final u = Uri.parse(baseUrl);
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.port,
      path: '/ws',
      queryParameters: {'mid': meetingId},
    );
  }

  // ------------------- Internal helpers -------------------

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _client
        .post(
          uri,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decodeJsonOrThrow(res, expectOk: true);
  }

  static Map<String, dynamic> _decodeJsonOrThrow(
    http.Response res, {
    required bool expectOk,
  }) {
    Map<String, dynamic> json;
    try {
      json =
          res.body.isEmpty
              ? <String, dynamic>{}
              : (jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Invalid JSON from server',
        rawBody: res.body,
      );
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        statusCode: res.statusCode,
        message: json['error']?.toString() ?? 'HTTP ${res.statusCode}',
        rawBody: res.body,
      );
    }

    // Some endpoints return 200 with {error: ...}—treat that as an error too.
    if (expectOk && json.containsKey('error')) {
      throw ApiException(
        statusCode: res.statusCode,
        message: json['error']?.toString() ?? 'Server error',
        rawBody: res.body,
      );
    }

    return json;
  }

  static String _normalizeBase(String base) {
    var b = base.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }
}

/// A simple error to bubble up to UI.
///
/// Example handling:
/// try { ... } on ApiException catch (e) {
///   showSnackbar('Network error: ${e.message}');
/// }
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? rawBody;

  ApiException({required this.statusCode, required this.message, this.rawBody});

  @override
  String toString() =>
      'ApiException($statusCode): $message${rawBody != null ? ' | $rawBody' : ''}';
}
