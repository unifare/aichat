
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/image_task.dart';
import '../models/video_task.dart';
import '../models/provider_config.dart';
import 'mock_provider.dart';
import 'ai_provider.dart';

final _uuid = Uuid();

// --- ProviderConfig state ---
final providerConfigsProvider = StateNotifierProvider<ProviderConfigsNotifier, List<ProviderConfig>>((ref)=> ProviderConfigsNotifier());
class ProviderConfigsNotifier extends StateNotifier<List<ProviderConfig>> {
  ProviderConfigsNotifier(): super(const [
    ProviderConfig(id:'mock',name:'Mock (本地演示)',baseUrl:'',chatModel:'gpt-4o',imageModel:'sdxl',videoModel:'sora'),
    ProviderConfig(id:'openai',name:'OpenAI',baseUrl:'https://api.openai.com/v1',chatModel:'gpt-4o',imageModel:'dall-e-3',videoModel:'sora'),
    ProviderConfig(id:'compat',name:'OpenAI Compatible · 自建网关',baseUrl:'https://ai.company.local/v1',chatModel:'gpt-4o',imageModel:'sd-xl',videoModel:'sora'),
  ]);
  void update(ProviderConfig c){ state = [for(final p in state) if(p.id==c.id) c else p]; }
  void add(ProviderConfig c){ state = [...state, c]; }
  void remove(String id){ state = state.where((p)=>p.id!=id).toList(); }
}

final activeProviderIdProvider = StateProvider<String>((ref)=> 'mock');

final aiProviderProvider = Provider<AIProvider>((ref){
  final id = ref.watch(activeProviderIdProvider);
  // demo: always mock unless you wire CompatibleProvider here
  return MockProvider();
});

// --- Conversations ---
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref)=> ConversationsNotifier(ref));
final activeConversationIdProvider = StateProvider<String?>((ref)=> null);

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  final Ref ref;
  ConversationsNotifier(this.ref): super(_seed());

  static List<Conversation> _seed(){
    final now = DateTime.now();
    return [
      Conversation(
        id:'c1', title:'Flutter 全平台架构讨论', createdAt: now.subtract(const Duration(minutes:2)), updatedAt: now.subtract(const Duration(minutes:2)),
        providerId:'mock', model:'gpt-4o',
        messages: [
          ChatMessage(id:'m1', role: ChatRole.assistant, content:'你好，有什么可以帮助？试试输入“帮我设计一个 App”，我会以流式返回。', createdAt: now.subtract(const Duration(minutes:2)), model:'gpt-4o'),
          ChatMessage(id:'m2', role: ChatRole.user, content:'帮我设计一个 Flutter 全平台 AI 客户端，要支持可配置 Endpoint。', createdAt: now.subtract(const Duration(minutes:1))),
          ChatMessage(id:'m3', role: ChatRole.assistant, content:'好的，我建议用 **Provider Adapter** 抽象：UI 只调 `provider.chat()`，底层分别对接 OpenAI / Compatible / 自建网关。\n\n```dart\nabstract class AIProvider {\n  Future<ChatResponse> chat({required List<ChatMessage> messages, required String model});\n  Future<ImageResponse> generateImage({required String prompt, required String model});\n  Future<VideoTask> generateVideo({required String prompt, required String model});\n}\n```', createdAt: now, model:'gpt-4o'),
        ],
      ),
      Conversation(id:'c2', title:'API 设计 · Provider 抽象', createdAt: now.subtract(const Duration(hours:1)), updatedAt: now.subtract(const Duration(hours:1)), providerId:'mock', model:'claude-3.5'),
      Conversation(id:'c3', title:'画图提示词优化', createdAt: now.subtract(const Duration(days:1)), updatedAt: now.subtract(const Duration(days:1)), providerId:'mock', model:'sdxl'),
    ];
  }

  void newConversation(){
    final id = _uuid.v4();
    final now = DateTime.now();
    final c = Conversation(id:id, title:'新对话', createdAt: now, updatedAt: now, providerId: ref.read(activeProviderIdProvider), model: 'gpt-4o');
    state = [c, ...state];
    ref.read(activeConversationIdProvider.notifier).state = id;
  }

  void appendMessage(String convId, ChatMessage msg){
    state = [
      for(final c in state)
        if(c.id==convId) c.copyWith(messages: [...c.messages, msg], updatedAt: DateTime.now(), title: c.messages.isEmpty && msg.role==ChatRole.user ? _titleFrom(msg.content) : c.title)
        else c
    ];
  }

  void updateLastAssistant(String convId, String content){
    state = [
      for(final c in state)
        if(c.id==convId && c.messages.isNotEmpty) c.copyWith(messages: [...c.messages.sublist(0, c.messages.length-1), ChatMessage(id:c.messages.last.id, role: ChatRole.assistant, content: content, createdAt: c.messages.last.createdAt, model: c.messages.last.model)], updatedAt: DateTime.now())
        else c
    ];
  }

  String _titleFrom(String s)=> s.length>18? '${s.substring(0,18)}…': s;
}

// current conversation
final currentConversationProvider = Provider<Conversation?>((ref){
  final list = ref.watch(conversationsProvider);
  final id = ref.watch(activeConversationIdProvider);
  if(id==null) return list.isNotEmpty? list.first: null;
  return list.where((c)=>c.id==id).firstOrNull ?? (list.isNotEmpty? list.first: null);
});

// chat streaming state
final chatStreamingProvider = StateProvider<bool>((ref)=> false);
final chatStreamingTextProvider = StateProvider<String>((ref)=> '');

// image tasks
final imageTasksProvider = StateNotifierProvider<ImageTasksNotifier, List<ImageTask>>((ref)=> ImageTasksNotifier());
class ImageTasksNotifier extends StateNotifier<List<ImageTask>> {
  ImageTasksNotifier(): super([]);
  void add(ImageTask t)=> state=[t, ...state];
  void update(String id, ImageTask Function(ImageTask) fn)=> state=[for(final p in state) if(p.id==id) fn(p) else p];
}

// video tasks
final videoTasksProvider = StateNotifierProvider<VideoTasksNotifier, List<VideoTask>>((ref)=> VideoTasksNotifier());
class VideoTasksNotifier extends StateNotifier<List<VideoTask>> {
  VideoTasksNotifier(): super([]);
  void add(VideoTask t)=> state=[t, ...state];
  void update(String id, VideoTask Function(VideoTask) fn)=> state=[for(final p in state) if(p.id==id) fn(p) else p];
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty? null: first;
}
