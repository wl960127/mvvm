import 'package:mvvm/pages/common/base.dart';

///
class VideoCallProvider extends BaseProvide {
  ///
  String account = "";

  ///
  String roomID = "";

  ///
  bool isCall = false;

  ///
  bool isFront = true;

  ///
  bool isMuteMic = false;

  ///
  VideoCallProvider(this.account, this.roomID);

  /// 呼叫
  startCall() {}

  /// 切换摄像头
  swictCamera() {}

  /// 改变喇叭状态
  swicthSpeakerState() {}

  /// 改变麦克风状态
  swicthMicrophoneState() {}

  /// 取消呼叫
  closeCall() {}
}
