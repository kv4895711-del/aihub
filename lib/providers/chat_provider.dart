/// Chat state provider: current chat, messages,
  send/stop/regenerate.
  library chat_provider;

  import 'dart:async';
  import 'package:flutter/foundation.dart';

  import '../models/chat_message.dart';

  /// Manages the currently open chat and its messages.
  class ChatProvider extends ChangeNotifier {
    String? _currentChatId;
    final Map<String, List<ChatMessage>> _messages = {};
    final Set<String> _generating = {};

    String? get currentChatId => _currentChatId;

    List<ChatMessage> get messages =>
        _currentChatId == null ? [] : _messages[_currentChatId]
  ?? [];

    bool get isGenerating =>
        _currentChatId != null &&
  _generating.contains(_currentChatId);

    /// Start a fresh chat.
    void newChat() {
      _currentChatId =
  'chat_${DateTime.now().microsecondsSinceEpoch}';
      _messages[_currentChatId] = [];
      notifyListeners();
    }

    /// Open an existing chat (Phase 6 wires this to the DB).
    void openChat(String id, List<ChatMessage> msgs) {
      _currentChatId = id;
      _messages[id] = msgs;
      notifyListeners();
    }

    /// Send a user message and (Phase 2) stream a dummy AI
  reply.
    Future<void> sendMessage(String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || _currentChatId == null) return;

      final chatId = _currentChatId!;
      final userMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_u',
        text: trimmed,
        role: MessageRole.user,                                         timestamp: DateTime.now(),
      );
      final aiMsg = ChatMessage(                                        id: '${DateTime.now().microsecondsSinceEpoch}_a',
        text: '',
        role: MessageRole.ai,
        timestamp: DateTime.now(),                                      status: MessageStatus.streaming,
        isStreaming: true,                                            );
                                                                      _messages[chatId] = [...?_messages[chatId], userMsg,
  aiMsg];                                                             _generating.add(chatId);
      notifyListeners();                                        
      await _streamDummyReply(chatId: chatId, aiMsgId: aiMsg.id,
  userText: trimmed);
    }                                                           
    /// Simulated token-by-token reply (Phase 2 only).              Future<void> _streamDummyReply({
      required String chatId,
      required String aiMsgId,                                        required String userText,
    }) async {                                                        final reply = _dummyReply(userText);
      var buffer = '';                                                for (final token in reply.split(' ')) {
        buffer += (buffer.isEmpty ? '' : ' ') + token;                  _replaceMessage(chatId, aiMsgId,
            (m) => m.copyWith(text: buffer, status:
  MessageStatus.streaming, isStreaming: true));
        notifyListeners();                                              await Future<void>.delayed(const Duration(milliseconds:
  40));
      }
      _replaceMessage(chatId, aiMsgId,
          (m) => m.copyWith(text: reply, status:
  MessageStatus.done, isStreaming: false));
      _generating.remove(chatId);
      notifyListeners();
    }
                                                                    void _replaceMessage(String chatId, String msgId,
  ChatMessage Function(ChatMessage) f) {                              final list = _messages[chatId];
      if (list == null) return;
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx < 0) return;
      _messages[chatId] = [...list];
      _messages[chatId]![idx] = f(list[idx]);

    String _dummyReply(String userText) {                             const samples = [
        'This is a placeholder reply while Phase 2 builds the
  UI. Phase 4 will stream real answers from your FreeLLMAPI
  gateway.',                                                            'The glass UI is coming together! Soon this text will be
  replaced by real streamed model output.',
        'Dummy mode: send any message and you will see            token-by-token animation here.',
      ];
      return samples[userText.length % samples.length];
    }

    /// Stop the current generation (Phase 2: just finalizes the
  bubble).
    void stopGenerating() {
      if (_currentChatId == null) return;
      final chatId = _currentChatId!;                                 final list = _messages[chatId];
      if (list == null) return;                                       final updated = list
          .map((m) => m.isStreaming                                           ? m.copyWith(status: MessageStatus.done,
  isStreaming: false)
              : m)
          .toList();                                                  _messages[chatId] = updated;
      _generating.remove(chatId);
      notifyListeners();
    }                                                           
    /// Regenerate the last AI answer (Phase 2: dummy text).        Future<void> regenerate() async {
      if (_currentChatId == null) return;                             final chatId = _currentChatId!;
      final list = _messages[chatId];
      if (list == null || list.isEmpty) return;
      final lastAi = list.lastWhere(
        (m) => m.role == MessageRole.ai,
        orElse: () => list.last,                                      );
      _generating.add(chatId);
      notifyListeners();
      await _streamDummyReply(
        chatId: chatId,
        aiMsgId: lastAi.id,                                             userText: 'regenerate',
      );                                                            }
  }
