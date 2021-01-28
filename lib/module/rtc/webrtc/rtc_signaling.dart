import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/webrtc/session_type.dart';
import 'package:mvvm/module/rtc/webrtc/signaling_state.dart';
import 'package:mvvm/util/util.dart';

import 'call_state.dart';
import 'rtc_ice_server.dart';
import 'rtc_socket.dart';
import 'session.dart';
import 'signaling_state.dart';

/// 回调函数
/// 信令状态回调
typedef void SignalingStateCallback(SignalingState state);

/// 呼叫状态回调
typedef void CallStateCallback(Session session, CallSata state);

///  视频流回调
typedef void StreamStateCallback(Session session, MediaStream stream);

/// 其他事件回调
typedef void OtherEventCallback(dynamic event);

///  数据管道消息回调
typedef void DataChannelMessageCallback(
    Session session, RTCDataChannel dc, RTCDataChannelMessage data);

/// 管道回调
typedef void DataChannelCallback(Session session, RTCDataChannel dc);

/// rtc逻辑操作
class RtcSignaling {
  String _host;
  int _p2pPort = 8000;
  int _turnPort = 9000;

  //Json编码
  JsonEncoder _encoder = JsonEncoder();

  //Json解码
  JsonDecoder _decoder = JsonDecoder();

  /// IceServers 配置类
  RtcIceServers _p2pIceServers;
  //  socket 操作类
  RtcSocket _rtcSocket;

  ///
  SignalingStateCallback onSignalingStateChange;

  ///
  CallStateCallback onCallStateChange;

  ///
  StreamStateCallback onLocalStream;

  ///
  StreamStateCallback onAddRemoteStream;

  ///
  StreamStateCallback onRemoveRemoteStream;

  ///
  OtherEventCallback onPeersUpdate;

  ///
  DataChannelMessageCallback onDataChannelMessage;

  ///
  DataChannelCallback onDataChannel;

  /// 自己的userID
  String _userId = randomNumeric(10);

  /// 用户名字
  String _userName = 'rtc_name_${randomNumeric(8)} ';

  String _selfId = randomNumeric(6);

  /// 房间ID
  String _roomId = '1111';

  ///
  RtcSignaling(this._host, this._p2pPort);

  ///ws连接
  void connect() async {
    var url = "ws://$_host:$_p2pPort/ws";
    _rtcSocket = RtcSocket(url);

    //对应于穿透需要配置的地方 默认没有
    _p2pIceServers = RtcIceServers(_host, _turnPort);
    _p2pIceServers.init();

    _rtcSocket.onOpenCallback = () {
      onSignalingStateChange?.call(SignalingState.ConnectionOpen);
      // _send('joinRoom', {
      //   'name': _userName, //名称
      //   'id': _userId, //自己Id
      //   'roomId': _roomId, //房
      // });
    };

    _rtcSocket.onMessageCallback = (msg) {
      // print('p2p_video_call 接收到信息 $msg ');
      this._onMessage(_decoder.convert(msg as String));
    };

    _rtcSocket.onCloseCallback = (dynamic code, dynamic reason) {
      print('p2p_video_call 关闭 $code  $reason ');
      onSignalingStateChange?.call(SignalingState.connectionClose);
    };

    await _rtcSocket.connect();
  }

  /// 信令关闭
  close() {
    //关闭Socket
    if (_rtcSocket != null) {
      _rtcSocket.close();
    }
  }

