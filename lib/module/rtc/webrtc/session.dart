import 'package:flutter_webrtc/flutter_webrtc.dart';

///
class Session {
  ///
  String pid;

  ///
  String sid;

  ///构造
  Session({this.pid, this.sid});

  // 管道流
  RTCPeerConnection _pc;

  ///
  set pc(RTCPeerConnection pc) {
    this._pc = pc;
  }

  ///
  RTCPeerConnection get pc => _pc;

  //数据通道
  RTCDataChannel _dc;

  ///
  RTCDataChannel get dc => _dc;

  ///
  set dc(RTCDataChannel dc) {
    _dc = dc;
  }

  /// 远程会话集合
  List<RTCIceCandidate> _remoteIceCandidate = [];
  // set remoteCandidates(RTCDataChannel dc) {
  //   _dc = dc;
  // }
  ///
  List<RTCIceCandidate> get remoteCandidates => _remoteIceCandidate;
}
