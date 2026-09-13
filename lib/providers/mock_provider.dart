
// 仅用于本地开发自检，不在发布 UI 中作为假数据展示。
// 线上逻辑禁止使用此 Provider 返回假对话/假图片/假进度。
import 'dart:async';
import '../models/chat_message.dart';
import '../models/video_task.dart';
import 'ai_provider.dart';

class MockProvider implements AIProvider {
  @override String get id => 'mock-dev-only';
  @override String get name => 'Mock (开发自检)';
  @override Future<ChatResponse> chat({required List<ChatMessage> messages, required String model}) async => throw Exception('Mock 已禁用：请在设置页配置真实 Provider');
  @override Stream<String> chatStream({required List<ChatMessage> messages, required String model}) => Stream.error(Exception('Mock 已禁用'));
  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) => throw Exception('Mock 已禁用');
  @override Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'}) => throw Exception('Mock 已禁用');
  @override Future<VideoTask> getVideoTask(String taskId) => throw Exception('Mock 已禁用');
  @override Future<bool> testConnection() async => false;
}
