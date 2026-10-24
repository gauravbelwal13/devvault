import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/api_test_result.dart';
import 'vault_providers.dart';

class ApiTestState {
  const ApiTestState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  final bool isLoading;
  final ApiTestResult? result;
  final String? error;

  ApiTestState copyWith({
    bool? isLoading,
    ApiTestResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ApiTestState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ApiTestNotifier extends StateNotifier<ApiTestState> {
  ApiTestNotifier(
    this.ref,
    this.itemId,
  ) : super(const ApiTestState());

  final Ref ref;
  final String itemId;

  Future<void> send({
    required String method,
    required String url,
    String? headers,
    String? queryParameters,
    String? body,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final result = await ref.read(testApiRequestProvider).call(
            method: method,
            url: url,
            headers: _parseJsonMap(headers),
            queryParameters: _parseJsonMap(queryParameters),
            body: body,
          );

      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const ApiTestState();
  }

  Map<String, String> _parseJsonMap(String? value) {
    if (value == null || value.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(value);

    if (decoded is! Map) {
      return {};
    }

    return decoded.map(
      (key, value) => MapEntry(
        key.toString(),
        value.toString(),
      ),
    );
  }
}

final apiTestProvider = StateNotifierProvider.family<
    ApiTestNotifier,
    ApiTestState,
    String>(
  (ref, itemId) => ApiTestNotifier(
    ref,
    itemId,
  ),
);