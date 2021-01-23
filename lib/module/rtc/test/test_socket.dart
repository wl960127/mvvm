import 'dart:io';

import 'package:mvvm/module/rtc/basertc/base_socket.dart';

///
class TestSocket implements BaseSocket {
  /// 连接 url
  String _url;

  /// socket对象
  WebSocket _socket;

  ///构造函数
  TestSocket(this._url);

  @override
  connect() async {
    try {
      _socket = await _connectForSelfSigned(_url);
      this?.onOpenCallback();
      _socket.listen((data) {
        // this?.onMessageCallback(data);
      }, onDone: () {
        print("监听数据完成");
        // this?.onCloseCallback(_socket.closeCode, _socket.closeReason);
      }, onError: (error) {
        print("监听数据异常 $error");
        // this?.onCloseCallback(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      // this?.onCloseCallback(500, e.toString());
      print(" 连接失败 ${e.toString()}");
    }
  }

  @override
  send(data) {
    if (_socket != null) {
      _socket.add(data);
      print("p2p_socket 发送 $data");
    }
  }

  @override
  close() {
    if (_socket != null) {
      _socket.close();
    }
  }

  /// 连接ws
  Future<WebSocket> _connectForSelfSigned(String url) async {
    return await WebSocket.connect(url);
  }

  @override
  var onCloseCallback;

  @override
  var onMessageCallback;

  @override
  // TODO: implement onOpenCallback
  get onOpenCallback => throw UnimplementedError();
}
