import 'package:dio/dio.dart';

import 'package:my_first_app/core/api/api_exception.dart';

/// HTTP API 客户端。
///
/// 底层基于社区标准网络库 `dio`，本类只做项目级的统一封装：
/// - 统一拼接 baseUrl 与超时时间
/// - 通过拦截器在每次请求前注入登录 token（等价于 axios 的请求拦截器）
/// - 把 dio 的 [DioException] 统一翻译成项目自己的 [ApiException]
///
/// `dio` 的能力（拦截器链、取消、重试、日志）都可以通过 [dio] 实例扩展，
/// 业务层永远只面向本类的方法，不直接接触 dio 类型。
class ApiClient {
  final Dio dio;

  /// 登录 token 提供者。
  ///
  /// 每次请求前回调一次，返回 `null` 表示当前未登录、不带 Authorization 头。
  /// 用回调而不是直接存 token 字符串，是因为 token 会在登录/退出时变化，
  /// 回调可以保证每次请求都拿到最新值（类似 axios 拦截器里读 store）。
  final Future<String?> Function()? tokenProvider;

  ApiClient({
    required String baseUrl,
    HttpClientAdapter? adapter,
    this.tokenProvider,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
         ),
       ) {
    // 测试时通过自定义 adapter 替换真实网络传输层。
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (tokenProvider != null) {
            final String? token = await tokenProvider!();

            if (token != null && token.isNotEmpty) {
              // 后端鉴权方式为 HTTP Bearer，格式固定为 `Bearer <token>`。
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
      ),
    );
  }

  /// 发起 GET 请求并返回解析后的 JSON。
  ///
  /// [path] 是相对于 baseUrl 的路径，例如 `/api/user/me`。
  /// [queryParameters] 会以 query string 拼接到 URL 末尾。
  /// [headers] 是本次请求的附加请求头，例如登录接口的 `X-Client-Id`。
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }

  /// 发起 POST 请求并返回解析后的 JSON。
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
    );
  }

  /// 发起 PUT 请求并返回解析后的 JSON。
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => dio.put<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
    );
  }

  /// 发起 DELETE 请求并返回解析后的 JSON。
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _request(
      () => dio.delete<dynamic>(
        path,
        options: Options(headers: headers),
      ),
    );
  }

  /// 统一执行请求并把异常翻译成 [ApiException]。
  ///
  /// Service 层和上层状态管理只需要认识 [ApiException] 一种网络异常类型，
  /// 不需要感知 dio 的存在。
  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
    try {
      final Response<dynamic> response = await send();
      return response.data;
    } on DioException catch (e) {
      final Response<dynamic>? response = e.response;

      if (response != null) {
        throw ApiException(
          statusCode: response.statusCode,
          message: '请求失败 (${response.statusCode}): ${response.data}',
        );
      }

      final bool isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;

      throw ApiException(
        message: isTimeout ? '网络请求超时，请稍后重试' : '网络请求失败: ${e.message}',
      );
    }
  }

  /// 释放底层 HTTP 客户端资源。
  void dispose() {
    dio.close();
  }
}
