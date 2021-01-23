import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mvvm/module/rtc/p2p_state.dart';
import 'package:mvvm/module/rtc/p2p_video_call.dart';
import 'package:mvvm/pages/common/base.dart';
import 'package:mvvm/util/util.dart';
import 'package:mvvm/viewmodel/video_provider.dart';

///
class VideoCallPage extends PageProvideNode<VideoCallProvider> {
  ///
  VideoCallPage() : super();

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
    with TickerProviderStateMixin<_VideoCallPage>
    implements Presenter {
  VideoCallProvider _provider;

  bool _isCalling = false;
  bool _inCalling = false;
  String _sdp;

  bool _microphoneOff = false;
  bool _speakerOff = false;

  String _userName = "1";
  String _roomId = "111";
  String _userID = randomNumeric(6);

  //所有成员
  List<dynamic> _users = [];

  /// 本地视频渲染对象
  RTCVideoRenderer _localRender = RTCVideoRenderer();

  /// 远端视频渲染对象
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  /// 信令  P2PVideoCall
  P2PVideoCall _p2pVideoCall;

  @override
  void initState() {
    super.initState();
    _provider = widget.mProvider;
    initRenderers();
    _connect();
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
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text("rtc"),
        ),
        body: _inCalling
            ? OrientationBuilder(
                builder: (context, orientation) {
                  return Center(
                    child: Container(
                      child:
                          _isCalling ? Text(_sdp) : Text("data channel test"),
                    ),
                  );
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(1),
                itemCount: _users.length,
                itemBuilder: (context, i) {
                  return _buildItem(context, _users[i] as Map<String, String>);
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
  void onClick(String action) {
    // TODO: implement onClick
  }

  /// 挂断通话
  _hangUp() {
    if (_p2pVideoCall != null) {
      _p2pVideoCall.hangUp();
    }
  }

  //呼叫通话

  _startCall(String toUserID, bool isUseScreen) {
    if (_p2pVideoCall != null && _userID != toUserID) {
      _p2pVideoCall.startCall(toUserID, 'video');
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

  // 喇叭静音
  _muteSpeaker() {
    var muted = !_speakerOff;
    setState(() {
      _speakerOff = muted;
    });
    _p2pVideoCall.muteSpeaker(!muted);
  }

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
      _p2pVideoCall = P2PVideoCall('192.168.0.186', 8000)..connect();
      //信令状态处理
      _p2pVideoCall.onSignalingStateCallback = (P2PState state) {};
      // 人员列表更新
      _p2pVideoCall.onUserUpdateCallback = ((event) {
        setState(() {
          _users = event['users'] as List;
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
  Widget _buildItem(BuildContext context, Map<String, String> user) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(user['name']),
        subtitle: Text('id:' + user['id']),
        onTap: null,
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.videocam),
                    onPressed: () => _startCall(user['id'], false),
                    tooltip: '视频通话',
                  ),
                  IconButton(
                    icon: Icon(Icons.screen_share),
                    onPressed: () => _startCall(user['id'], true),
                    tooltip: '屏幕共享',
                  )
                ])),
      ),
      Divider()
    ]);
  }
}
