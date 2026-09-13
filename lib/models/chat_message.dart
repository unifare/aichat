enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final String? model;
  final String? thinking;
  final String? command;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.model,
    this.thinking,
    this.command,
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? createdAt,
    String? model,
    String? thinking,
    String? command,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        model: model ?? this.model,
        thinking: thinking ?? this.thinking,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        if (model != null) 'model': model,
        if (thinking != null) 'thinking': thinking,
        if (command != null) 'command': command,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: ChatRole.values.byName(j['role'] as String),
        content: j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        model: j['model'] as String?,
        thinking: j['thinking'] as String?,
        command: j['command'] as String?,
      );
}
