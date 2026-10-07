import 'package:my_first_app/core/api/api_exception.dart';

/// 解包后端统一响应包装 `Result<T>`。
///
/// 后端所有接口都返回 `{code, message, data}` 结构：
/// - `code == 200` 表示业务成功，返回其中的 `data`（可能为 null，如 Result<Void>）
/// - 其余情况按业务失败处理，抛出携带后端提示信息的 [ApiException]
///
/// HTTP 层的状态码处理在 [ApiClient] 里完成，
/// 这里只负责业务层的状态码，两层职责互不重叠。
dynamic parseResultData(dynamic response) {
  if (response is! Map<String, dynamic>) {
    throw FormatException('接口返回格式异常，期望对象，实际: ${response.runtimeType}');
  }

  final dynamic code = response['code'];

  if (code != 200) {
    throw ApiException(
      statusCode: code is int ? code : null,
      message: response['message'] as String? ?? '请求失败',
    );
  }

  return response['data'];
}
