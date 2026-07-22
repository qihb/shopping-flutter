import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:my_first_app/core/api/api_exception.dart';

/// HTTP API 客户端。
///
/// 它把 `http` 包的使用细节封装起来：
/// - 统一拼接 baseUrl
/// - 统一设置请求头
/// - 统一处理 HTTP 状态码和异常
///
/// 构造函数接受可选的 `http.Client`，方便测试时注入 Mock Client。
/// 这和前端里 axios/fetch 封装层的思路是一致的。
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 发起 GET 请求并返回解析后的 JSON。
  ///
  /// [path] 是相对于 baseUrl 的路径，例如 `/products`。
  /// [queryParameters] 会以 query string 拼接到 URL 末尾。
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    try {
      final http.Response response = await _client.get(
        uri,
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }

      throw ApiException(message: '网络请求失败: $e');
    }
  }

  /// 发起 POST 请求并返回解析后的 JSON。
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');

    try {
      final http.Response response = await _client.post(
        uri,
        headers: _defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }

      throw ApiException(message: '网络请求失败: $e');
    }
  }

  /// 释放底层 HTTP 客户端资源。
  void dispose() {
    _client.close();
  }

  Map<String, String> get _defaultHeaders => <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: '请求失败 (${response.statusCode}): ${response.body}',
    );
  }
}
