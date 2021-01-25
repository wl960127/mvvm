import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/basertc/p2p_state.dart';
import 'package:mvvm/module/rtc/webrtc/p2p_video_client.dart';
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
  VideoCallProvider _provider;

  bool _isCalling = false;
  bool _inCalling = false;
  String _sdp;

  bool _microphoneOff = false;
  bool _speakerOff = false;

  // String _userName = "1";
  // String _roomId = "111";
  String _userID = randomNumeric(6);
  // String _userID = randomNumeric(6);

  //所有成员
  List<dynamic> _users = [];

  /// 本地视频渲染对象
  RTCVideoRenderer _localRender = RTCVideoRenderer();

  /// 远端视频渲染对象
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  /// 信令  P2PVideoCall
  P2PVideoClient _p2pVideoCall;

  @override
  void initState() {
    startForegroundService();
    _provider = widget.mProvider;
    initRenderers();
    _connect();
    super.initState();
  }

  @override
  deactivate() {
    super.deactivate();
    //关闭信令
    if (_p2pVideoCall != null) {
      _p2pVideoCall.close();
    }

    if (_localRender != null) {
      _localRender.dispose();
    }
    if (_remoteRender != null) {
      _remoteRender.dispose();
    }
    startForegroundService();
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
                itemCount: _users.length,
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
    if (_p2pVideoCall != null) {
      _p2pVideoCall.hangUp();
    }
  }

  //呼叫通话

  _startCall(String toUserID, bool isUseScreen) {
    if (_p2pVideoCall != null && _userID != toUserID) {
      _p2pVideoCall.startCall(toUserID, 'video', isUseScreen: isUseScreen);
    }
  }

  // 切换摄像头
  _switchCamera() {
    _p2pVideoCall.switchCamera();
  }

  // 麦克风静音
  _muteMic() {
    var muted = !_microphoneOff;
    setState(() {
      _microphoneOff = muted;
    });
    _p2pVideoCall.muteMicroPhone(!muted);
  }

  /// 喇叭静音
  // _muteSpeaker() {
  //   var muted = !_speakerOff;
  //   setState(() {
  //     _speakerOff = muted;
  //   });
  //   _p2pVideoCall.muteSpeaker(!muted);
  // }

  /// 初始化视频渲染对象
  initRenderers() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  /// 连接服务器
  _connect() async {
    print(" 连接服务器 ");
    if (_p2pVideoCall == null) {
      // 实例化信令并连接
      _p2pVideoCall = P2PVideoClient('192.168.0.186', 8000)..connect();
      //信令状态处理
      _p2pVideoCall.onSignalingStateCallback = (P2PState state) {
        switch (state) {
          case P2PState.callStateJoinRoom:
            this.setState(() {
              _inCalling = true;
            });
            break;
          //挂断状态
          case P2PState.callStateHangUp:
            this.setState(() {
              _localRender.srcObject = null;
              _remoteRender.srcObject = null;
              _inCalling = false;
            });
            break;
          case P2PState.connectionClosed:
          case P2PState.connectionError:
          case P2PState.connectionOpen:
            break;
        }
      };
      // 人员列表更新
      _p2pVideoCall.onUserUpdateCallback = ((event) {
        setState(() {
          _users = event['users'] as List;
          print('人员列表更新 ${_users.toString()}');
        });
      });
      //本地流到达
      _p2pVideoCall.onLocalStream = ((stream) {
        _localRender.srcObject = stream;
      });
      //远端流到达
      _p2pVideoCall.onAddRemoteStream = ((stream) {
        _remoteRender.srcObject = stream;
      });
      //远端流移除
      _p2pVideoCall.onRemoveRemoteStream = ((stream) {
        _remoteRender.srcObject = null;
      });
    } else {
      print("_p2pVideoClient!= null");
    }
  }

  ///
  Widget _buildItem(BuildContext context, user) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(user['name'] as String),
        subtitle: Text('id ${user['id'] as String}'),
        onTap: null,
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.videocam),
                    onPressed: () => _startCall(user['id'] as String, false),
                    tooltip: '视频通话',
                  ),
                  IconButton(
                    icon: Icon(Icons.screen_share),
                    onPressed: () => _startCall(user['id'] as String, true),
                    tooltip: '屏幕共享',
                  )
                ])),
      ),
      Divider()
    ]);
  }

  @override
  bool get wantKeepAlive => true;

  ///
startForegroundService() async {
  await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 5);
  await FlutterForegroundPlugin.setServiceMethod(globalForegroundService);
  await FlutterForegroundPlugin.startForegroundService(
    holdWakeLock: false,
    onStarted: () {
      print("Foreground on Started");
    },
    onStopped: () {
      print("Foreground on Stopped");
    },
    title: "Tcamera",
    content: "Tcamera sharing your screen.",
    iconName: "ic_stat_mobile_screen_share",
  );
  return true;
}

///
void globalForegroundService() {
  debugPrint("current datetime is ${DateTime.now()}");
}

}
