
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
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
  String _selectedModel='gpt-4o';

  @override void dispose(){ _input.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _input.text.trim();
    if(text.isEmpty) return;
    final conv = ref.read(currentConversationProvider);
    if(conv==null) return;
    final userMsg = ChatMessage(id:_uuid.v4(), role: ChatRole.user, content: text, createdAt: DateTime.now());
    ref.read(conversationsProvider.notifier).appendMessage(conv.id, userMsg);
    _input.clear();
    // streaming
    ref.read(chatStreamingProvider.notifier).state=true;
    ref.read(chatStreamingTextProvider.notifier).state='';
    final assistantId = _uuid.v4();
    final placeholder = ChatMessage(id:assistantId, role: ChatRole.assistant, content:'', createdAt: DateTime.now(), model:_selectedModel);
    ref.read(conversationsProvider.notifier).appendMessage(conv.id, placeholder);

    final provider = ref.read(aiProviderProvider);
    final history = [...conv.messages, userMsg];
    try{
      await for(final chunk in provider.chatStream(messages: history, model: _selectedModel)){
        ref.read(chatStreamingTextProvider.notifier).state=chunk;
        ref.read(conversationsProvider.notifier).updateLastAssistant(conv.id, chunk);
        await Future.delayed(const Duration(milliseconds:1));
        if(_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }catch(e){
      ref.read(conversationsProvider.notifier).updateLastAssistant(conv.id, '请求失败：$e');
    } finally {
      ref.read(chatStreamingProvider.notifier).state=false;
    }
    if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds:200), curve: Curves.easeOut);
  }

  @override Widget build(BuildContext context){
    final conv = ref.watch(currentConversationProvider);
    final streaming = ref.watch(chatStreamingProvider);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w<600;
    return Column(children:[
      // header
      Container(
        padding: const EdgeInsets.fromLTRB(16,12,16,12),
        decoration: const BoxDecoration(color: Color(0x99141C2B), border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children:[
          Text('对话 · 流式输出', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile?14:15, letterSpacing:-0.2)),
          const Spacer(),
          DropdownButton<String>(
            value: _selectedModel,
            underline: const SizedBox(),
            style: const TextStyle(fontSize:13, color: AppColors.fg),
            dropdownColor: AppColors.surface,
            items: const [
              DropdownMenuItem(value:'gpt-4o', child: Text('gpt-4o')),
              DropdownMenuItem(value:'claude-3.5-sonnet', child: Text('claude-3.5-sonnet')),
              DropdownMenuItem(value:'gemini-1.5-pro', child: Text('gemini-1.5-pro')),
              DropdownMenuItem(value:'custom-compatible', child: Text('custom-compatible')),
            ],
            onChanged: (v){ if(v!=null) setState(()=>_selectedModel=v); },
          ),
          const SizedBox(width:8),
          Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border), color: const Color(0x0AFFFFFF)), child: const Text('Streaming · 开', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
          const SizedBox(width:6),
          Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border), color: const Color(0x0AFFFFFF)), child: const Text('上下文 12k', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
        ]),
      ),
      Expanded(
        child: conv==null
          ? const Center(child: Text('还没有会话，点击“新对话”开始', style: TextStyle(color: AppColors.muted)))
          : conv.messages.isEmpty
            ? _empty()
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16,16,16,16),
                itemCount: conv.messages.length + (streaming?1:0),
                itemBuilder: (c,i){
                  if(streaming && i==conv.messages.length){
                    final t = ref.watch(chatStreamingTextProvider);
                    if(t.isEmpty) return const SizedBox();
                  }
                  final msg = conv.messages[i.clamp(0, conv.messages.length-1)];
                  // when streaming, last message is being updated already
                  return _bubble(msg);
                },
              ),
      ),
      // composer - always visible
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: Column(children:[
          Row(crossAxisAlignment: CrossAxisAlignment.end, children:[
            Container(width:36,height:36, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.attach_file, size:18, color: AppColors.muted)),
            const SizedBox(width:8),
            Expanded(child: TextField(
              controller: _input,
              minLines:1, maxLines:4,
              style: const TextStyle(fontSize:14),
              decoration: InputDecoration(hintText: '输入消息…  支持 Markdown、代码块、图片粘贴', filled:true, fillColor: AppColors.surface2),
              onSubmitted: (_)=> _send(),
            )),
            const SizedBox(width:8),
            SizedBox(width:42,height:42, child: FilledButton(onPressed: _send, style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Icon(Icons.send, size:18))),
          ]),
          const SizedBox(height:8),
          Row(children:[
            const Text('Enter 发送 · Shift+Enter 换行 · / 唤起指令', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: const Text('Dio', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
            const SizedBox(width:6),
            Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: const Text('Riverpod', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
          ]),
        ]),
      ),
    ]);
  }

  Widget _empty(){
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, style: BorderStyle.solid), color: const Color(0x05112233)),
        child: Column(children:[
          const Text('还没有消息', style: TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
          const SizedBox(height:6),
          const Text('从下方输入框开始，或试试示例提示词', style: TextStyle(fontSize:13, color: AppColors.muted)),
          const SizedBox(height:12),
          Wrap(spacing:8, children:[
            OutlinedButton(onPressed: ()=> _input.text='帮我写一个 Dio 拦截器', child: const Text('Dio 拦截器')),
            OutlinedButton(onPressed: ()=> _input.text='生成一张赛博城市', child: const Text('生成图片')),
            OutlinedButton(onPressed: ()=> _input.text='生成 10s 跑车视频', child: const Text('生成视频')),
          ]),
        ]),
      ),
    );
  }

  Widget _bubble(ChatMessage msg){
    final isUser = msg.role==ChatRole.user;
    return Align(
      alignment: isUser? Alignment.centerRight: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser? 520: 560),
        margin: const EdgeInsets.only(bottom:12),
        padding: const EdgeInsets.fromLTRB(12,10,12,10),
        decoration: BoxDecoration(
          color: isUser? AppColors.accent: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser? AppColors.accent: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text(isUser? '你 · ${_fmt(msg.createdAt)}': 'AI · ${msg.model??'gpt-4o'} · ${_fmt(msg.createdAt)}', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: isUser? const Color(0xB2111827): AppColors.muted)),
          const SizedBox(height:6),
          if(msg.content.contains('```') || msg.content.contains('`provider.chat`'))
            MarkdownBody(
              data: msg.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: isUser? const Color(0xFF111827): AppColors.fg, fontSize:14, height:1.6),
                code: TextStyle(backgroundColor: const Color(0xFF101727), color: isUser? const Color(0xFF111827): const Color(0xFFE2E8F0), fontFamily:'JetBrainsMono', fontSize:12),
                codeblockDecoration: BoxDecoration(color: const Color(0xFF101727), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              ),
              selectable: true,
            )
          else
            SelectableText(msg.content, style: TextStyle(color: isUser? const Color(0xFF111827): AppColors.fg, fontSize:14, height:1.6)),
        ]),
      ),
    );
  }

  String _fmt(DateTime d)=> '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
