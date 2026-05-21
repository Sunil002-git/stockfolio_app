import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import '../providers/auth_provider.dart';

class ApiService {
  late final Dio _dio;
  final AuthProvider _auth;

  ApiService(this._auth) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {"content-Type": "application/json"},
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _auth.accessToken;
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        // Response interceptor
        // Runs after EVERY API response.
        // On 401 (Unauthorized): token has expired.
        //   → Silently calls /api/token/refresh/
        //   → Saves new access token
        //   → Retries the original request
        //   → User never sees an error
        // On any other error: just pass it through.
        // Equivalent to the response interceptor in api.js.
        onError: (DioException error, handler) async {
          final is401 = error.response?.statusCode == 401;
          final isRefreshPath = error.requestOptions.path.contains(
            "token/refresh",
          );
          final isLoginPath = error.requestOptions.path.contains("login");

          if (is401 && !isRefreshPath && !isLoginPath) {
            final refreshToken = _auth.refreshToken;

            if (refreshToken == null) {
              await _auth.logout();
              return handler.next(error);
            }
            try {
              // Silent refresh
              debugPrint("[ApiService] Access token expired. Refreshing...");
              final refreshRes = await _dio.post(
                "token/refresh/",
                data: {"refresh": refreshToken},
              );

              final newToken = refreshRes.data["access"] as String;
              await _auth.updateAccessToken(newToken);
              debugPrint("[ApiService] Token refreshed successfully.");

              // Retry the original request with new token
              final opts = error.requestOptions;
              opts.headers["Authorization"] = "Bearer $newToken";
              final retryRes = await _dio.fetch(opts);
              return handler.resolve(retryRes);
            } catch (e) {
              debugPrint("[ApiService] Refresh failed. Logging out.");
              await _auth.logout();
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ── Convenience methods ──────────────────────────────────────
  // These wrap _dio so callers write api.get() not api._dio.get()
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);
  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);
  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);
  Future<Response<T>> delete<T>(String path) => 
  _dio.delete<T>(path);
}
