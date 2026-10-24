import 'package:http/http.dart' as http;

import '../../domain/entities/api_test_result.dart';

class ApiTestDatasource {
  ApiTestDatasource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiTestResult> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    String? body,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final stopwatch = Stopwatch()..start();

    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(
            uri,
            headers: headers,
          );
          break;

        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body,
          );
          break;

        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body,
          );
          break;

        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: body,
          );
          break;

        case 'DELETE':
          response = await _client.delete(
            uri,
            headers: headers,
            body: body,
          );
          break;

        case 'HEAD':
          response = await _client.head(
            uri,
            headers: headers,
          );
          break;

        default:
          throw UnsupportedError(
            'HTTP method "$method" is not supported.',
          );
      }

      stopwatch.stop();

      return ApiTestResult(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase ?? '',
        headers: response.headers,
        body: response.body,
        responseTime: stopwatch.elapsed,
      );
    } catch (_) {
      stopwatch.stop();
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}