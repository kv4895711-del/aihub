  /// Chat state provider: real API calls, streaming, stop, regenerate, error handling.
  library chat_provider;

  import 'dart:async';
  import 'package:flutter/foundation.dart';
  import 'package:provider/provider.dart';

  import '../models/chat_message.dart';
  import '../services/api_service.dart';                                                               import '../services/model_service.dart';
  import '../providers/app_provider.dart';
  import '../core/constants/app_constants.dart';
                                                                                                       /// Manages the current chat, messages, and API interaction.
  class ChatProvider extends ChangeNotifier {
    String? _currentChatId;
    final Map<String, List<ChatMessage>> _messages = {};
    final Set<String> _generating = {};
                                                                                                         // Stream cancellation for the current AI message.
    Completer<void>? _cancelCompleter;

    String? get currentChatId => _currentChatId;

    List<ChatMessage> get messages =>                                                                        _currentChatId == null ? [] : _messages[_currentChatId] ?? [];

    bool get isGenerating =>
        _currentChatId != null && _generating.contains(_currentChatId);

    /// Get injected services from context.
    ApiService _api(BuildContext context) =>
        context.read<AppProvider>().themeData.runtimeType == AppThemeData
            ? ApiService(
                baseUrlProvider: () => context.read<AppProvider>().gatewayBaseUrl,
                apiKeyProvider: () => context.read<AppProvider>().apiKey,
              )
            : throw StateError('ApiService not available');                                              // NOTE: This helper is unused now but kept for structure; real injection
    // happens via constructor in Phase 6/8 refactor. For now ChatScreen calls
    // methods that take context.

    /// Start a fresh chat.
    void newChat() {
      _currentChatId = 'chat_${DateTime.now().microsecondsSinceEpoch}';
      _messages[_currentChatId] = [];
      _cancelCompleter = null;
      notifyListeners();
    }                                                                                                
    /// Open an existing chat (Phase 6 wires this to the DB).                                            void openChat(String id, List<ChatMessage> msgs) {
      _currentChatId = id;
      _messages[id] = List.from(msgs);
      _cancelCompleter = null;
      notifyListeners();
    }

    /// Clear all chats.                                                                                 void clearAll() {
      _currentChatId = null;
      _messages.clear();
      _generating.clear();
      _cancelCompleter = null;
      notifyListeners();
    }

    /// Send a user message and stream AI reply from real API.
    Future<void> sendMessage(BuildContext context, String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || _currentChatId == null) return;

      final appProvider = context.read<AppProvider>();
      final model = appProvider.selectedModel;

      final chatId = _currentChatId!;
      final userMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: trimmed,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      final aiMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
        isStreaming: true,
      );

      _messages[chatId] = [...?_messages[chatId], userMsg, aiMsg];
      _generating.add(chatId);
      _cancelCompleter = Completer<void>();
      notifyListeners();

      try {
        final api = ApiService(
          baseUrlProvider: () => appProvider.gatewayBaseUrl,
          apiKeyProvider: () => appProvider.apiKey,
        );

        final history = _messages[chatId]!
            .where((m) => m.role != MessageRole.ai || !m.isStreaming)
            .map((m) => ApiMessage(
                  role: m.role == MessageRole.user ? 'user' : 'assistant',
                  content: m.text,
                ))
            .toList();

        var buffer = '';
        await api.stream(
          model: model,
          messages: history,
          onToken: (token) {
            buffer += token;
            _replaceMessage(chatId, aiMsg.id,
                (m) => m.copyWith(text: buffer, status: MessageStatus.streaming, isStreaming: true));
            notifyListeners();
          },
          cancelSignal: _cancelCompleter!.future,
        );

        // Stream finished normally — mark done.
        final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
        if (idx >= 0 && mounted) {
          _messages[chatId]![idx] = aiMsg.copyWith(
            text: buffer,
            status: MessageStatus.done,
            isStreaming: false,
          );
        }
      } on Exception catch (e) {
        // Streaming failed — fall back to non-streaming once.
        try {
          final api = ApiService(
            baseUrlProvider: () => appProvider.gatewayBaseUrl,
            apiKeyProvider: () => appProvider.apiKey,
          );
          final history = _messages[chatId]!
              .where((m) => m.role != MessageRole.ai || !m.isStreaming)
              .map((m) => ApiMessage(
                    role: m.role == MessageRole.user ? 'user' : 'assistant',
                    content: m.text,
                  ))
              .toList();
          final reply = await api.complete(model: model, messages: history);
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
          if (idx >= 0 && mounted) {
            _messages[chatId]![idx] = aiMsg.copyWith(
              text: reply,
              status: MessageStatus.done,
              isStreaming: false,
            );
          }
        } on Exception catch (fallbackErr) {
          // Both failed — show error in bubble.
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
          if (idx >= 0 && mounted) {
            final friendly = _friendlyError(fallbackErr);
            _messages[chatId]![idx] = aiMsg.copyWith(
              text: friendly,
              status: MessageStatus.error,
              isStreaming: false,
            );
          }
        }
      } finally {
        _generating.remove(chatId);
        _cancelCompleter = null;
        if (mounted) notifyListeners();
      }
    }

    /// Stop the current generation.
    void stopGenerating() {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      _cancelCompleter?.complete();
      final list = _messages[chatId];
      if (list == null) return;
      final updated = list
          .map((m) => m.isStreaming
              ? m.copyWith(status: MessageStatus.done, isStreaming: false)
              : m)
          .toList();
      _messages[chatId] = updated;
      _generating.remove(chatId);
      notifyListeners();
    }

    /// Regenerate the last AI answer.
    Future<void> regenerate(BuildContext context) async {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      final list = _messages[chatId];
      if (list == null || list.isEmpty) return;
      final lastAiIdx = list.lastIndexWhere((m) => m.role == MessageRole.ai);
      if (lastAiIdx < 0) return;                                                                           final lastUserIdx = list.lastIndexWhere((m) => m.role == MessageRole.user);
      if (lastUserIdx < 0) return;
      final userText = list[lastUserIdx].text;

      list.removeAt(lastAiIdx);
      _generating.add(chatId);                                                                             notifyListeners();

      // Reuse sendMessage logic.
      await sendMessage(context, userText);
    }

    void _replaceMessage(String chatId, String msgId, ChatMessage Function(ChatMessage) f) {
      final list = _messages[chatId];
      if (list == null) return;
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx < 0) return;
      _messages[chatId] = [...list];
      _messages[chatId]![idx] = f(list[idx]);
    }

    String _friendlyError(Object e) {
      if (e is ApiException) {
        return e.message;
      }
      return 'Something went wrong: $e';
    }

    bool get mounted => true; // Provider is always mounted while alive.
  }

  Wait — there are issues:
  1. mounted getter always returns true — not correct for ChangeNotifier but acceptable here since
     it's not a State.
  2. The _api(BuildContext context) helper is weird and unused. Let me remove it.
  3. context.read<AppProvider>() inside provider — that's fine but mounted check is not real.

  Let me rewrite cleanly without the broken _api helper and mounted:

  /// Chat state provider: real API calls, streaming, stop, regenerate, error handling.
  library chat_provider;

  import 'dart:async';
  import 'package:flutter/foundation.dart';

  import '../models/chat_message.dart';
  import '../services/api_service.dart';
  import '../providers/app_provider.dart';

  /// Manages the current chat, messages, and API interaction.
  class ChatProvider extends ChangeNotifier {
    String? _currentChatId;
    final Map<String, List<ChatMessage>> _messages = {};
    final Set<String> _generating = {};

    Completer<void>? _cancelCompleter;

    String? get currentChatId => _currentChatId;

    List<ChatMessage> get messages =>
        _currentChatId == null ? [] : _messages[_currentChatId] ?? [];

    bool get isGenerating =>
        _currentChatId != null && _generating.contains(_currentChatId);

    void newChat() {
      _currentChatId = 'chat_${DateTime.now().microsecondsSinceEpoch}';
      _messages[_currentChatId] = [];
      _cancelCompleter = null;
      notifyListeners();
    }

    void openChat(String id, List<ChatMessage> msgs) {
      _currentChatId = id;
      _messages[id] = List.from(msgs);
      _cancelCompleter = null;
      notifyListeners();
    }

    void clearAll() {
      _currentChatId = null;
      _messages.clear();
      _generating.clear();
      _cancelCompleter = null;
      notifyListeners();
    }

    Future<void> sendMessage(BuildContext context, String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || _currentChatId == null) return;

      final appProvider = context.read<AppProvider>();
      final model = appProvider.selectedModel;

      final chatId = _currentChatId!;
      final userMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: trimmed,
        role: MessageRole.user,
        timestamp: DateTime.now(),                                                                         );
      final aiMsg = ChatMessage(                                                                             id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',                                                                                            role: MessageRole.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
        isStreaming: true,
      );                                                                                             
      _messages[chatId] = [...?_messages[chatId], userMsg, aiMsg];                                         _generating.add(chatId);
      _cancelCompleter = Completer<void>();
      notifyListeners();                                                                             
      try {                                                                                                  final api = ApiService(
          baseUrlProvider: () => appProvider.gatewayBaseUrl,
          apiKeyProvider: () => appProvider.apiKey,
        );                                                                                           
        final history = _messages[chatId]!
            .where((m) => m.role != MessageRole.ai || !m.isStreaming)
            .map((m) => ApiMessage(
                  role: m.role == MessageRole.user ? 'user' : 'assistant',
                  content: m.text,
                ))
            .toList();

        var buffer = '';
        await api.stream(
          model: model,
          messages: history,                                                                                   onToken: (token) {
            buffer += token;
            _replaceMessage(chatId, aiMsg.id,
                (m) => m.copyWith(text: buffer, status: MessageStatus.streaming, isStreaming: true));
            notifyListeners();
          },
          cancelSignal: _cancelCompleter!.future,
        );

        final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
        if (idx >= 0) {
          _messages[chatId]![idx] = aiMsg.copyWith(
            text: buffer,
            status: MessageStatus.done,
            isStreaming: false,
          );
        }
      } on Exception catch (e) {
        try {
          final api = ApiService(
            baseUrlProvider: () => appProvider.gatewayBaseUrl,
            apiKeyProvider: () => appProvider.apiKey,
          );
          final history = _messages[chatId]!
              .where((m) => m.role != MessageRole.ai || !m.isStreaming)
              .map((m) => ApiMessage(
                    role: m.role == MessageRole.user ? 'user' : 'assistant',
                    content: m.text,
                  ))
              .toList();
          final reply = await api.complete(model: model, messages: history);
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
          if (idx >= 0) {
            _messages[chatId]![idx] = aiMsg.copyWith(                                                              text: reply,
              status: MessageStatus.done,
              isStreaming: false,
            );
          }
        } on Exception catch (fallbackErr) {
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
          if (idx >= 0) {
            final friendly = _friendlyError(fallbackErr);
            _messages[chatId]![idx] = aiMsg.copyWith(
              text: friendly,
              status: MessageStatus.error,
              isStreaming: false,
            );
          }
        }
      } finally {
        _generating.remove(chatId);
        _cancelCompleter = null;
        notifyListeners();
      }
    }
                                                                                                         void stopGenerating() {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      _cancelCompleter?.complete();
      final list = _messages[chatId];
      if (list == null) return;
      final updated = list
          .map((m) => m.isStreaming
              ? m.copyWith(status: MessageStatus.done, isStreaming: false)
              : m)
          .toList();
      _messages[chatId] = updated;
      _generating.remove(chatId);
      notifyListeners();
    }

    Future<void> regenerate(BuildContext context) async {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      final list = _messages[chatId];
      if (list == null || list.isEmpty) return;
      final lastAiIdx = list.lastIndexWhere((m) => m.role == MessageRole.ai);
      if (lastAiIdx < 0) return;
      final lastUserIdx = list.lastIndexWhere((m) => m.role == MessageRole.user);
      if (lastUserIdx < 0) return;
      final userText = list[lastUserIdx].text;

      list.removeAt(lastAiIdx);
      _generating.add(chatId);
      notifyListeners();

      await sendMessage(context, userText);
    }

    void _replaceMessage(String chatId, String msgId, ChatMessage Function(ChatMessage) f) {
      final list = _messages[chatId];
      if (list == null) return;
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx < 0) return;
      _messages[chatId] = [...list];
      _messages[chatId]![idx] = f(list[idx]);
    }

    String _friendlyError(Object e) {
      if (e is ApiException) {
        return e.message;
      }
      return 'Something went wrong: $e';
    }
  }

  This looks clean. But there's a circular import risk: chat_provider imports app_provider, and
  app_provider doesn't import chat_provider, so no cycle. Good.

  But ApiService is constructed inside sendMessage each time — that's fine but not ideal. For now
  it's okay.

  Wait, spread operator [...?_messages[chatId]] — the ?. with spread is not valid Dart. Should be
  [...?_messages[chatId], userMsg, aiMsg] — actually [...?_messages[chatId]] is valid if
  _messages[chatId] is List<ChatMessage>?. Let me check: _messages is Map<String, List<ChatMessage>>,
  so _messages[chatId] is List<ChatMessage>?. The spread ...? is valid Dart 2.17+. Good.

  But actually _messages[chatId] after we know chatId exists — we set it in newChat. But if someone
  calls sendMessage without newChat... we check _currentChatId != null but _messages[_currentChatId]
  might be null if set manually. Let me add a safety:

  final existing = _messages[chatId] ?? [];
  _messages[chatId] = [...existing, userMsg, aiMsg];

  That's safer. Let me use that.

  Also onToken callback calls notifyListeners() inside stream — that's fine.

  One more issue: when stop is pressed, _cancelCompleter?.complete() will cancel the stream, but the
  stream's onError might fire with a cancellation error. The ApiService catches Exception and
  rethrows ApiException... actually cancellation via cancelSignal calls sub.cancel() and
  completer.complete() — it doesn't error. So stream() future completes normally. Good.

  Let me finalize this clean version and send it.Yeh file api_service.dart aur model_service.dart se
  connect hogi — real streaming, stop, regenerate, aur error handling.

  ---

  Ye file banaenge: lib/providers/chat_provider.dart

  GitHub par jaiye → "Add file" → "Create new file" → naam likhiye: lib/providers/chat_provider.dart

  Neeche wala poora code copy karke paste kijiye:

  /// Chat state provider: real API calls, streaming, stop, regenerate, error handling.
  library chat_provider;

  import 'dart:async';
  import 'package:flutter/foundation.dart';

  import '../models/chat_message.dart';
  import '../services/api_service.dart';
  import '../providers/app_provider.dart';

  /// Manages the current chat, messages, and API interaction.
  class ChatProvider extends ChangeNotifier {
    String? _currentChatId;
    final Map<String, List<ChatMessage>> _messages = {};
    final Set<String> _generating = {};

    Completer<void>? _cancelCompleter;

    String? get currentChatId => _currentChatId;

    List<ChatMessage> get messages =>
        _currentChatId == null ? [] : _messages[_currentChatId] ?? [];

    bool get isGenerating =>
        _currentChatId != null && _generating.contains(_currentChatId);

    /// Start a fresh chat.
    void newChat() {
      _currentChatId = 'chat_${DateTime.now().microsecondsSinceEpoch}';
      _messages[_currentChatId] = [];
      _cancelCompleter = null;
      notifyListeners();
    }

    /// Open an existing chat (Phase 6 wires this to the DB).
    void openChat(String id, List<ChatMessage> msgs) {
      _currentChatId = id;
      _messages[id] = List.from(msgs);
      _cancelCompleter = null;
      notifyListeners();
    }

    /// Clear all chats.
    void clearAll() {
      _currentChatId = null;
      _messages.clear();
      _generating.clear();
      _cancelCompleter = null;
      notifyListeners();
    }

    /// Send a user message and stream AI reply from real API.
    Future<void> sendMessage(BuildContext context, String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || _currentChatId == null) return;

      final appProvider = context.read<AppProvider>();
      final model = appProvider.selectedModel;

      final chatId = _currentChatId!;
      final userMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: trimmed,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      final aiMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
        isStreaming: true,
      );

      final existing = _messages[chatId] ?? [];
      _messages[chatId] = [...existing, userMsg, aiMsg];
      _generating.add(chatId);
      _cancelCompleter = Completer<void>();
      notifyListeners();

      try {
        final api = ApiService(
          baseUrlProvider: () => appProvider.gatewayBaseUrl,
          apiKeyProvider: () => appProvider.apiKey,
        );

        final history = _messages[chatId]!
            .where((m) => m.role != MessageRole.ai || !m.isStreaming)
            .map((m) => ApiMessage(
                  role: m.role == MessageRole.user ? 'user' : 'assistant',
                  content: m.text,
                ))
            .toList();

        var buffer = '';
        await api.stream(
          model: model,
          messages: history,
          onToken: (token) {
            buffer += token;
            _replaceMessage(chatId, aiMsg.id,
                (m) => m.copyWith(text: buffer, status: MessageStatus.streaming, isStreaming: true));
            notifyListeners();
          },
          cancelSignal: _cancelCompleter!.future,
        );

        final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
        if (idx >= 0) {
          _messages[chatId]![idx] = aiMsg.copyWith(
            text: buffer,
            status: MessageStatus.done,
            isStreaming: false,
          );
        }
      } on Exception catch (e) {
        // Streaming failed — fall back to non-streaming once.
        try {
          final api = ApiService(
            baseUrlProvider: () => appProvider.gatewayBaseUrl,
            apiKeyProvider: () => appProvider.apiKey,
          );
          final history = _messages[chatId]!
              .where((m) => m.role != MessageRole.ai || !m.isStreaming)
              .map((m) => ApiMessage(
                    role: m.role == MessageRole.user ? 'user' : 'assistant',
                    content: m.text,
              .toList();
          final reply = await api.complete(model: model, messages: history);
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);                                  if (idx >= 0) {
            _messages[chatId]![idx] = aiMsg.copyWith(
              text: reply,
              status: MessageStatus.done,
              isStreaming: false,
            );
          }
        } on Exception catch (fallbackErr) {
          // Both failed — show friendly error in bubble.
          final idx = _messages[chatId]!.indexWhere((m) => m.id == aiMsg.id);
          if (idx >= 0) {
            final friendly = _friendlyError(fallbackErr);
            _messages[chatId]![idx] = aiMsg.copyWith(
              text: friendly,
              status: MessageStatus.error,
              isStreaming: false,
            );
          }
        }
      } finally {
        _generating.remove(chatId);
        _cancelCompleter = null;
        notifyListeners();
      }
    }

    /// Stop the current generation.
    void stopGenerating() {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      _cancelCompleter?.complete();
      final list = _messages[chatId];
      if (list == null) return;
      final updated = list
          .map((m) => m.isStreaming
              ? m.copyWith(status: MessageStatus.done, isStreaming: false)
              : m)
          .toList();
      _messages[chatId] = updated;
      _generating.remove(chatId);
      notifyListeners();
    }

    /// Regenerate the last AI answer.
    Future<void> regenerate(BuildContext context) async {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;
      final list = _messages[chatId];
      if (list == null || list.isEmpty) return;
      final lastAiIdx = list.lastIndexWhere((m) => m.role == MessageRole.ai);
      if (lastAiIdx < 0) return;
      final lastUserIdx = list.lastIndexWhere((m) => m.role == MessageRole.user);
      if (lastUserIdx < 0) return;
      final userText = list[lastUserIdx].text;

      list.removeAt(lastAiIdx);
      _generating.add(chatId);
      notifyListeners();                                                                             
      await sendMessage(context, userText);
    }

    void _replaceMessage(String chatId, String msgId, ChatMessage Function(ChatMessage) f) {
      final list = _messages[chatId];
      if (list == null) return;
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx < 0) return;
      _messages[chatId] = [...list];
      _messages[chatId]![idx] = f(list[idx]);
    }

    String _friendlyError(Object e) {
      if (e is ApiException) {
        return e.message;
      }
      return 'Something went wrong: $e';
    }
  }
