
import '../core/api/api_client.dart';
import '../models/chat_message.dart';
import '../models/video_task.dart';
import '../models/provider_config.dart';
import 'ai_provider.dart';

class CompatibleProvider implements AIProvider {
  final ProviderConfig config;
  late final ApiClient client;
  CompatibleProvider(this.config){
    client = ApiClient(baseUrl: config.baseUrl, apiKey: config.apiKey);
  }
  @override String get id => config.id;
  @override String get name => config.name;

  @override Future<ChatResponse> chat({required List<ChatMessage> messages, required String model}) async {
    final data = await client.postJson(config.chatEndpoint, {
      'model': model,
      'messages': messages.map((m)=>{'role':m.role.name,'content':m.content}).toList(),
    });
    final choices = data['choices'] as List?;
    final content = choices!=null && choices.isNotEmpty ? (choices[0]['message']['content'] ?? '') : (data['content'] ?? '');
    return ChatResponse(content: content.toString(), model: model);
  }

  @override Stream<String> chatStream({required List<ChatMessage> messages, required String model}) async* {
    // fallback: fetch full then yield incrementally
    final res = await chat(messages: messages, model: model);
    for(int i=0;i<res.content.length;i++){
      await Future.delayed(const Duration(milliseconds: 12));
      yield res.content.substring(0,i+1);
    }
  }

  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) async {
    final data = await client.postJson(config.imageEndpoint, {'prompt':prompt,'model':model,'size':size,'n':2});
    final list = data['data'] as List?;
    final urls = list?.map((e)=> e['url']?.toString() ?? '').where((s)=>s.isNotEmpty).toList() ?? [];
    return ImageResponse(urls);
  }

  @override Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'}) async {
    final data = await client.postJson(config.videoEndpoint, {'prompt':prompt,'model':model,'duration':duration});
    final id = (data['id'] ?? data['task_id'] ?? 'v_mock').toString();
    return VideoTask(id:id,prompt:prompt,model:model,duration:duration,status:VideoStatus.processing,progress: 5);
  }

  @override Future<VideoTask> getVideoTask(String taskId) async {
    final data = await client.getJson('${config.videoEndpoint}/$taskId');
    final statusStr = (data['status'] ?? 'processing').toString();
    final progress = (data['progress'] ?? 67) as int;
    final url = data['video_url'] ?? data['url'];
    return VideoTask(id:taskId,prompt:'',model:config.videoModel,duration:'10s',status: statusStr=='completed'? VideoStatus.completed : statusStr=='failed'? VideoStatus.failed : VideoStatus.processing, progress: progress, videoUrl: url?.toString());
  }

  @override Future<bool> testConnection() async {
    try{ await client.getJson('/models'); return true; }catch(_){ return false; }
  }
}
