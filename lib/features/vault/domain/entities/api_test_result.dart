class ApiTestResult {
  const ApiTestResult({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    required this.responseTime,
  });

  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final String body;
  final Duration responseTime;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  bool get isClientError => statusCode >= 400 && statusCode < 500;

  bool get isServerError => statusCode >= 500;
}