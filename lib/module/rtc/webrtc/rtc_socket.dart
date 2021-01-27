import 'dart:io';

/// 定义消息回调函数
typedef void OnMessageCallback(dynamic msg);

/// 定义关闭回调函数
typedef void OnCloseCallback(dynamic code, dynamic reason);

/// 定义打开回调函数
typedef void OnOpenCallback();

/// socket 连接
class RtcSocket {
  /// 连接 url
  String _url;

  /// socket对象
  WebSocket _socket;

  ///打开回调函数
  OnOpenCallback onOpenCallback;

  ///消息回调函数
  OnMessageCallback onMessageCallback;

  ///关闭回调函数
  OnCloseCallback onCloseCallback;

  ///构造函数
  RtcSocket(this._url);

  /// 连接ws
  connect() async {
    try {
      _socket = await _connectForSelfSigned(_url);
      this?.onOpenCallback();
      _socket.listen((data) {
        this?.onMessageCallback(data);
      }, onDone: () {
        print("监听数据完成");
        this?.onCloseCallback(_socket.closeCode, _socket.closeReason);
      }, onError: (error) {
        print("监听数据异常 $error");
        this?.onCloseCallback(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      this?.onCloseCallback(500, e.toString());
      print(" 连接失败 ${e.toString()}");
    }
  }

  /// 发送socket信息
  send(data) {
    if (_socket != null) {
      _socket.add(data);
      print("p2p_socket 发送 $data");
    }
  }

  /// 断开连接
  close() {
    if (_socket != null) {
      _socket.close();
    }
  }

  /// 连接ws
  Future<WebSocket> _connectForSelfSigned(String url) async {
    return await WebSocket.connect(url);
  }
}
