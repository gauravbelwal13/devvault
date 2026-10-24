import '../../domain/entities/api_test_result.dart';
import '../../domain/repositories/api_test_repository.dart';
import '../datasources/api_test_datasource.dart';

class ApiTestRepositoryImpl implements ApiTestRepository {
  ApiTestRepositoryImpl(this._datasource);

  final ApiTestDatasource _datasource;

  @override
  Future<ApiTestResult> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    String? body,
  }) {
    return _datasource.sendRequest(
      method: method,
      url: url,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
}