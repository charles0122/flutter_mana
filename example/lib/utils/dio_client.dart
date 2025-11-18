import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mana_dio_inspector/mana_dio_inspector.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  final String _baseUrl = 'https://jsonplaceholder.typicode.com';

  DioClient._internal() {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl));

    _dio.interceptors.add(ManaDioCollector());
  }

  factory DioClient() => _instance;

  Future<Response> _getRequest() async {
    return await _dio.get('/posts/${Random().nextInt(100) + 1}');
  }

  Future<Response> _postRequest() async {
    return await _dio.post(
      '/posts',
      data: {
        'title': 'add post',
        'body': 'this is ${Random().nextInt(100) + 1}',
        'userId': Random().nextInt(10) + 1,
      },
    );
  }

  Future<Response> _putRequest() async {
    final id = Random().nextInt(100) + 1;
    return await _dio.put(
      '/posts/$id',
      data: {
        'id': id,
        'title': 'updated post',
        'body': 'this is $id',
        'userId': Random().nextInt(10) + 1,
      },
    );
  }

  Future<Response> _deleteRequest() async {
    return await _dio.delete('/posts/${Random().nextInt(100) + 1}');
  }

  Future<Response> randomRequest() async {
    final random = Random();
    final method = random.nextInt(4);

    switch (method) {
      case 1:
        debugPrint('执行POST请求');
        return await _postRequest();
      case 2:
        debugPrint('执行PUT请求');
        return await _putRequest();
      case 3:
        debugPrint('执行DELETE请求');
        return await _deleteRequest();
      default:
        debugPrint('执行GET请求');
        return await _getRequest();
    }
  }
}
