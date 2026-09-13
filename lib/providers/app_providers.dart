
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/storage/local_storage.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/image_task.dart';
import '../models/video_task.dart';
import '../models/provider_config.dart';
import 'ai_provider.dart';
import 'compatible_provider.dart';

final _uuid = Uuid();

// Providers Config — 真实持久化，无默认值
final providerConfigsProvider = StateNotifierProvider<ProviderConfigsNotifier, List<ProviderConfig>>((ref)=> ProviderConfigsNotifier());
class ProviderConfigsNotifier extends StateNotifier<List<ProviderConfig>> {
  ProviderConfigsNotifier(): super([]){
    _load();
  }
  Future<void> _load() async {
    final list = await LocalStorage.loadProviders();
    state = list;
  }
  Future<void> _save() async => await LocalStorage.saveProviders(state);
  void update(ProviderConfig c){
    state = [for(final p in state) if(p.id==c.id) c else p];
    _save();
  }
  void add(ProviderConfig c){
    state = [...state, c];
    _save();
  }
  void remove(String id){
    state = state.where((p)=>p.id!=id).toList();
    _save();
  }
}

final activeProviderIdProvider = StateNotifierProvider<ActiveProviderNotifier, String?>((ref)=> ActiveProviderNotifier());
class ActiveProviderNotifier extends StateNotifier<String?> {
  ActiveProviderNotifier(): super(null){ _load(); }
  Future<void> _load() async { state = await LocalStorage.loadActiveProviderId(); }
  void set(String? id){
    state=id;
    if(id!=null) LocalStorage.saveActiveProviderId(id);
  }
}

final aiProviderProvider = Provider<AIProvider>((ref){
  final configs = ref.watch(providerConfigsProvider);
  final activeId = ref.watch(activeProviderIdProvider);
  if(configs.isEmpty) return UnconfiguredProvider('未配置任何 Provider，请到 设置 → 添加 Provider');
  ProviderConfig? cfg;
  if(activeId!=null) cfg = configs.where((c)=>c.id==activeId).firstOrNull;
  cfg ??= configs.first;
  if(cfg.baseUrl.trim().isEmpty) return UnconfiguredProvider('Provider "${cfg.name}" 未填写 Base URL，请到设置页补全');
  if(cfg.apiKey.trim().isEmpty) return UnconfiguredProvider('Provider "${cfg.name}" 未填写 API Key，请到设置页补全');
  try{
    return CompatibleProvider(cfg);
  }catch(e){
    return UnconfiguredProvider('Provider 配置错误：$e');
  }
});

// Conversations — 真实持久化，初始为空
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref)=> ConversationsNotifier(ref));
final activeConversationIdProvider = StateProvider<String?>((ref)=> null);

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  final Ref ref;
  ConversationsNotifier(this.ref): super([]){ _load(); }
  Future<void> _load() async {
    final list = await LocalStorage.loadConversations();
    state = list;
    if(list.isNotEmpty && ref.read(activeConversationIdProvider)==null){
      ref.read(activeConversationIdProvider.notifier).state = list.first.id;
    }
  }
  Future<void> _save() async => await LocalStorage.saveConversations(state);

  void newConversation(){
    final activeId = ref.read(activeProviderIdProvider);
    final configs = ref.read(providerConfigsProvider);
    final providerId = activeId ?? (configs.isNotEmpty? configs.first.id: 'none');
    final model = configs.where((c)=>c.id==providerId).firstOrNull?.chatModel ?? 'gpt-4o';
    final id = _uuid.v4();
    final now = DateTime.now();
    final c = Conversation(id:id, title:'新对话', createdAt: now, updatedAt: now, providerId: providerId, model: model);
    state = [c, ...state];
    ref.read(activeConversationIdProvider.notifier).state = id;
    _save();
  }

  void deleteConversation(String id){
    state = state.where((c)=>c.id!=id).toList();
    if(ref.read(activeConversationIdProvider)==id){
      ref.read(activeConversationIdProvider.notifier).state = state.isNotEmpty? state.first.id: null;
    }
    _save();
  }

  void appendMessage(String convId, ChatMessage msg){
    state = [
      for(final c in state)
        if(c.id==convId) c.copyWith(messages: [...c.messages, msg], updatedAt: DateTime.now(), title: c.messages.isEmpty && msg.role==ChatRole.user ? _titleFrom(msg.content) : c.title)
        else c
    ];
    _save();
  }

  void updateLastAssistant(String convId, String content){
    state = [
      for(final c in state)
        if(c.id==convId && c.messages.isNotEmpty) c.copyWith(messages: [...c.messages.sublist(0, c.messages.length-1), ChatMessage(id:c.messages.last.id, role: ChatRole.assistant, content: content, createdAt: c.messages.last.createdAt, model: c.messages.last.model)], updatedAt: DateTime.now())
        else c
    ];
    _save();
  }

  void replaceLastAssistant(String convId, String content){
    // 用于最终定版
    updateLastAssistant(convId, content);
  }

  String _titleFrom(String s){
    final t=s.trim().replaceAll('\n',' ');
    if(t.length>20) return '${t.substring(0,20)}…';
    return t.isEmpty? '新对话': t;
  }
}

final currentConversationProvider = Provider<Conversation?>((ref){
  final list = ref.watch(conversationsProvider);
  final id = ref.watch(activeConversationIdProvider);
  if(id==null) return list.isNotEmpty? list.first: null;
  return list.where((c)=>c.id==id).firstOrNull ?? (list.isNotEmpty? list.first: null);
});

final chatStreamingProvider = StateProvider<bool>((ref)=> false);

// image tasks — 仅真实任务，内存态（可扩展持久化）
final imageTasksProvider = StateNotifierProvider<ImageTasksNotifier, List<ImageTask>>((ref)=> ImageTasksNotifier());
class ImageTasksNotifier extends StateNotifier<List<ImageTask>> {
  ImageTasksNotifier(): super([]);
  void add(ImageTask t)=> state=[t, ...state];
  void update(String id, ImageTask Function(ImageTask) fn)=> state=[for(final p in state) if(p.id==id) fn(p) else p];
  void remove(String id)=> state=state.where((e)=>e.id!=id).toList();
  void clear()=> state=[];
}

// video tasks — 仅真实任务
final videoTasksProvider = StateNotifierProvider<VideoTasksNotifier, List<VideoTask>>((ref)=> VideoTasksNotifier());
class VideoTasksNotifier extends StateNotifier<List<VideoTask>> {
  VideoTasksNotifier(): super([]);
  void add(VideoTask t)=> state=[t, ...state];
  void update(String id, VideoTask Function(VideoTask) fn)=> state=[for(final p in state) if(p.id==id) fn(p) else p];
  void remove(String id)=> state=state.where((e)=>e.id!=id).toList();
  void clear()=> state=[];
}

extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty? null: first; }
