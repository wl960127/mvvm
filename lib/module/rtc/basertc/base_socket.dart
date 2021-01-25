/// 定义消息回调函数
typedef void OnMessageCallback(dynamic msg);

/// 定义关闭回调函数
typedef void OnCloseCallback(dynamic code, dynamic reason);

/// 定义打开回调函数
typedef void OnOpenCallback();

/// socket 抽象类
abstract class BaseSocket {
//  /打开回调函数
  OnOpenCallback onOpenCallback;

  ///消息回调函数
  OnMessageCallback onMessageCallback;

  ///关闭回调函数
  OnCloseCallback onCloseCallback;

  /// 连接ws
  connect() {}

  /// 发送指令
  send(msg) {}

  /// 断开连接
  close() {}
}
