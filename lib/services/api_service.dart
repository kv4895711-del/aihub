  /// API service: talks to the FreeLLMAPI gateway (OpenAI-compatible).
  library api_service;

  import 'dart:async';
  import 'dart:convert';
  import 'package:http/http.dart' as http;

  /// A single chat turn sent to the API.
  class ApiMessage {
    final String role;
    final String content;

    const ApiMessage({required this.role, required this.content});
                                                                                                         Map<String, String> toJson() => {'role': role, 'content': content};
  }

  /// Result of a test connection.
  class TestResult {
    final bool ok;
    final String message;

    const TestResult({required this.ok, required this.message});
  }

  /// Exception for API errors with a friendly message.
  class ApiException implements Exception {
    final String message;
    final int? statusCode;

    const ApiException(this.message, {this.statusCode});

    @override
    String toString() => message;                                                                      }

  /// Talks to the gateway. Never logs the API key.
  class ApiService {                                                                                     final String Function() baseUrlProvider;
    final String? Function() apiKeyProvider;

    ApiService({
      required this.baseUrlProvider,
      required this.apiKeyProvider,
    });

    String get _baseUrl {
      var url = baseUrlProvider().trim();
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }

    Map<String, String> _headers() {
      final key = apiKeyProvider()?.trim() ?? '';
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (key.isNotEmpty) 'Authorization': 'Bearer $key',
      };
    }

    /// Maps HTTP status codes to friendly messages.
    static ApiException _friendlyError(int status, String body) {
      switch (status) {                                                                                      case 401:
          return const ApiException(                                                                             'Invalid API key (401). Check your key in Settings.',
            statusCode: 401,
          );
        case 403:
          return const ApiException(                                                                             'Access denied (403). Your key may not be allowed for this model.',
            statusCode: 403,
          );
        case 429:
          return const ApiException(
            'Rate limit reached (429). Free providers have limits — wait a moment and try again.',               statusCode: 429,
          );
        case 404:
          return const ApiException(                                                                             'Not found (404). Check your Gateway URL in Settings.',
            statusCode: 404,
          );                                                                                                 default:
          if (status >= 500) {
            return ApiException(
              'Gateway error ($status). The model provider may be down.',
              statusCode: status,
            );
          }
          return ApiException(
            'Request failed ($status).',
            statusCode: status,                                                                                );
      }                                                                                                  }

    static ApiException _networkError(Object e) {
      return ApiException(
        'Cannot reach the gateway. Make sure FreeLLMAPI is running in Termux. ($e)',
      );
    }

    /// Test connection: GET /models with the key.
    Future<TestResult> testConnection() async {
      final client = http.Client();
      try {                                                                                                  final resp = await client
            .get(Uri.parse('$_baseUrl/models'), headers: _headers())
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return const TestResult(ok: true, message: 'Connected! Gateway is reachable.');
        }
        return TestResult(
          ok: false,
          message: _friendlyError(resp.statusCode, resp.body).message,
        );
      } catch (e) {
        return TestResult(ok: false, message: _networkError(e).message);
      } finally {
        client.close();
      }
    }

    /// Fetch available model ids from GET /models.
    Future<List<String>> fetchModels() async {
      final client = http.Client();
      try {
        final resp = await client
            .get(Uri.parse('$_baseUrl/models'), headers: _headers())
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode < 200 || resp.statusCode >= 300) {                                                 throw _friendlyError(resp.statusCode, resp.body);
        }                                                                                                    final decoded = jsonDecode(resp.body);
        final list = (decoded is Map ? (decoded['data'] ?? []) : decoded) as List;
        final ids = <String>[];
        for (final item in list) {
          if (item is Map && item['id'] is String) {
            ids.add(item['id'] as String);
          }
        }
        ids.sort();                                                                                          return ids;
      } on ApiException {
        rethrow;
      } on TimeoutException {
        throw const ApiException('The request timed out. Is the gateway busy or offline?');
      } catch (e) {                                                                                          throw _networkError(e);
      } finally {
        client.close();
      }
    }

    /// Non-streaming chat completion.
    Future<String> complete({
      required String model,
      required List<ApiMessage> messages,
      int maxTokens = 2048,
    }) async {
      final client = http.Client();
      try {
        final resp = await client
            .post(
              Uri.parse('$_baseUrl/chat/completions'),
              headers: _headers(),
              body: jsonEncode({
                'model': model,
                'messages': messages.map((m) => m.toJson()).toList(),
                'stream': false,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(const Duration(seconds: 120));
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw _friendlyError(resp.statusCode, resp.body);
        }
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;                                       final choices = decoded['choices'] as List? ?? [];
        if (choices.isEmpty) {
          throw const ApiException('The model returned an empty response.');
        }
        final message = (choices.first as Map)['message'] as Map? ?? {};                                     final content = (message['content'] as String?)?.trim() ?? '';
        if (content.isEmpty) {
          throw const ApiException('The model returned an empty response.');
        }
        return content;
      } on ApiException {
        rethrow;
      } on TimeoutException {
        throw const ApiException('The response timed out. Try again or pick another model.');
      } catch (e) {
        throw _networkError(e);
      } finally {
        client.close();
      }
    }

    /// Streaming chat completion. Calls [onToken] for each text chunk.
    /// Throws [ApiException] on failure (caller may fall back to [complete]).
    Future<void> stream({
      required String model,
      required List<ApiMessage> messages,
      required void Function(String token) onToken,
      int maxTokens = 2048,                                                                                Future<void>? cancelSignal,
    }) async {
      try {
        final request = http.Request(                                                                          'POST',
          Uri.parse('$_baseUrl/chat/completions'),
        );
        request.headers.addAll(_headers());                                                                  request.body = jsonEncode({
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,                                                                                      'max_tokens': maxTokens,
        });
                                                                                                             final resp = await client.send(request).timeout(
              const Duration(seconds: 60),
            );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          final body = await resp.stream.bytesToString();                                                      throw _friendlyError(resp.statusCode, body);
        }

        final completer = Completer<void>();
        final buffer = StringBuffer();
        late final StreamSubscription<String> sub;

        void processLine(String line) {
          if (!line.startsWith('data: ')) return;
          final data = line.substring(6).trim();
          if (data.isEmpty || data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List? ?? [];
            if (choices.isEmpty) return;
            final delta = (choices.first as Map)['delta'] as Map? ?? {};
            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              onToken(content);
            }
          } catch (_) {
            // Ignore malformed chunks (keep-alives etc).
          }
        }

        sub = resp.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            processLine(line);
            buffer.write(line);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },                                                                                                   onError: (Object e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          cancelOnError: true,
        );

        if (cancelSignal != null) {
          // Allow caller to abort by completing cancelSignal.
          cancelSignal.then((_) {
            sub.cancel();
            if (!completer.isCompleted) completer.complete();
          });
        }

        await completer.future.timeout(const Duration(minutes: 3));
      } on ApiException {
        rethrow;
      } on TimeoutException {
        throw const ApiException('Streaming timed out. Try again or pick another model.');
      } catch (e) {
        throw _networkError(e);
      } finally {
        client.close();
      }
    }
  }
