
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/provider_config.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';

class LocalStorage {
  static const _kProviders='aichat_providers_v2';
  static const _kActiveProvider='aichat_active_provider_v2';
  static const _kConversations='aichat_conversations_v2';
  static const _secure = FlutterSecureStorage();

  // providers: JSON in SharedPreferences, apiKey 额外走 secure storage
  static Future<List<ProviderConfig>> loadProviders() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProviders);
    if(raw==null) return [];
    try{
      final list = jsonDecode(raw) as List;
      final configs = <ProviderConfig>[];
      for(final e in list){
        final m = Map<String,dynamic>.from(e);
        final id = m['id'] as String;
        // apiKey 从 secure 读，覆盖 JSON 里的占位
        final secureKey = await _secure.read(key: _secureKey(id));
        configs.add(ProviderConfig.fromJson({...m, 'apiKey': secureKey ?? m['apiKey'] ?? ''}));
      }
      return configs;
    }catch(_){ return []; }
  }

  static Future<void> saveProviders(List<ProviderConfig> list) async {
    final sp = await SharedPreferences.getInstance();
    // 写 secure
    for(final c in list){
      if(c.apiKey.isNotEmpty) await _secure.write(key: _secureKey(c.id), value: c.apiKey);
      else await _secure.delete(key: _secureKey(c.id));
    }
    // JSON 中不落明文 key
    final sanitized = list.map((e){ final j=e.toJson(); j['apiKey']=''; return j; }).toList();
    await sp.setString(_kProviders, jsonEncode(sanitized));
  }

  static String _secureKey(String id)=> 'aichat_apikey_$id';

  static Future<String?> loadActiveProviderId() async => (await SharedPreferences.getInstance()).getString(_kActiveProvider);
  static Future<void> saveActiveProviderId(String id) async => (await SharedPreferences.getInstance()).setString(_kActiveProvider, id);

  static Future<String> readSecure(String key) async => await _secure.read(key:key) ?? '';
  static Future<void> writeSecure(String key,String value) async => await _secure.write(key:key, value:value);

  // conversations
  static Future<List<Conversation>> loadConversations() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kConversations);
    if(raw==null) return [];
    try{
      final list = jsonDecode(raw) as List;
      return list.map((e){
        final m = Map<String,dynamic>.from(e);
        final msgs = (m['messages'] as List? ?? []).map((x)=> ChatMessage.fromJson(Map<String,dynamic>.from(x))).toList();
        return Conversation(
          id: m['id'], title: m['title'], createdAt: DateTime.parse(m['createdAt']), updatedAt: DateTime.parse(m['updatedAt']),
          providerId: m['providerId'], model: m['model'], messages: msgs,
        );
      }).toList();
    }catch(_){ return []; }
  }

  static Future<void> saveConversations(List<Conversation> list) async {
    final sp = await SharedPreferences.getInstance();
    final data = list.map((c)=> {
      'id': c.id, 'title': c.title, 'createdAt': c.createdAt.toIso8601String(), 'updatedAt': c.updatedAt.toIso8601String(),
      'providerId': c.providerId, 'model': c.model, 'messages': c.messages.map((m)=> m.toJson()).toList(),
    }).toList();
    await sp.setString(_kConversations, jsonEncode(data));
  }
}
