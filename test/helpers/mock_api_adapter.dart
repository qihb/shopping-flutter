import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// dio 的测试用 Mock 适配器：记录请求并按用例定义返回响应。
///
/// dio 发送请求最终都会经过 [HttpClientAdapter]，
/// 实现它即可拦截真实网络，等价于 `http` 包测试里的 MockClient。
class CapturingMockAdapter implements HttpClientAdapter {
  CapturingMockAdapter({required this.responder});

  /// 由每个用例决定返回什么响应体。
  final ResponseBody Function(RequestOptions options) responder;

  /// 所有被拦截的请求，按发起顺序记录。
  final List<RequestOptions> captured = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

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