  /// 消息处理
  _onMessage(message) async {
    print('接收到消息 并准备处理 $message');
    Map<String, dynamic> mapData = message as Map<String, dynamic>;
    var data = mapData['data'];
    switch (mapData['msgType'] as String) {
      case 'updateUserList': //更新成员列表
        List<dynamic> user = data as List<dynamic>;
        // if (this.onUserUpdateCallback != null) {
        //   //回调参数,包括自己Id及成员列表
        //   Map<String, dynamic> event = Map<String, dynamic>();
        //   event['users'] = user;
        //   print('p2p_video_call 更新成员列表 ${data.toString()}');
        //   this.onUserUpdateCallback(event);
        // }
        break;
      case 'offer': //提议Offer消息

        var fromID = data['from'];
        //SDP描述
        var description = data['description'];
        //请求媒体类型
        var media = data['media'];
        //会话Id
        var sessionId = data['sessionId'];
        this._sessionId = sessionId;
        // 信令状态回调
        if (this.onSignalingStateCallback != null) {
          this.onSignalingStateCallback(P2PState.callStateJoinRoom);
        }
        //应应答方创建PeerConnection
        var pc = await _createPeerConnection(fromID, media, false);
        // pc放入集合
        _peerConnections[fromID] = pc;
        // 应答方pc设置远端SDP描述
        await pc.setRemoteDescription(RTCSessionDescription(
            description['sdp'] as String, description['type'] as String));
        //应答方创建应答信息
        await _createAnswer(fromID as String, pc, media as String);
        if (this._remoteCandidates.isNotEmpty) {
          //如果有Candidate缓存数据,将其添加至应答方PC对象里
          _remoteCandidates.forEach((element) async {
            await pc.addCandidate(element);
          });
          _remoteCandidates.clear();
        }
        break;
      case 'answer': //应答Answer
        var fromID = data['from'];
        //SDP描述
        var description = data['description'];
        //取出提议方PeerConnection
        var pc = _peerConnections[fromID];
        if (pc != null) {
          //提议方PC设置远端SDP描述
          await pc.setRemoteDescription(RTCSessionDescription(
              description['sdp'] as String, description['type'] as String));
        }
        break;
      case 'candidate': //网络Candidate信息
        //发送消息方Id
        var fromID = data['from'];
        //读取数据
        var candidateMap = data['candidate'];
        //根据Id获取PeerConnection
        var pc = _peerConnections[fromID];
        //生成Candidate对象
        RTCIceCandidate candidate = RTCIceCandidate(
            candidateMap['candidate'] as String,
            candidateMap['sdpMid'] as String,
            candidateMap['sdpMLineIndex'] as int);
        if (pc != null) {
          //将对方发过来的Candidate添加至PC对象里
          await pc.addCandidate(candidate);
        } else {
          //当应答方PC还未建立时,将Candidate数据暂时缓存起来
          _remoteCandidates.add(candidate);
        }
        break;
      case 'leaveRoom': //离开房间消息
        print('离开:');
        var id = data;
        print('离开: $id');
        this.leave(id);
        break;
      case 'hangUp': //挂断信息
        var id = data['to'];
        var sessionId = data['sessionId'];
        print('挂断:  $sessionId');
        this.leave(id);
        break;
      case 'heartPackage': //心跳包
        break;
      default:
        break;
    }
  }

  /// 创建 PeerConnection
  Future<RTCPeerConnection> _createPeerConnection(
      remoteID, media, bool isUseScreen) async {
    _localStream = await _createStream(media, isUseScreen); //创建并获取本地媒体流

    if (this._localStream != null) {
      this.onLocalStream(_localStream);
    }
    RTCPeerConnection pc = await createPeerConnection(
        _p2pIceServers.iceServers, P2PConstraints.pcConstraints); // //创建PC

    //添加本地流至pc
    await pc.addStream(_localStream);
    // pc 收集到的candidate (候选人数据)
    pc.onIceCandidate = (candidate) {
      // 发送至对方
      _send('candidate', {
        //对方Id
        'to': remoteID,
        //自己Id
        'from': _userId,
        //Candidate数据
        'candidate': {
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        },
        //会话Id
        'sessionId': this._sessionId,
        'roomId': _roomId, //房间Id
      });
    };
    // Ice连接状态
    pc.onIceConnectionState = (state) {
      print(' Ice连接状态 $state  ');
    };
    // 远端流到达
    pc.onAddStream = (stream) {
      print('远端视频流到达 ${stream == null}  ${onAddRemoteStream == null}');

      if (this.onAddRemoteStream != null) {
        this.onAddRemoteStream(stream);
      }
    };
    // 远端流移除
    pc.onRemoveStream = (stream) {
      print('远端视频流移除  ${stream == null ? ' 空 ' : ' 不为空'}');

      if (this.onRemoveRemoteStream != null) {
        this.onRemoveRemoteStream(stream);
      }
    };

    return pc;
  }

  /// 创建媒体流
  Future<MediaStream> _createStream(media, bool isUseScreen) async {
    return isUseScreen
        ? await navigator.getDisplayMedia(P2PConstraints.mediaConstraints)
        : await navigator.getUserMedia(P2PConstraints.mediaConstraints);

    // return mediaStream;
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
  _createAnswer(String remoteID, RTCPeerConnection pc, String media) async {
    try {
      RTCSessionDescription description =
          await pc.createAnswer(P2PConstraints.sdpConstraints);

      await pc.setLocalDescription(description);
      _send('answer', {
        //对方Id
        'to': remoteID,
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
    _rtcSocket.send(_encoder.convert(request));
  }

  /// 切换摄像头
  switchCamera() {}

  /// 麦克风操作
  muteMicroPhone(bool bool) {}

  /// 喇叭操作
  muteSpeaker(bool bool) {}

  /// 开始呼叫
  startCall(String remoteUserId, String mediaType,
      {bool isUseScreen = false}) async {
    var sessionID = _selfId + '-' + remoteUserId;
    //创建会话
    Session session = await _createSession();
    //信令状态
  }

  ///挂断/离开
  void leave(id) {}

  _createSession(
      {Session session,
      String peerID,
      String sessionID,
      SessionType sessionType,
      bool screenSharing}) async {
    var newSession = session ?? Session(sid: sessionID, pid: peerID);
    if (sessionType != SessionType.data) {}
  }
}
