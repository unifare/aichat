
class ProviderConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String chatEndpoint;
  final String imageEndpoint;
  final String videoEndpoint;
  final String chatModel;
  final String imageModel;
  final String videoModel;
  final String apiKey;
  final bool enabled;
  const ProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.chatEndpoint='/chat/completions',
    this.imageEndpoint='/images/generations',
    this.videoEndpoint='/video/generations',
    required this.chatModel,
    required this.imageModel,
    required this.videoModel,
    this.apiKey='',
    this.enabled=true,
  });
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'baseUrl':baseUrl,'chatEndpoint':chatEndpoint,'imageEndpoint':imageEndpoint,'videoEndpoint':videoEndpoint,'chatModel':chatModel,'imageModel':imageModel,'videoModel':videoModel,'apiKey':apiKey,'enabled':enabled};
  factory ProviderConfig.fromJson(Map<String,dynamic> j)=>ProviderConfig(id:j['id'],name:j['name'],baseUrl:j['baseUrl'],chatEndpoint:j['chatEndpoint']??'/chat/completions',imageEndpoint:j['imageEndpoint']??'/images/generations',videoEndpoint:j['videoEndpoint']??'/video/generations',chatModel:j['chatModel']??'gpt-4o',imageModel:j['imageModel']??'dall-e-3',videoModel:j['videoModel']??'sora',apiKey:j['apiKey']??'',enabled:j['enabled']??true);
  ProviderConfig copyWith({String? name,String? baseUrl,String? chatEndpoint,String? imageEndpoint,String? videoEndpoint,String? chatModel,String? imageModel,String? videoModel,String? apiKey,bool? enabled})=>ProviderConfig(id:id,name:name??this.name,baseUrl:baseUrl??this.baseUrl,chatEndpoint:chatEndpoint??this.chatEndpoint,imageEndpoint:imageEndpoint??this.imageEndpoint,videoEndpoint:videoEndpoint??this.videoEndpoint,chatModel:chatModel??this.chatModel,imageModel:imageModel??this.imageModel,videoModel:videoModel??this.videoModel,apiKey:apiKey??this.apiKey,enabled:enabled??this.enabled);
}
