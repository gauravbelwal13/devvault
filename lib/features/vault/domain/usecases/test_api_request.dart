import '../entities/api_test_result.dart';
import '../repositories/api_test_repository.dart';

class TestApiRequest {
  TestApiRequest(this._repository);

  final ApiTestRepository _repository;

  Future<ApiTestResult> call({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    String? body,
  }) {
    return _repository.sendRequest(
      method: method,
      url: url,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
}