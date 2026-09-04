import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final http.Client client;

  // Option 1: Live Render URL set as default
  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? 'https://origin-2.onrender.com/', // Replace with your exact Render backend URL
        client = client ?? http.Client();

  Future<TraceResult> trace(String id) async =>
      TraceResult.fromJson(await _get('/trace/${Uri.encodeComponent(id)}'));

  Future<List<TraceResult>> traceDate(String date) async {
    final j = await _post('/trace/query', {'date': date});
    return (j['results'] as List? ?? [])
        .map((x) => TraceResult.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<Map<String, dynamic>> analytics() => _get('/analytics/summary');

  Future<List<Transaction>> transactions({String? status}) async {
    final j = await _get(
      '/transactions',
      params: {
        'page': '1',
        'page_size': '100',
        if (status != null) 'status': status,
      },
    );
    return (j['items'] as List? ?? [])
        .map((x) => Transaction.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: (params != null && params.isNotEmpty) ? params : null,
      );
      final r = await client.get(uri).timeout(const Duration(seconds: 15));
      return _decode(r);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Could not reach backend at $baseUrl. Check backend connection.',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final r = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _decode(r);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Request timed out or backend at $baseUrl is unavailable.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response r) {
    dynamic b;
    try {
      b = jsonDecode(r.body);
    } catch (_) {
      b = {};
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(
        b is Map && b['detail'] != null
            ? b['detail'].toString()
            : 'Backend error (${r.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(b);
  }
}
