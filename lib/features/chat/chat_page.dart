
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat_message.dart';
import '../../providers/app_providers.dart';
import '../../app/theme.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});
  @override ConsumerState<ChatPage> createState()=> _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = Uuid();
  String _selectedModel='';
  bool _sending=false;

  @override void initState(){ super.initState(); _input.addListener(()=> setState((){})); WidgetsBinding.instance.addPostFrameCallback((_){ _syncModel(); }); }
  void _syncModel(){
    final configs = ref.read(providerConfigsProvider);
    final activeId = ref.read(activeProviderIdProvider);
    final active = configs.where((c)=>c.id==activeId).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    if(active!=null && _selectedModel.isEmpty) setState(()=> _selectedModel=active.chatModel);
  }
  @override void didChangeDependencies(){ super.didChangeDependencies(); _syncModel(); }
  @override void dispose(){ _input.dispose(); _scroll.dispose(); super.dispose(); }

  bool get _canSend => _input.text.trim().isNotEmpty && !_sending;

  Future<void> _send() async {
    final text = _input.text.trim();
    if(text.isEmpty || _sending) return;
    final configs = ref.read(providerConfigsProvider);
    if(configs.isEmpty){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('未配置 Provider，无法发送。请先去设置页添加。'),
        action: SnackBarAction(label:'去设置', onPressed: ()=> context.go('/settings')),
      ));
      return;
    }
    final conv = ref.read(currentConversationProvider);
    String convId;
    if(conv==null){
      ref.read(conversationsProvider.notifier).newConversation();
      await Future.delayed(const Duration(milliseconds:50));
      convId = ref.read(activeConversationIdProvider) ?? ref.read(conversationsProvider).first.id;
      if(_selectedModel.isEmpty){
        final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
        _selectedModel = active.chatModel;
      }
    } else {
      convId = conv.id;
    }
    if(_selectedModel.isEmpty){
      final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
      _selectedModel = active.chatModel;
    }

    final userMsg = ChatMessage(id:_uuid.v4(), role: ChatRole.user, content: text, createdAt: DateTime.now());
    ref.read(conversationsProvider.notifier).appendMessage(convId, userMsg);
    _input.clear();
    setState(()=> _sending=true);
    ref.read(chatStreamingProvider.notifier).state=true;

    // 占位 assistant 消息，内容由流式增量填充
    final assistantId = _uuid.v4();
    final placeholder = ChatMessage(id:assistantId, role: ChatRole.assistant, content:'', createdAt: DateTime.now(), model:_selectedModel);
    ref.read(conversationsProvider.notifier).appendMessage(convId, placeholder);

    // 收集真实历史（含刚发的 user）
    final historyConv = ref.read(conversationsProvider).where((c)=>c.id==convId).firstOrNull;
    final trimmedHistory = historyConv==null? [userMsg] : historyConv.messages.where((m)=>m.id!=assistantId).toList();

    final provider = ref.read(aiProviderProvider);
    try{
      String acc='';
      await for(final chunk in provider.chatStream(messages: trimmedHistory, model: _selectedModel)){
        acc = chunk;
        ref.read(conversationsProvider.notifier).updateLastAssistant(convId, acc);
        // 轻量滚动到底
        if(_scroll.hasClients){
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds:120), curve: Curves.easeOut);
        }
      }
      if(acc.trim().isEmpty){
        ref.read(conversationsProvider.notifier).updateLastAssistant(convId, '（服务端返回空内容）');
      }
    }catch(e){
      final msg = e.toString().replaceFirst('Exception:','').trim();
      ref.read(conversationsProvider.notifier).updateLastAssistant(convId, '请求失败：$msg\n\n请检查 设置 → Provider 的 Base URL / Endpoint / API Key 是否正确，然后重试。');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败：$msg')));
    } finally {
      ref.read(chatStreamingProvider.notifier).state=false;
      if(mounted) setState(()=> _sending=false);
      if(_scroll.hasClients){
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds:200), curve: Curves.easeOut);
      }
    }
  }

  @override Widget build(BuildContext context){
    final conv = ref.watch(currentConversationProvider);
    final configs = ref.watch(providerConfigsProvider);
    final hasProvider = configs.isNotEmpty;
    final streaming = ref.watch(chatStreamingProvider);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w<600;
    // 同步 model 下拉
    if(hasProvider && _selectedModel.isEmpty){
      final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
      WidgetsBinding.instance.addPostFrameCallback((_)=> setState(()=> _selectedModel=active.chatModel));
    }

    return Column(children:[
      // 未配置提示条
      if(!hasProvider)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.12), border: const Border(bottom: BorderSide(color: Color(0xFFF59E0B)))),
          child: Row(children:[
            const Icon(Icons.warning_amber_rounded, size:18, color: Color(0xFFF59E0B)),
            const SizedBox(width:8),
            const Expanded(child: Text('未配置任何 Provider，无法发起请求。请先去设置页添加 Base URL 与 API Key。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B)))),
            const SizedBox(width:8),
            FilledButton(onPressed: ()=> context.go('/settings'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('去设置', style: TextStyle(fontSize:12))),
          ]),
        ),
      // 顶部信息栏
      Container(
        padding: const EdgeInsets.fromLTRB(16,10,16,10),
        decoration: const BoxDecoration(color: Color(0x99141C2B), border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children:[
          Text(conv==null? '对话': conv.title, maxLines:1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile?13:14, letterSpacing:-0.2)),
          if(conv!=null) ...[
            const SizedBox(width:8),
            Text('· ${conv.messages.length} 条', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
          ],
          const Spacer(),
          if(hasProvider) ...[
            DropdownButton<String>(
              value: _selectedModel.isEmpty? null: _selectedModel,
              hint: const Text('选择模型', style: TextStyle(fontSize:12, color: AppColors.muted)),
              underline: const SizedBox(),
              style: const TextStyle(fontSize:13, color: AppColors.fg),
              dropdownColor: AppColors.surface,
              items: _modelItems(configs),
              onChanged: (v){ if(v!=null) setState(()=>_selectedModel=v); },
            ),
            const SizedBox(width:8),
          ],
          Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border), color: const Color(0x0AFFFFFF)), child: Text(streaming? '生成中…': '就绪', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
        ]),
      ),
      Expanded(
        child: conv==null
          ? _emptyNoConversation(hasProvider)
          : conv.messages.isEmpty
            ? _emptyNoMessages(hasProvider)
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16,16,16,16),
                itemCount: conv.messages.length,
                itemBuilder: (c,i){
                  final msg = conv.messages[i];
                  final isLast = i==conv.messages.length-1;
                  final isStreamingLast = isLast && msg.role==ChatRole.assistant && streaming && msg.content.isEmpty;
                  if(isStreamingLast){
                    return const Align(alignment: Alignment.centerLeft, child: _TypingIndicator());
                  }
                  return _bubble(msg, isLast && streaming);
                },
              ),
      ),
      // 输入区 — 始终可见，人性化
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: Column(children:[
          Row(crossAxisAlignment: CrossAxisAlignment.end, children:[
            Tooltip(
              message: '附件（未实现）',
              child: Container(width:36,height:36, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.attach_file, size:18, color: AppColors.muted)),
            ),
            const SizedBox(width:8),
            Expanded(child: TextField(
              controller: _input,
              minLines:1, maxLines:5,
              style: const TextStyle(fontSize:14),
              decoration: InputDecoration(
                hintText: hasProvider? '输入消息…  Shift+Enter 换行，Enter 发送': '请先去设置页配置 Provider 后再输入',
                filled:true, fillColor: AppColors.surface2,
                suffixIcon: _input.text.isNotEmpty? IconButton(icon: const Icon(Icons.clear, size:18), onPressed: ()=> _input.clear()): null,
              ),
              enabled: hasProvider && !_sending,
              onSubmitted: hasProvider? (_)=> _send(): null,
              onEditingComplete: (){},
            )),
            const SizedBox(width:8),
            SizedBox(width:42,height:42, child: FilledButton(
              onPressed: _canSend && hasProvider? _send: null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), disabledBackgroundColor: AppColors.surface2, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _sending? const SizedBox(width:18,height:18, child: CircularProgressIndicator(strokeWidth:2, color: Color(0xFF111827))): const Icon(Icons.send, size:18),
            )),
          ]),
          const SizedBox(height:8),
          Row(children:[
            const Text('Enter 发送 · Shift+Enter 换行', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
            const Spacer(),
            if(_input.text.isNotEmpty) Text('${_input.text.length} 字', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
          ]),
        ]),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> _modelItems(List configs){
    final models = <String>{};
    for(final c in configs){ models.add(c.chatModel); }
    // 额外常用模型供选择，但仍以真实请求为准
    for(final m in ['gpt-4o','gpt-4o-mini','claude-3.5-sonnet','gemini-1.5-pro']){
      models.add(m);
    }
    if(_selectedModel.isNotEmpty) models.add(_selectedModel);
    return models.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:13)))).toList();
  }

  Widget _emptyNoConversation(bool hasProvider){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children:[
          Container(width:64,height:64, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withValues(alpha:0.2))), child: const Icon(Icons.chat_bubble_outline, color: AppColors.accent, size:28)),
          const SizedBox(height:14),
          const Text('还没有会话', style: TextStyle(fontWeight: FontWeight.w700, fontSize:14)),
          const SizedBox(height:6),
          Text(hasProvider? '点击“新对话”开始，所有记录将保存在本地。': '请先到 设置 页添加 Provider，再创建会话。', style: const TextStyle(fontSize:13, color: AppColors.muted), textAlign: TextAlign.center),
          const SizedBox(height:16),
          if(hasProvider)
            FilledButton.icon(onPressed: ()=> ref.read(conversationsProvider.notifier).newConversation(), icon: const Icon(Icons.add), label: const Text('新对话'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827))),
          if(!hasProvider)
            FilledButton.icon(onPressed: ()=> context.go('/settings'), icon: const Icon(Icons.settings), label: const Text('去设置'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827))),
        ]),
      ),
    );
  }

  Widget _emptyNoMessages(bool hasProvider){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children:[
          const Icon(Icons.waving_hand_outlined, color: AppColors.muted, size:28),
          const SizedBox(height:10),
          const Text('开始对话', style: TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
          const SizedBox(height:6),
          const Text('在下方输入你的问题，服务端将返回回答。', style: TextStyle(fontSize:13, color: AppColors.muted), textAlign: TextAlign.center),
          const SizedBox(height:12),
          Wrap(spacing:8, runSpacing:8, alignment: WrapAlignment.center, children:[
            _promptChip('帮我写一个 Dio 拦截器，支持 token 刷新'),
            _promptChip('用 Riverpod 管理 Provider 配置的最佳实践'),
            _promptChip('解释一下 OpenAI Compatible 协议'),
          ]),
          if(!hasProvider) ...[
            const SizedBox(height:12),
            const Text('当前未配置 Provider，发送将提示去设置。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFFF59E0B))),
          ],
        ]),
      ),
    );
  }

  Widget _promptChip(String t){
    return ActionChip(
      label: Text(t, style: const TextStyle(fontSize:12)),
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.surface2,
      onPressed: ()=> _input.text=t,
    );
  }

  Widget _bubble(ChatMessage msg, bool isStreaming){
    final isUser = msg.role==ChatRole.user;
    return Align(
      alignment: isUser? Alignment.centerRight: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser? 520: 640),
        margin: const EdgeInsets.only(bottom:12),
        padding: const EdgeInsets.fromLTRB(12,10,12,10),
        decoration: BoxDecoration(
          color: isUser? AppColors.accent: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser? AppColors.accent: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[
            Text(isUser? '你 · ${_fmt(msg.createdAt)}': 'AI · ${msg.model??'—'} · ${_fmt(msg.createdAt)}', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: isUser? const Color(0xB2111827): AppColors.muted)),
            const Spacer(),
            if(!isUser && msg.content.isNotEmpty)
              InkWell(
                onTap: ()async{
                  await Clipboard.setData(ClipboardData(text: msg.content));
                  if(!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
                },
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy, size:14, color: AppColors.muted)),
              ),
          ]),
          const SizedBox(height:6),
          if(msg.content.isEmpty && !isUser && isStreaming)
            const Row(children:[ SizedBox(width:14,height:14, child: CircularProgressIndicator(strokeWidth:2, color: AppColors.accent)), SizedBox(width:8), Text('正在生成…', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted))])
          else if(msg.content.contains('```') || msg.content.contains('**') || msg.content.contains('`'))
            MarkdownBody(
              data: msg.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: isUser? const Color(0xFF111827): AppColors.fg, fontSize:14, height:1.6),
                code: const TextStyle(backgroundColor: Color(0xFF101727), color: Color(0xFFE2E8F0), fontFamily:'JetBrainsMono', fontSize:12),
                codeblockDecoration: BoxDecoration(color: const Color(0xFF101727), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                blockquoteDecoration: BoxDecoration(color: AppColors.surface, border: Border(left: BorderSide(color: AppColors.accent, width:3))),
              ),
              selectable: true,
            )
          else
            SelectableText(msg.content.isEmpty? '…': msg.content, style: TextStyle(color: isUser? const Color(0xFF111827): AppColors.fg, fontSize:14, height:1.6)),
          if(isStreaming && msg.content.isNotEmpty)
            Container(width:8,height:14, margin: const EdgeInsets.only(top:4), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }

  String _fmt(DateTime d)=> '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: const Row(mainAxisSize: MainAxisSize.min, children:[
        SizedBox(width:16,height:16, child: CircularProgressIndicator(strokeWidth:2, color: AppColors.accent)),
        SizedBox(width:8),
        Text('正在生成…', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)),
      ]),
    );
  }
}
extension _FO<E> on Iterable<E>{ E? get firstOrNull => isEmpty? null: first; }
