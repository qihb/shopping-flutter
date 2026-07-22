/// API 请求异常。
///
/// 把 HTTP 状态码和错误信息封装成 Dart 异常，
/// 方便调用方统一 catch 和处理。
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
