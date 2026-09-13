import 'chat_message.dart';
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String providerId;
  final String model;
  final List<ChatMessage> messages;
  final String? thinking;
  final String? command;
  const Conversation({required this.id, required this.title, required this.createdAt, required this.updatedAt, required this.providerId, required this.model, this.messages=const [], this.thinking, this.command});
  Conversation copyWith({String? title, List<ChatMessage>? messages, DateTime? updatedAt, String? providerId, String? model, String? thinking, String? command})=>Conversation(id:id,title:title??this.title,createdAt:createdAt,updatedAt:updatedAt??this.updatedAt,providerId:providerId??this.providerId,model:model??this.model,messages:messages??this.messages,thinking:thinking??this.thinking,command:command??this.command);
}
