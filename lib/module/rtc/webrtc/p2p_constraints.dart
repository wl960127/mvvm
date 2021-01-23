/// 约束条件
class P2PConstraints {
  /// Media 约束条件
  static const Map<String, dynamic> mediaConstraints = {
    //开启音频
    "audio": true,
    "video": {
      "mandatory": {
        //宽度
        "minWidth": '640',
        //高度
        "minHeight": '480',
        //帧率
        "minFrameRate": '30',
      },
      "facingMode": "user",
      "optional": [],
    }
  };

  /// PeerConnection约束
  static const Map<String, dynamic> pcConstraints = {
    'mandatory': {},
    'optional': [
      //如果要与浏览器互通开启DtlsSrtpKeyAgreement
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  /// SDP约束
  static const Map<String, dynamic> sdpConstraints = {
    'mandatory': {
      //是否接收语音数据
      'OfferToReceiveAudio': true,
      //是否接收视频数据
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };
}
