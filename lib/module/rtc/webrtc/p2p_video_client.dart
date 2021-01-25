import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/basertc/p2p_state.dart';
import 'package:mvvm/util/util.dart';

import '../webrtc/p2p_constraints.dart';
import 'p2p_ice_server.dart';
import 'p2p_socket.dart';

/// 定义信令状态回调
typedef void SignalingStateCallback(P2PState state);

/// 定义媒体流状回调
typedef void StreamStateCallback(MediaStream stream);

/// 用户列表更新
typedef void UserUpdateCallback(dynamic event);

/// rtc逻辑操作
class P2PVideoClient {
  P2PSocket _p2pSocket;
  String _host;
  int _p2pPort = 8000;
  int _turnPort = 9000;

  /// 自己的userID
  String _userId = randomNumeric(10);

  /// 用户名字
  String _userName = 'rtc_name_${randomNumeric(8)} ';

  /// 房间ID
  String _roomId = '1111';

  //会话ID
  var _sessionId;

  P2PIceServers _p2pIceServers;

  //Json编码
  JsonEncoder _encoder = JsonEncoder();

  //Json解码
  JsonDecoder _decoder = JsonDecoder();

  //PeerConnection集合
  var _peerConnections = Map<dynamic, RTCPeerConnection>();

  //远端Candidate数组
  List<RTCIceCandidate> _remoteCandidates = [];

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
  P2PVideoClient(this._host, this._p2pPort);

  ///ws连接
  void connect() async {
    var url = "ws://$_host:$_p2pPort/ws";
    _p2pSocket = P2PSocket(url);

    //对应于穿透需要配置的地方 默认没有
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
      if (this.onSignalingStateCallback != null) {
        this.onSignalingStateCallback(P2PState.connectionClosed);
      }
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
        List<dynamic> user = data as List<dynamic>;
        if (this.onUserUpdateCallback != null) {
          //回调参数,包括自己Id及成员列表
          Map<String, dynamic> event = Map<String, dynamic>();
          event['users'] = user;
          print('p2p_video_call 更新成员列表 ${data.toString()}');
          this.onUserUpdateCallback(event);
        }
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

    return pc;
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
    _p2pSocket.send(_encoder.convert(request));
  }

  /// 切换摄像头
  switchCamera() {}

  /// 麦克风操作
  muteMicroPhone(bool bool) {}

  /// 喇叭操作
  muteSpeaker(bool bool) {}

  /// 开始呼叫
  startCall(String remoteUserId, String mediaType, {bool isUseScreen = false}) {
    this._sessionId = this._userId + '-' + mediaType;
    //信令状态
    if (this.onSignalingStateCallback != null) {
      this.onSignalingStateCallback(P2PState.callStateJoinRoom);
    }
    //创建PeerConnect
    _createPeerConnection(remoteUserId, mediaType, isUseScreen).then((pc) {
      // pc对象放入集合
      _peerConnections[remoteUserId] = pc;
      // 发送offer请求
      _createOffer(remoteUserId, pc, mediaType);
    });
  }

  ///挂断/离开
  void leave(id) {
    //关闭并清空所有PC
    _peerConnections.forEach((key, peerConn) {
      peerConn.close();
    });
    _peerConnections.clear();

    //销毁本地媒体流
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }

    //将会话Id置为空
    this._sessionId = null;
    //设置当前状态为挂断状态
    if (this.onSignalingStateCallback != null) {
      this.onSignalingStateCallback(P2PState.callStateHangUp);
    }
  }
}

