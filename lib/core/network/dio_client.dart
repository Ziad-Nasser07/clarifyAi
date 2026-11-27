import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  final Dio dio;

  DioClient()
      : dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final isGeminiRequest =
          err.requestOptions.uri.host.contains('generativelanguage.googleapis.com');
          final statusCode = err.response?.statusCode;
          final isTransientError = statusCode == 503 ||
              statusCode == 429 ||
              err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout;

          if (isGeminiRequest && isTransientError) {
            final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
            const maxRetries = 2;

            if (retryCount < maxRetries) {
              final nextRetry = retryCount + 1;
              err.requestOptions.extra['retryCount'] = nextRetry;

              // انتظار سريع: 1.5 ثانية ثم 3 ثوانٍ قبل التحويل التلقائي إلى Groq
              final delayMs = nextRetry * 1500;
              debugPrint(
                'Gemini busy ($statusCode). Auto-retrying ($nextRetry/$maxRetries) in ${delayMs}ms...',
              );
              await Future.delayed(Duration(milliseconds: delayMs));

              try {
                final response = await dio.fetch(err.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }
          return handler.next(err);
        },
      ),
    );
  }
}