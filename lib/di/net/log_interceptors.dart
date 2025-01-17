import 'package:dio/dio.dart';

///
class LogsInterceptors extends InterceptorsWrapper {
  @override
  onRequest(RequestOptions options) async {
    print("\n================== 请求数据 ==========================");
    print("LogsInterceptors 请求baseUrl：${options.baseUrl}");
    print("LogsInterceptors 请求url：${options.path}");
    print('LogsInterceptors 请求头: ' + options.headers.toString());
    if (options.data != null) {
      print('\nLogsInterceptors请求参数: ' + options.data.toString());
    }
    print("================== 请求数据结束 ==========================\n");
    return options;
  }

  @override
  onResponse(Response response) async {
    print("\n================== 响应数据 ==========================");

    if (response != null) {
      var responseStr = response.toString();
      print("LogsInterceptors  onResponse " + responseStr);
    }
    print("================== 响应数据结束 ==========================\n");

    return response; // continue
  }

  @override
  onError(DioError err) async {
    print("\n================== 错误响应数据 ======================");
    print('LogsInterceptors 请求异常: ' + err.toString());
    print('LogsInterceptors 请求异常信息: ' + err.response?.toString() ?? " 无效数据 ");
    print("================== 错误响应数据结束 ======================\n");

    return err;
  }
}
