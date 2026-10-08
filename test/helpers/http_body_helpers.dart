import 'dart:convert';

import 'package:dio/dio.dart';

/// 读取请求体：dio 在 JSON 场景下可能给 Map，也可能给已编码的字符串。
Map<String, dynamic> decodedJsonBody(RequestOptions options) {
  final dynamic data = options.data;

  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is String && data.isNotEmpty) {
    return jsonDecode(data) as Map<String, dynamic>;
  }

  return <String, dynamic>{};
}

/// 构造一个业务成功的 JSON 响应体。
ResponseBody jsonResponseBody(
  Map<String, dynamic> body, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}
