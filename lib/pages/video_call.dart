import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/webrtc/call_state.dart';
import 'package:mvvm/module/rtc/webrtc/rtc_signaling.dart';
import 'package:mvvm/module/rtc/webrtc/session.dart';
import 'package:mvvm/module/rtc/webrtc/session_type.dart';
import 'package:mvvm/module/rtc/webrtc/signaling_state.dart';
import 'package:mvvm/pages/common/base.dart';
import 'package:mvvm/util/util.dart';
import 'package:mvvm/viewmodel/video_provider.dart';

///
class VideoCallPage extends PageProvideNode<VideoCallProvider> {
  ///
  VideoCallPage(String account, String roomID) : super();

  @override
  Widget buildContent(BuildContext context) {
    return _VideoCallPage(mProvider);
  }
}

///
class _VideoCallPage extends StatefulWidget {
  final VideoCallProvider mProvider;

  _VideoCallPage(this.mProvider);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<_VideoCallPage>
    with TickerProviderStateMixin<_VideoCallPage>, AutomaticKeepAliveClientMixin
    implements Presenter {
  // VideoCallProvider _provider;

  bool _isCalling = false;
  bool _inCalling = false;
  String _sdp;

  Session _session;

  bool _microphoneOff = false;
  bool _speakerOff = false;

  // String _userName = "1";
  // String _roomId = "111";
  String _userID = randomNumeric(6);

  // String _userID = randomNumeric(6);

  //所有成员
  List<dynamic> _users = [];
  var _selfID;

  /// 本地视频渲染对象
  RTCVideoRenderer _localRender = RTCVideoRenderer();

  /// 远端视频渲染对象
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  /// 信令
  RtcSignaling _rtcSignaling;

  @override
  void initState() {
    // _provider = widget.mProvider;
    initRenderers();
    _connect();
    super.initState();
  }

  @override
  deactivate() {
    super.deactivate();
    //关闭信令
    _rtcSignaling?.close();
    _localRender?.dispose();
    _remoteRender?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(
      child: Scaffold(
        appBar: AppBar(),
        body: _inCalling
            ? OrientationBuilder(builder: (context, orientation) {
                return Container(
                  child: Stack(children: <Widget>[
                    //远端视频定位
                    Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        //远端视频容器,大小为大视频
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          //整个容器宽
                          width: MediaQuery.of(context).size.width,
                          //整个容器高
                          height: MediaQuery.of(context).size.height,
                          //远端视频渲染
                          child: RTCVideoView(_remoteRender),
                          decoration: BoxDecoration(color: Colors.black54),
                        )),
                    //本地视频定位
                    Positioned(
                      left: 20.0,
                      top: 20.0,
                      //本地视频容器,大小为小视频
                      child: Container(
                        //固定宽度,竖屏时为90,横屏时为120
                        width:
                            orientation == Orientation.portrait ? 90.0 : 120.0,
                        //固定高度,竖屏时为120,横屏时为90
                        height:
                            orientation == Orientation.portrait ? 120.0 : 90.0,
                        //本地视频渲染
                        child: RTCVideoView(_localRender),
                        decoration: BoxDecoration(color: Colors.black54),
                      ),
                    ),
                  ]),
                );
              })
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(1),
                itemCount: _users != null ? _users.length : 0,
                itemBuilder: (context, i) {
                  return _buildItem(context, _users[i]);
                }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? SizedBox(
                width: 200.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      //切换摄像头按钮
                      FloatingActionButton(
                        child: Icon(Icons.switch_camera),
                        onPressed: _switchCamera,
                      ),
                      //挂断按钮
                      FloatingActionButton(
                        onPressed: _hangUp,
                        child: Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                      //麦克风禁音按钮
                      FloatingActionButton(
                        child: this._microphoneOff
                            ? Icon(Icons.mic_off)
                            : Icon(Icons.mic),
                        onPressed: _muteMic,
                      )
                    ]))
            : null,
      ),
    );
  }

  @override
  void onClick(String action) {}

  /// 挂断通话
  _hangUp() {
    if (_rtcSignaling != null) {
      _rtcSignaling.bye(_session.sid);
    }
  }

  //呼叫通话

  _startCall(String toUserID, String type, bool isUseScreen) async {
    if (_rtcSignaling != null && _userID != toUserID) {
      await _rtcSignaling.invite(toUserID, type, isUseScreen);
    }
  }

  // 切换摄像头
  _switchCamera() {
    _rtcSignaling.switchCamera();
  }

  // 麦克风静音
  _muteMic() {
    var muted = !_microphoneOff;
    setState(() {
      _microphoneOff = muted;
    });
    _rtcSignaling.muteMicroPhone();
  }

  /// 喇叭静音
  // _muteSpeaker() {
  //   var muted = !_speakerOff;
  //   setState(() {
  //     _speakerOff = muted;
  //   });
  //   _p2pVideoClient.muteSpeaker(!muted);
  // }

  /// 初始化视频渲染对象
  initRenderers() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  /// 连接服务器
  _connect() async {
    print(" 连接服务器 ");
    if (_rtcSignaling == null) {
      // 实例化信令并连接
      _rtcSignaling = RtcSignaling('192.168.0.186', 8000)..connect();
      //信令状态处理
      _rtcSignaling.onSignalingStateChange = (SignalingState state) {
        print(' 信令状态  $state');
        switch (state) {
          case SignalingState.connectionOpen:
            break;
          case SignalingState.connectionClose:
            break;
          case SignalingState.connectionError:
            break;
        }
      };

      _rtcSignaling.onCallStateChange = (Session session, CallState state) {
        switch (state) {
          case CallState.callStateNew:
            setState(() {
              _session = session;
              _inCalling = true;
            });
            break;
          case CallState.callStateBye:
            setState(() {
              _localRender.srcObject = null;
              _remoteRender.srcObject = null;
              _inCalling = false;
              _session = null;
            });

            break;
          case CallState.callStateInvite:
            break;
          case CallState.callStateConnected:
            break;
          case CallState.callStateRinging:
            break;
        }
      };

      _rtcSignaling.onPeersUpdate = ((event) {
        if (event != null) {
          setState(() {
            _selfID = event['self'];
            _users = event['peers'] as List;
          });
        }
      });

      _rtcSignaling.onLocalStream = ((_, stream) {
        _localRender.srcObject = stream;
      });
      _rtcSignaling.onAddRemoteStream = ((_, stream) {
        _remoteRender.srcObject = stream;
      });
    } else {
      print("_p2pVideoClient!= null");
    }
  }

  ///
  Widget _buildItem(BuildContext context, user) {
    var self = (user['id'] == _selfID);
    String userName = user['name'] as String;
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self ? userName + '[Your self]' : userName),
        subtitle: Text('id ${user['id'] as String}'),
        onTap: null,
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.videocam),
                    onPressed: () =>
                        _startCall(user['id'] as String, VideoSession, false),
                    tooltip: '视频通话',
                  ),
                  IconButton(
                    icon: Icon(Icons.screen_share),
                    onPressed: () =>
                        _startCall(user['id'] as String, VideoSession, true),
                    tooltip: '屏幕共享',
                  )
                ])),
      ),
      Divider()
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
