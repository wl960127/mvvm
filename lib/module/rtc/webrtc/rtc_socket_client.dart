import 'rtc_socket.dart';

/// 视频呼叫
class RtcSocketClient {
  //IP地址
  var _host = "192.168.0.186";

  //信令服务器端口
  var _p2pPort = 8000;

  /// ws
  RtcSocket _socket;

  /// Turn服务器端口
  // var _turnPort = 9000;

  ///WebSocket 连接
  connect() async {
    print('WebSocket WebSocket 连接   ');
    var wsUrl = 'ws://$_host:$_p2pPort/ws';
    print('WebSocket $wsUrl   ');
    _socket = RtcSocket(wsUrl);
    _socket.connect();
  }

  /// 断开连接
  close() {
    if (_socket != null) {
      _socket.close();
    }
  }
}
