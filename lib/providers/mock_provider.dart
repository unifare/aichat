
import 'dart:async';
import 'dart:math';
import '../models/chat_message.dart';
import '../models/video_task.dart';
import 'ai_provider.dart';

class MockProvider implements AIProvider {
  @override String get id => 'mock';
  @override String get name => 'Mock (本地演示)';
  final _rand = Random();
  final Map<String, VideoTask> _videos={};

  @override Future<ChatResponse> chat({required List<ChatMessage> messages, required String model}) async {
    await Future.delayed(Duration(milliseconds: 400+_rand.nextInt(400)));
    final last = messages.isEmpty? '你好': messages.last.content;
    return ChatResponse(content: '已收到：$last\n\n按 Provider 抽象，当前模型 **$model** 会通过 `provider.chat()` 路由。演示为本地 Mock，无需真实 Endpoint。', model: model, tokensUsed: 412);
  }

  @override Stream<String> chatStream({required List<ChatMessage> messages, required String model}) async* {
    final full = await chat(messages: messages, model: model);
    final text = full.content;
    for(int i=0;i<text.length;i++){
      await Future.delayed(const Duration(milliseconds: 18));
      yield text.substring(0,i+1);
    }
  }

  @override Future<ImageResponse> generateImage({required String prompt, required String model, String size='1024x1024'}) async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if(_rand.nextDouble()<0.15) throw Exception('Endpoint 超时');
    return ImageResponse(List.generate(2, (i)=> 'https://picsum.photos/seed/${prompt.hashCode.abs()+i}/600/600'));
  }

  @override Future<VideoTask> generateVideo({required String prompt, required String model, String duration='10s'}) async {
    final id = 'v_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final task = VideoTask(id:id,prompt:prompt,model:model,duration:duration,status:VideoStatus.processing,progress: 7);
    _videos[id]=task;
    // simulate polling progress by updating map asynchronously
    Timer.periodic(const Duration(milliseconds: 900), (t){
      final cur = _videos[id];
      if(cur==null){ t.cancel(); return; }
      if(cur.status==VideoStatus.completed){ t.cancel(); return; }
      final next = min(100, cur.progress + 5 + _rand.nextInt(8));
      if(next>=100){
        _videos[id]=cur.copyWith(status: VideoStatus.completed, progress: 100, videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4');
        t.cancel();
      } else {
        _videos[id]=cur.copyWith(progress: next);
      }
    });
    return task;
  }

  @override Future<VideoTask> getVideoTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _videos[taskId] ?? VideoTask(id:taskId,prompt:'',model:'sora',duration:'10s',status:VideoStatus.failed, error:'not found');
  }

  @override Future<bool> testConnection() async { await Future.delayed(const Duration(milliseconds: 500)); return true; }
}
