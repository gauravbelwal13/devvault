import '../entities/api_test_result.dart';

abstract class ApiTestRepository {
  Future<ApiTestResult> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers,
    Map<String, String> queryParameters,
    String? body,
  });
}