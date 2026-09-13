
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../models/chat_message.dart';
import '../models/video_task.dart';
import '../models/provider_config.dart';
import 'ai_provider.dart';

class CompatibleProvider implements AIProvider {
  final ProviderConfig config;
  late final ApiClient client;
  CompatibleProvider(this.config){
    if(config.baseUrl.trim().isEmpty) throw ArgumentError('Base URL 未配置');
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
    String content='';
    if(choices!=null && choices.isNotEmpty){
      final msg = choices[0]['message'];
      if(msg is Map) content = (msg['content'] ?? '').toString();
    }
    if(content.isEmpty) content = (data['content'] ?? data['output'] ?? '').toString();
    if(content.isEmpty) content = data.toString();
    return ChatResponse(content: content, model: model, tokensUsed: (data['usage']?['total_tokens'] ?? 0) as int);
  }

  @override Stream<String> chatStream({required List<ChatMessage> messages, required String model}) async* {
    // 优先尝试真实 SSE 流式
    final dio = client.dio;
    try{
      final resp = await dio.post(
        config.chatEndpoint,
        data: {'model': model, 'messages': messages.map((m)=>{'role':m.role.name,'content':m.content}).toList(), 'stream': true},
        options: Options(responseType: ResponseType.plain),
      );
      // 若服务端返回流式文本，尝试按 SSE 解析；否则回退
      final data = resp.data;
      if(data is String && data.contains('data:')){
        String acc='';
        for(final line in data.split('\n')){
          final t=line.trim();
          if(!t.startsWith('data:')) continue;
          final payload=t.substring(5).trim();
          if(payload=='[DONE]') break;
          acc += payload;
          yield acc;
        }
        if(acc.isNotEmpty) return;
      }
    }catch(_){
      // 回退到非流式逐字 yield，保证调用方仍能流式展示真实内容
    }
    final res = await chat(messages: messages, model: model);
    // 真实内容一次性拿到后，按字符增量 yield，仅为打字机效果，不伪造内容
    for(int i=0;i<res.content.length;i++){
      await Future.delayed(const Duration(milliseconds: 12));
      yield res.content.substring(0,i+1);
    }
  }

  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) async {
    final data = await client.postJson(config.imageEndpoint, {'prompt':prompt,'model':model,'size':size,'n':1});
    final list = data['data'] as List?;
    final urls = list?.map((e){
      if(e is Map){
        return (e['url'] ?? e['b64_json'] ?? '').toString();
      }
      return e.toString();
    }).where((s)=>s.isNotEmpty).toList() ?? [];
    return ImageResponse(urls);
  }

  @override Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'}) async {
    final data = await client.postJson(config.videoEndpoint, {'prompt':prompt,'model':model,'duration':duration});
    final id = (data['id'] ?? data['task_id'] ?? data['taskId'] ?? '').toString();
    if(id.isEmpty) throw Exception('服务端未返回 task_id：$data');
    return VideoTask(id:id,prompt:prompt,model:model,duration:duration,status:VideoStatus.processing,progress: 0);
  }

  @override Future<VideoTask> getVideoTask(String taskId) async {
    final data = await client.getJson('${config.videoEndpoint}/$taskId');
    final statusStr = (data['status'] ?? data['state'] ?? 'processing').toString().toLowerCase();
    final progress = (data['progress'] is int) ? data['progress'] as int : int.tryParse(data['progress']?.toString() ?? '') ?? 0;
    final url = data['video_url'] ?? data['url'] ?? data['videoUrl'];
    VideoStatus st;
    if(statusStr.contains('complete') || statusStr.contains('success') || statusStr=='done') st=VideoStatus.completed;
    else if(statusStr.contains('fail') || statusStr.contains('error')) st=VideoStatus.failed;
    else st=VideoStatus.processing;
    return VideoTask(id:taskId,prompt:'',model:config.videoModel,duration:'10s',status: st, progress: progress.clamp(0,100), videoUrl: url?.toString(), error: data['error']?.toString());
  }

  @override Future<bool> testConnection() async {
    try{
      await client.getJson('/models');
      return true;
    }catch(_){
      // 降级：尝试 chat 模型的轻量探测
      try{ await client.postJson(config.chatEndpoint, {'model': config.chatModel, 'messages':[{'role':'user','content':'ping'}], 'max_tokens':1}); return true; }catch(_){ return false; }
    }
  }
}

/// 未配置时的占位 Provider，调用即抛真实错误，不返回假数据
class UnconfiguredProvider implements AIProvider {
  final String reason;
  UnconfiguredProvider(this.reason);
  @override String get id => 'unconfigured';
  @override String get name => '未配置';
  Future<Never> _fail() => Future.error(Exception(reason));
  @override Future<ChatResponse> chat({required List<ChatMessage> messages, required String model}) => _fail();
  @override Stream<String> chatStream({required List<ChatMessage> messages, required String model}) => Stream.error(Exception(reason));
  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) => _fail();
  @override Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'}) => _fail();
  @override Future<VideoTask> getVideoTask(String taskId) => _fail();
  @override Future<bool> testConnection() async => false;
}
