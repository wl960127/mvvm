import 'package:mvvm/module/rtc/basertc/base_socket.dart';

///
abstract class BaseP2PClient {
  BaseSocket _socket;

  /// 构造方法
  BaseP2PClient(this._socket);

  ///视频呼叫
  callVideo() {}

  ///语音呼叫
  callAudio() {}

  /// 结束呼叫
  endCall() {}
}
