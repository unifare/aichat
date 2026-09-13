
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/provider_config.dart';

class LocalStorage {
  static const _kProviders='aichat_providers';
  static const _kActiveProvider='aichat_active_provider';
  static const _secure = FlutterSecureStorage();

  static Future<List<ProviderConfig>> loadProviders() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProviders);
    if(raw==null) return _defaults();
    try{
      final list = jsonDecode(raw) as List;
      return list.map((e)=>ProviderConfig.fromJson(Map<String,dynamic>.from(e))).toList();
    }catch(_){ return _defaults(); }
  }

  static Future<void> saveProviders(List<ProviderConfig> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProviders, jsonEncode(list.map((e)=>e.toJson()).toList()));
  }

  static Future<String?> loadActiveProviderId() async => (await SharedPreferences.getInstance()).getString(_kActiveProvider);
  static Future<void> saveActiveProviderId(String id) async => (await SharedPreferences.getInstance()).setString(_kActiveProvider, id);

  static Future<String> readSecure(String key) async => await _secure.read(key:key) ?? '';
  static Future<void> writeSecure(String key,String value) async => await _secure.write(key:key, value:value);

  static List<ProviderConfig> _defaults()=> const [
    ProviderConfig(id:'openai',name:'OpenAI',baseUrl:'https://api.openai.com/v1',chatModel:'gpt-4o',imageModel:'dall-e-3',videoModel:'sora'),
    ProviderConfig(id:'compat',name:'OpenAI Compatible · 自建网关',baseUrl:'https://ai.company.local/v1',chatModel:'gpt-4o',imageModel:'sd-xl',videoModel:'sora'),
  ];
}
