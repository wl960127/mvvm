import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/p2p_ice_server.dart';
import 'package:mvvm/module/rtc/p2p_socket.dart';

import 'p2p_constraints.dart';
import 'p2p_state.dart';

/// 定义信令状态回调
typedef void SignalingStateCallback(P2PState state);

/// 定义媒体流状回调
typedef void StreamStateCallback(MediaStream stream);

/// 用户列表更新
typedef void UserUpdateCallback(dynamic event);

///
class P2PVideoCall {
  P2PSocket _p2pSocket;
  String _host;
  int _p2pPort = 8000;
  int _turnPort = 9000;

  String _userId = '1222';
  String _userName = 'rtc_01';
  String _roomId = '111111';
  String _sessionId;

  P2PIceServers _p2pIceServers;

  //Json编码
  JsonEncoder _encoder = JsonEncoder();

  //Json解码
  JsonDecoder _decoder = JsonDecoder();

  /// 本地媒体流
  MediaStream _localStream;

  ///信令状态回调函数
  SignalingStateCallback onSignalingStateCallback;

  ///媒体流状态回调函数,本地流
  StreamStateCallback onLocalStream;

  ///媒体流状态回调函数,远端流添加
  StreamStateCallback onAddRemoteStream;

  ///媒体流状态回调函数,远端流移除
  StreamStateCallback onRemoveRemoteStream;

  ///所有成员更新回调函数
  UserUpdateCallback onUserUpdateCallback;

  ///
  P2PVideoCall(this._host, this._p2pPort);

  ///ws连接
  void connect() async {
    var url = "ws://$_host:$_p2pPort/ws";
    _p2pSocket = P2PSocket(url);

    _p2pIceServers = P2PIceServers(_host, _turnPort);
    _p2pIceServers.init();

    _p2pSocket.onOpenCallback = () {
      // this.onSignalingStateCallback(P2PState.connectionOpen);
      print('p2p_video_call onOpen ');
      _send('joinRoom', {
        'name': _userName, //名称
        'id': _userId, //自己Id
        'roomId': _roomId, //房
      });
    };

    _p2pSocket.onMessageCallback = (msg) {
      // print('p2p_video_call 接收到信息 $msg ');
      this._onMessage(_decoder.convert(msg as String));
    };

    _p2pSocket.onCloseCallback = (dynamic code, dynamic reason) {
      print('p2p_video_call 关闭 $code  $reason ');
      // if (this.onSignalingStateCallback != null) {
      //   this.onSignalingStateCallback(P2PState.connectionClosed);
      // }
    };

    await _p2pSocket.connect();
  }

  /// 信令关闭
  close() {
    //关闭Socket
    if (_p2pSocket != null) {
      _p2pSocket.close();
    }
  }

  /// 消息处理
  _onMessage(message) async {
    print('接收到消息 并准备处理 $message');
    Map<String, dynamic> mapData = message as Map<String, dynamic>;
    var data = mapData['data'];
    switch (mapData['msgType'] as String) {
      case 'updateUserList': //更新成员列表
        break;
      case 'offer': //提议Offer消息
        break;
      case 'answer': //应答Answer
        break;
      case 'candidate': //网络Candidate信息
        break;
      case 'leaveRoom': //离开房间消息
        break;
      case 'hangUp': //挂断信息
        break;
      case 'heartPackage': //心跳包
        break;
      default:
        break;
    }
  }

  /// 创建 PeerConnection
  _createPeerConnection(id, media, bool isUseScreen) async {
    _localStream = await _createStream(media, isUseScreen); //创建并获取本地媒体流
    RTCPeerConnection pc = await createPeerConnection(
        _p2pIceServers.iceServers, P2PConstraints.pcConstraints); // //创建PC

    //添加本地流至pc
    await pc.addStream(_localStream);
    // pc 收集到的candidate
    pc.onIceCandidate = (candidate) {};
    // Ice连接状态
    pc.onIceConnectionState = (state) {};
    // 远端流到达
    pc.onAddStream = (stream) {
      if (this.onAddRemoteStream != null) {
        this.onAddRemoteStream(stream);
      }
    };
    // 远端流移除
    pc.onRemoveStream = (stream) {
      if (this.onRemoveRemoteStream != null) {
        this.onRemoveRemoteStream(stream);
      }
    };
  }

  /// 创建媒体流
  Future<MediaStream> _createStream(media, bool isUseScreen) async {
    MediaStream mediaStream = isUseScreen
        ? await navigator.getDisplayMedia(P2PConstraints.mediaConstraints)
        : await navigator.getUserMedia(P2PConstraints.mediaConstraints);

    if (this._localStream != null) {
      this.onLocalStream(mediaStream);
    }
    return mediaStream;
  }

  /// 创建提议Offer
  _createOffer(String id, RTCPeerConnection pc, String media) async {
    try {
      //返回SDP信息
      RTCSessionDescription s =
          await pc.createOffer(P2PConstraints.sdpConstraints);
      //设置本地描述信息
      await pc.setLocalDescription(s);
      //发送Offer至对方
      _send('offer', {
        //对方Id
        'to': id,
        //自己Id
        'from': _userId,
        //SDP数据
        'description': {'sdp': s.sdp, 'type': s.type},
        //会话Id
        'sessionId': this._sessionId,
        //媒体类型
        'media': media,
        'roomId': _roomId, //房间Id
      });
    } catch (e) {
      print(e.toString());
    }
  }

  /// 创建应答
  _createAnswer(String id, RTCPeerConnection pc, String media) async {
    try {
      RTCSessionDescription description =
          await pc.createAnswer(P2PConstraints.sdpConstraints);

      await pc.setLocalDescription(description);
      _send('answer', {
        //对方Id
        'to': id,
        //自己Id
        'from': _userId,
        //SDP数据
        'description': {'sdp': description.sdp, 'type': description.type},
        //会话Id
        'sessionId': this._sessionId,
        //房间Id
        'roomId': _roomId,
      });
    } catch (e) {
      print('_createAnswer 失败 ${e.toString()}');
    }
  }

  /// 挂断
  hangUp() {
    _send('hangUp', {
      'sessionId': this._sessionId,
      'from': this._userId,
      'roomId': _roomId, //房间Id
    });
  }

  /// 发送消息 传入类型及数据
  _send(msgType, data) {
    var request = Map();
    request["msgType"] = msgType;
    request["data"] = data;
    //Json转码后发送
    _p2pSocket.send(_encoder.convert(request));
  }

  /// 切换摄像头
  switchCamera() {}

  /// 麦克风操作
  muteMicroPhone(bool bool) {}

  /// 喇叭操作
  muteSpeaker(bool bool) {}

  /// 开始呼叫
  startCall(String s, String t, {bool isUseScreen = true}) {}
}
