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

  /// 切换摄像头
  switchCamera() {}

  /// 麦克风操作
  muteMicroPhone(bool bool) {}

  /// 喇叭操作
  muteSpeaker(bool bool) {}
}
