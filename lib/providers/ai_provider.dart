
import '../models/chat_message.dart';
import '../models/image_task.dart';
import '../models/video_task.dart';

class ChatResponse {
  final String content;
  final String model;
  final int tokensUsed;
  const ChatResponse({required this.content, required this.model, this.tokensUsed=0});
}

class ImageResponse {
  final List<String> urls;
  const ImageResponse(this.urls);
}

abstract class AIProvider {
  String get id;
  String get name;
  Future<ChatResponse> chat({required List<ChatMessage> messages, required String model});
  Stream<String> chatStream({required List<ChatMessage> messages, required String model});
  Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'});
  Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'});
  Future<VideoTask> getVideoTask(String taskId);
  Future<bool> testConnection();
}
