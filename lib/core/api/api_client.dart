
import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio dio;
  ApiClient({required String baseUrl, required String apiKey, Duration timeout=const Duration(seconds: 30)}): dio=Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: timeout,
    receiveTimeout: timeout,
    headers: {
      if(apiKey.isNotEmpty) 'Authorization':'Bearer $apiKey',
      'Content-Type':'application/json',
    },
  )){
    dio.interceptors.add(LogInterceptor(requestBody:true, responseBody:true));
  }

  Future<Map<String,dynamic>> postJson(String path, Map<String,dynamic> data) async {
    try{
      final res = await dio.post(path, data: data);
      if(res.data is Map) return Map<String,dynamic>.from(res.data);
      return {'data': res.data};
    } on DioException catch(e){
      throw ApiException(e.message ?? 'network error', statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String,dynamic>> getJson(String path) async {
    try{
      final res = await dio.get(path);
      if(res.data is Map) return Map<String,dynamic>.from(res.data);
      return {'data': res.data};
    } on DioException catch(e){
      throw ApiException(e.message ?? 'network error', statusCode: e.response?.statusCode);
    }
  }
}
