import 'dart:async';
import 'dart:convert';
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
    final dio = client.dio;
    try{
      final resp = await dio.post<ResponseBody>(
        config.chatEndpoint,
        data: {'model': model, 'messages': messages.map((m)=>{'role':m.role.name,'content':m.content}).toList(), 'stream': true},
        options: Options(responseType: ResponseType.stream, headers: {'Accept':'text/event-stream'}),
      );
      final body = resp.data;
      if(body==null) throw Exception('empty stream');
      String acc='';
      bool gotContent=false;
      bool inReasoning=false;
      String buffer='';
      await for(final chunk in body.stream){
        buffer += utf8.decode(chunk, allowMalformed: true);
        // process line by line
        while(buffer.contains('\n')){
          final nl = buffer.indexOf('\n');
          String line = buffer.substring(0, nl);
          buffer = buffer.substring(nl+1);
          line = line.trim();
          if(line.isEmpty) continue;
          if(!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if(payload.isEmpty || payload=='[DONE]') continue;
          Map<String,dynamic>? obj;
          try{
            final v = jsonDecode(payload);
            if(v is Map<String,dynamic>) obj=v;
            else if(v is Map) obj=Map<String,dynamic>.from(v);
          }catch(_){ continue; }
          if(obj==null) continue;
          final delta = _extractDelta(obj);
          if(delta.reasoning != null && delta.reasoning!.isNotEmpty){
            if(!inReasoning){
              inReasoning = true;
              acc += '<think>';
            }
            acc += delta.reasoning!;
            gotContent = true;
            yield acc;
          }
          if(delta.content != null && delta.content!.isNotEmpty){
            if(inReasoning){
              inReasoning = false;
              acc += '</think>\n';
            }
            acc += delta.content!;
            gotContent = true;
            yield acc;
          }
          final finish = _extractFinish(obj);
          if(finish) break;
        }
      }
      if(inReasoning){
        inReasoning = false;
        acc += '</think>\n';
        yield acc;
      }
      // tail buffer without trailing newline
      final tail = buffer.trim();
      if(tail.startsWith('data:')){
        final payload = tail.substring(5).trim();
        if(payload.isNotEmpty && payload!='[DONE]'){
          try{
            final v=jsonDecode(payload);
            Map<String,dynamic>? obj;
            if(v is Map<String,dynamic>) obj=v;
            else if(v is Map) obj=Map<String,dynamic>.from(v);
            if(obj!=null){
              final c=_extractDeltaContent(obj);
              if(c!=null && c.isNotEmpty){ acc+=c; gotContent=true; yield acc; }
            }
          }catch(_){}
        }
      }
      if(gotContent) return;
    }catch(_){
      // fall through to non-stream
    }
    // fallback: non-streaming request with incremental yield for typewriter feel
    final res = await chat(messages: messages, model: model);
    // yield progressively so UI still animates even on non-stream endpoints
    String cur='';
    for(final ch in res.content.split('')){
      cur+=ch;
      yield cur;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  ({String? content, String? reasoning}) _extractDelta(Map<String,dynamic> obj){
    final choices = obj['choices'];
    if(choices is List && choices.isNotEmpty){
      final c0 = choices[0];
      if(c0 is Map){
        final delta = c0['delta'];
        if(delta is Map){
          final rc = delta['reasoning_content'];
          final cc = delta['content'];
          final tc = delta['text'];
          return (
            content: (cc is String && cc.isNotEmpty) ? cc : ((tc is String && tc.isNotEmpty) ? tc : null),
            reasoning: (rc is String && rc.isNotEmpty) ? rc : null,
          );
        }
        final text = c0['text'];
        if(text is String && text.isNotEmpty) return (content: text, reasoning: null);
        final msg = c0['message'];
        if(msg is Map){
          final mc = msg['content'];
          final mrc = msg['reasoning_content'];
          return (
            content: (mc is String && mc.isNotEmpty) ? mc : null,
            reasoning: (mrc is String && mrc.isNotEmpty) ? mrc : null,
          );
        }
        final content = c0['content'];
        if(content is String && content.isNotEmpty) return (content: content, reasoning: null);
      }
    }
    final direct = obj['content'];
    if(direct is String && direct.isNotEmpty) return (content: direct, reasoning: null);
    final txt = obj['text'];
    if(txt is String && txt.isNotEmpty) return (content: txt, reasoning: null);
    return (content: null, reasoning: null);
  }

  String? _extractDeltaContent(Map<String,dynamic> obj){
    final d = _extractDelta(obj);
    return d.content ?? d.reasoning;
  }
  bool _extractFinish(Map<String,dynamic> obj){
    try{
      final choices=obj['choices'];
      if(choices is List && choices.isNotEmpty){
        final c0=choices[0] as Map;
        final fr=c0['finish_reason'];
        if(fr!=null && fr.toString()!='null' && fr.toString().isNotEmpty) return true;
      }
    }catch(_){}
    return false;
  }

  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) async {
    final data = await client.postJson(config.imageEndpoint, {'prompt':prompt,'model':model,'size':size,'n':1});
    final list = data['data'] as List?;
    final urls = list?.map((e){
      if(e is Map){
        return (e['url'] ?? e['b64_json'] ?? e['b64Json'] ?? '').toString();
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
      try{ await client.postJson(config.chatEndpoint, {'model': config.chatModel, 'messages':[{'role':'user','content':'ping'}], 'max_tokens':1}); return true; }catch(_){ return false; }
    }
  }
}

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
