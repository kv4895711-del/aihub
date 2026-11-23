 /// Chat message model.
  library chat_message;

  /// Role of a message in the chat.
  enum MessageRole { user, ai }

  /// Delivery status of a message.
  enum MessageStatus {
    /// Being received/streamed.
    streaming,

    /// Complete.
    done,

    /// Failed to receive.
    error,
  }

  /// A single chat message.
  class ChatMessage {
    /// Unique message id.
    final String id;

    /// Text content.
    final String text;

    /// Message role (user or AI).
    final MessageRole role;

    /// Timestamp.
    final DateTime timestamp;                                   
    /// Status (streaming, done, error).
    final MessageStatus status;

    /// Whether the AI is still streaming this message.
    final bool isStreaming;

      required this.id,
      required this.text,
      required this.role,
      required this.timestamp,
      this.status = MessageStatus.done,
      this.isStreaming = false,
    });

    /// Copy with optional overrides.
    ChatMessage copyWith({
      String? id,
      String? text,
      MessageRole? role,
      DateTime? timestamp,
      MessageStatus? status,
      bool? isStreaming,
    }) {
      return ChatMessage(                                               id: id ?? this.id,
        text: text ?? this.text,
        role: role ?? this.role,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        isStreaming: isStreaming ?? this.isStreaming,
      );
    }

    /// Convert to map (for DB storage).
    Map<String, dynamic> toMap() => {
          'id': id,
          'text': text,
          'role': role.index,
          'timestamp': timestamp.toIso8601String(),
          'status': status.index,
          'isStreaming': isStreaming ? 1 : 0,
        };

    /// Create from map (for DB retrieval).
    factory ChatMessage.fromMap(Map<String, dynamic> map) {
      return ChatMessage(
        id: map['id'] as String,
        text: map['text'] as String,
        role: MessageRole.values[map['role'] as int],
        timestamp: DateTime.parse(map['timestamp'] as String),
        status: map['status'] != null
            ? MessageStatus.values[map['status'] as int]
            : MessageStatus.done,                                       isStreaming: map['isStreaming'] == 1,
      );
    }
  }
