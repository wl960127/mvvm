import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mvvm/widgets/toast.dart';

///
/// 对错误 [e] 进行分发处理
dispatchFailure(BuildContext context, dynamic e) {
  var message = e.toString();
  if (e is DioError) {
    switch (e.type) {
      case DioErrorType.CANCEL:
        message = "请求取消";
        break;
      case DioErrorType.CONNECT_TIMEOUT:
        message = "连接超时";
        break;
      case DioErrorType.SEND_TIMEOUT:
        message = "请求超时";
        break;
      case DioErrorType.RECEIVE_TIMEOUT:
        message = "响应超时";
        break;
      case DioErrorType.RESPONSE:
        {
          try {
            int errCode = e.response.statusCode;
            switch (errCode) {
              case 400:
                message = "请求语法错误";
                break;
              case 403:
                message = "服务器拒绝执行";
                break;
              case 404:
                message = "无法连接服务器";
                break;
              case 405:
                message = "请求方法被禁止";
                break;
              case 500:
                message = "服务器内部错误";
                break;
              case 502:
                message = "无效的请求";
                break;
              case 503:
                message = "服务器挂了";
                break;
              case 505:
                message = "不支持HTTP协议请求";
                break;
              default:
                message = "未知错误";
            }
          } on Exception catch (_) {
            message = "未知错误";
          }
        }
        break;
      default:
        message = "未知错误";
    }
  }
  print("error ：" + message);
  if (context != null) {
    Toast.show(message, context, type: Toast.ERROR);
  }
}
