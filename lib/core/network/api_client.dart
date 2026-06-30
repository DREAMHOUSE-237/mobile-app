import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EXCEPTIONS RÉSEAU — Équivalent de la gestion d'erreurs d'axios
// ══════════════════════════════════════════════════════════════════════════════
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  // Cas courants
  bool get isUnauthorized  => statusCode == 401;
  bool get isForbidden     => statusCode == 403;
  bool get isNotFound      => statusCode == 404;
  bool get isServerError   => statusCode != null && statusCode! >= 500;
  bool get isNetworkError  => statusCode == null;
}

// ══════════════════════════════════════════════════════════════════════════════
// DIO CLIENT — Équivalent de l'instance axios avec intercepteurs
// ══════════════════════════════════════════════════════════════════════════════
class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    final baseUrl = dotenv.env['API_URL'] ?? '';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      _LoggingInterceptor(),
    ]);
  }

  // ── GET ──────────────────────────────────────────────────────────────────────
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST ─────────────────────────────────────────────────────────────────────
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PUT ──────────────────────────────────────────────────────────────────────
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH
  Future<dynamic> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── MULTIPART (upload images + docs) ────────────────────────────────────────
  Future<dynamic> postMultipart(
    String path,
    FormData formData, {
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            ...?extraHeaders,
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> putMultipart(String path, FormData formData) async {
    try {
      final response = await _dio.put(
        path,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GESTION ERREURS ──────────────────────────────────────────────────────────
  ApiException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Délai de connexion dépassé. Vérifiez votre connexion.',
        statusCode: null,
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Impossible de se connecter. Vérifiez votre connexion Internet.',
        statusCode: null,
      );
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    final message = _extractMessage(responseData, statusCode);
    return ApiException(
      message: message,
      statusCode: statusCode,
      data: responseData,
    );
  }

  String _extractMessage(dynamic data, int? code) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['detail']?.toString() ??
          data['message']?.toString() ??
          _defaultMessage(code);
    }
    return _defaultMessage(code);
  }

  String _defaultMessage(int? code) {
    switch (code) {
      case 400: return 'Données invalides.';
      case 401: return 'Identifiants incorrects ou session expirée.';
      case 403: return 'Accès refusé.';
      case 404: return 'Ressource introuvable.';
      case 500: return 'Erreur serveur. Réessayez plus tard.';
      default:  return 'Une erreur inattendue est survenue.';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERCEPTEUR AUTH — Injecte automatiquement le token JWT
// Équivalent de l'intercepteur axios dans auth_service.js
// ══════════════════════════════════════════════════════════════════════════════
class _AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Headers nécessaires pour le Commentary Service (X-User-Id, X-User-Email)
    final userId    = await _storage.getUserUuid(); // UUID microservices
    final userEmail = await _storage.getUserEmail();
    if (userId != null)    options.headers['X-User-Id']    = userId;
    if (userEmail != null) options.headers['X-User-Email'] = userEmail;

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expiré → supprimer session
      await _storage.clearAll();
    }
    handler.next(err);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERCEPTEUR LOGGING — Debug uniquement
// ══════════════════════════════════════════════════════════════════════════════
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('🌐 [DH] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('✅ [DH] ${response.statusCode} ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('❌ [DH] ${err.response?.statusCode} ${err.requestOptions.path}');
      return true;
    }());
    handler.next(err);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER RIVERPOD — Injection de dépendance du client HTTP
// ══════════════════════════════════════════════════════════════════════════════
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});
