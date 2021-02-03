import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/webrtc/constraints.dart';
import 'package:mvvm/module/rtc/webrtc/session_type.dart';
import 'package:mvvm/module/rtc/webrtc/signaling_state.dart';
import 'package:mvvm/util/device_info.dart';
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
typedef void CallStateCallback(Session session, CallState state);

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

  List<MediaStream> _remoteStreams = <MediaStream>[];
  Map<String, Session> _sessions = {};

  String _selfId = randomNumeric(6);

  /// 房间ID
  // String _roomId = '1111';

  MediaStream _localStream;

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
      onSignalingStateChange?.call(SignalingState.connectionOpen);
      _send('new', {'name': DeviceInfo.label, 'id': _selfId});
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
    switch (mapData['type'] as String) {
      case 'peers': //新成员
        {
          List<dynamic> peers = data as List;
          // if (onPeersUpdate != null) {
          Map<String, dynamic> event = Map();
          event['self'] = _selfId;
          event['peers'] = peers;
          onPeersUpdate?.call(event);
          // }
        }
        break;
      case 'offer': //提议Offer消息
        {
          var peerId = data['from'] as String;
          var description = data['description'];
          var media = data['media'] as String;
          var sessionId = data['session_id'] as String;
          var session = _sessions[sessionId];
          var newSession = await _createSession(
              session: session,
              peerID: peerId,
              sessionID: sessionId,
              mediaType: media,
              screenSharing: false);
          _sessions[sessionId] = newSession;
          await newSession.pc.setRemoteDescription(RTCSessionDescription(
              description['sdp'] as String, description['type'] as String));
          await _createAnswer(newSession, media);
          if (newSession.remoteCandidates.isNotEmpty) {
            newSession.remoteCandidates.forEach((candidate) async {
              await newSession.pc.addCandidate(candidate);
            });
            newSession.remoteCandidates.clear();
          }
          onCallStateChange?.call(newSession, CallState.callStateNew);
        }
        break;
      case 'answer': //应答Answer
        {
          var description = data['description'];
          var sessionId = data['session_id'];
          var session = _sessions[sessionId];
          await session?.pc?.setRemoteDescription(RTCSessionDescription(
              description['sdp'] as String, description['type'] as String));
        }
        break;
      case 'candidate': //网络Candidate信息
        {
          var peerId = data['from'];
          var candidateMap = data['candidate'];
          var sessionId = data['session_id'] as String;
          var session = _sessions[sessionId];
          RTCIceCandidate candidate = RTCIceCandidate(
              candidateMap['candidate'] as String,
              candidateMap['sdpMid'] as String,
              candidateMap['sdpMLineIndex'] as int);

          if (session != null) {
            if (session.pc != null) {
              await session.pc.addCandidate(candidate);
            } else {
              session.remoteCandidates.add(candidate);
            }
          } else {
            _sessions[sessionId] =
                Session(pid: peerId as String, sid: sessionId)
                  ..remoteCandidates.add(candidate);
          }
        }
        break;
      case 'leave': //离开房间消息
        {
          var peerID = data as String;
          _closeSessionByPeerID(peerID);
        }
        break;
      case 'bye': //挂断信息
        {
          var sessionID = data['session_id'];
          print('bye:  $sessionID');
          var session = _sessions.remove(sessionID);
          onCallStateChange?.call(session, CallState.callStateBye);
          await _closeSession(session);
        }
        break;
      case 'heartbeat': //心跳包
        break;
      default:
        break;
    }
  }

  /// 创建媒体流
  Future<MediaStream> _createStream(media, bool isUseScreen) async {
    return isUseScreen
        ? await navigator.mediaDevices
            .getDisplayMedia(P2PConstraints.mediaConstraints)
        : await navigator.mediaDevices
            .getUserMedia(P2PConstraints.mediaConstraints);
  }

  /// 创建提议Offer
  Future<void> _createOffer(Session session, String media) async {
    try {
      //返回SDP信息
      RTCSessionDescription s =
          await session.pc.createOffer(P2PConstraints.sdpConstraints);
      //设置本地描述信息
      await session.pc.setLocalDescription(s);
      //发送Offer至对方
      _send('offer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': session.sid,
        'media': media,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  /// 创建应答
  _createAnswer(Session session, String media) async {
    try {
      RTCSessionDescription description =
          await session.pc.createAnswer(P2PConstraints.sdpConstraints);

      await session.pc.setLocalDescription(description);
      _send('answer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': description.sdp, 'type': description.type},
        'session_id': session.sid,
      });
    } catch (e) {
      print('_createAnswer 失败 ${e.toString()}');
    }
  }

  /// 挂断
  bye(String sessionID) {
    _send('bye', {
      'session_id': sessionID,
      'from': _selfId,
    });
    _closeSession(_sessions[sessionID]);
  }

  /// 发送消息 传入类型及数据
  _send(type, data) {
    var request = Map();
    request["type"] = type;
    request["data"] = data;
    //Json转码后发送
    _rtcSocket.send(_encoder.convert(request));
  }

  /// 切换摄像头
  switchCamera() {
    if (_localStream != null) {
      // _localStream.getVideoTracks()[0].switchCamera();
      Helper.switchCamera(_localStream.getVideoTracks()[0]);
    }
  }

  /// 麦克风操作
  muteMicroPhone() {
    if (_localStream != null) {
      bool enabled = _localStream.getAudioTracks()[0].enabled;
      _localStream.getAudioTracks()[0].enabled = !enabled;
    }
  }

  /// 喇叭操作
  muteSpeaker(bool bool) {}

  /// 开始呼叫
  invite(String peerID, String media, bool isUseScreen) async {
    var sessionID = _selfId + '-' + peerID;
    //创建会话
    Session session = await _createSession(
        peerID: peerID,
        sessionID: sessionID,
        mediaType: media,
        screenSharing: isUseScreen);

    _sessions[sessionID] = session;

    if (media == DataSession) {
      await _creteDataChannel(session);
    }
    await _createOffer(session, media);
    onCallStateChange?.call(session, CallState.callStateNew);
  }

  ///挂断/离开
  void leave(id) {}

  Future<Session> _createSession(
      {Session session,
      String peerID,
      String sessionID,
      String mediaType,
      bool screenSharing}) async {
    var newSession = session ?? Session(sid: sessionID, pid: peerID);
    if (mediaType != DataSession) {
      _localStream = await _createStream(String, screenSharing);
    }

    RTCPeerConnection pc = await createPeerConnection(
        _p2pIceServers.iceServers, P2PConstraints.pcConstraints);

    if (mediaType != DataSession) {
      _localStream
          .getTracks()
          .forEach((track) async => await pc.addTrack(track, _localStream));
    }

    pc.onIceCandidate = (candidate) {
      if (candidate == null) {
        return;
      }
      _send('candidate', {});
    };

    pc.onIceConnectionState = (state) {};

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        onAddRemoteStream?.call(newSession, event.streams[0]);
      }
    };

    pc.onRemoveStream = (stream) {
      onRemoveRemoteStream?.call(newSession, stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(newSession, channel);
    };
    newSession.pc = pc;
    return newSession;
  }

  void _addDataChannel(Session session, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (data) {
      onDataChannelMessage?.call(session, channel, data);
    };
    session.dc = channel;
    onDataChannel?.call(session, channel);
  }

  Future<void> _creteDataChannel(Session session,
      {String label = 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
      ..maxRetransmits = 30;
    RTCDataChannel channel =
        await session.pc.createDataChannel(label, dataChannelDict);
    _addDataChannel(session, channel);
  }

  void _closeSessionByPeerID(String peerID) {
    Session session;
    _sessions.removeWhere((String key, Session se) {
      var ids = key.split('-');
      session = se;
      return peerID == ids[0] || peerID == ids[1];
    });
    if (session != null) {
      _closeSession(session);
      onCallStateChange?.call(session, CallState.callStateBye);
    }
  }

  Future<void> _closeSession(Session session) async {
    _localStream?.getTracks()?.forEach((element) async {
      await element.stop();
    });
    await _localStream?.dispose();
    _localStream = null;

    await session?.pc?.close();
    await session?.dc?.close();
  }
}
