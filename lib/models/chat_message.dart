
enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final String? model;
  const ChatMessage({required this.id, required this.role, required this.content, required this.createdAt, this.model});
  Map<String,dynamic> toJson()=>{'id':id,'role':role.name,'content':content,'createdAt':createdAt.toIso8601String(),'model':model};
  factory ChatMessage.fromJson(Map<String,dynamic> j)=>ChatMessage(id:j['id'],role:ChatRole.values.byName(j['role']),content:j['content'],createdAt:DateTime.parse(j['createdAt']),model:j['model']);
}
