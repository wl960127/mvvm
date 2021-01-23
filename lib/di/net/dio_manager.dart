import 'package:dio/dio.dart';

import 'entity/error_entity.dart';
import 'log_interceptors.dart';

///
typedef successCallBack = Function(dynamic);

///
typedef errCallBack = Function(ErrorEntity);

///
class DioManager {
  static final DioManager _dioManager = DioManager._internal();

  ///
  factory DioManager() => _dioManager;

  ///
  Dio dio;

  ///
  static Map<String, CancelToken> _cancelTokenMap;

  ///取消请求
  static void cancelRequest(String tag) {
    if (_cancelTokenMap.containsKey(tag)) {
      if (!_cancelTokenMap[tag].isCancelled) {
        _cancelTokenMap[tag].cancel();
      }
      _cancelTokenMap.remove(tag);
    }
  }

  ///
  DioManager._internal() {
    if (dio == null) {
      _cancelTokenMap = Map();
      BaseOptions options = BaseOptions(
          baseUrl: "http://192.168.0.186:8080/admin/",
          //通用部分接口
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          // headers: {
          //   //头部
          // },
          receiveDataWhenStatusError: false,
          connectTimeout: 3000,
          receiveTimeout: 3000);
      dio = Dio(options);
    }
    if (!bool.fromEnvironment("dart.vm.product")) {
      dio.interceptors.add(LogsInterceptors());
    }
  }
  //
  // ///
  // Future request<T>(RequestMethod method, String path,
  //     {Map<String, dynamic> map}) {
  //   return _request<T>(method, path, map: map);
  // }
  //
  // ///
  // Future _request<T>(RequestMethod method, String path,
  //     {Map<String, dynamic> map}) async {
  //   Response response;
  //
  //   if (method == RequestMethod.POST) {
  //     response = await dio.post(path,
  //         data: map, options: Options(method: RequestMethodValues[method]));
  //   } else if (method == RequestMethod.GET) {
  //     response = await dio.get(path,
  //         queryParameters: map,
  //         options: Options(method: RequestMethodValues[method]));
  //   }
  // }

  ///
//   ErrorEntity createErrorEntity(DioError error) {
//     switch (error.type) {
//       case DioErrorType.CANCEL:
//         {
//           return ErrorEntity(code: -1, message: "请求取消");
//         }
//         break;
//       case DioErrorType.CONNECT_TIMEOUT:
//         {
//           return ErrorEntity(code: -1, message: "连接超时");
//         }
//         break;
//       case DioErrorType.SEND_TIMEOUT:
//         {
//           return ErrorEntity(code: -1, message: "请求超时");
//         }
//         break;
//       case DioErrorType.RECEIVE_TIMEOUT:
//         {
//           return ErrorEntity(code: -1, message: "响应超时");
//         }
//         break;
//       case DioErrorType.RESPONSE:
//         {
//           try {
//             int errCode = error.response.statusCode;
//             String errMsg = error.response.statusMessage;
//             return ErrorEntity(code: errCode, message: errMsg);
//             // switch (errCode) {
//             //   case 400:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "请求语法错误");
//             //     }
//             //     break;
//             //   case 403:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "服务器拒绝执行");
//             //     }
//             //     break;
//             //   case 404:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "无法连接服务器");
//             //     }
//             //     break;
//             //   case 405:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "请求方法被禁止");
//             //     }
//             //     break;
//             //   case 500:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "服务器内部错误");
//             //     }
//             //     break;
//             //   case 502:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "无效的请求");
//             //     }
//             //     break;
//             //   case 503:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "服务器挂了");
//             //     }
//             //     break;
//             //   case 505:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "不支持HTTP协议请求");
//             //     }
//             //     break;
//             //   default:
//             //     {
//             //       return ErrorEntity(code: errCode, message: "未知错误");
//             //     }
//             // }
//           } on Exception catch (_) {
//             return ErrorEntity(code: -1, message: "未知错误");
//           }
//         }
//         break;
//       default:
//         {
//           return ErrorEntity(code: -1, message: error.message);
//         }
//     }
//   }
}
