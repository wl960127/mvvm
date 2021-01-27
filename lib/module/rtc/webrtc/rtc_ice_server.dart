//Turn服务器返回数据
var _turnCredential;

///
class RtcIceServers {
  ///
  String _url;

  ///
  int _turnPort;

  /// ICE服务器信息
  Map<String, dynamic> iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      /*
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
       */
    ]
  };

  ///
  RtcIceServers(this._url, this._turnPort);

  ///
  init() {
    // this._requestIceServer(this._url, this._turnPort);
  }

  ///
  Future _requestIceServer(String url, int turnPort) async {
    if (_turnCredential == null) {
      try {
        // _turnCredential = await getTurnCredential(url, turnPort);
        iceServers = {
          'iceServers': [
            {
              'url': _turnCredential['uris'][0],
              'username': _turnCredential['username'],
              'credential': _turnCredential['password']
            },
          ]
        };
      } catch (e) {
        print('_requestIceServer error ${e.toString()}');
      }
      ;
    }
    return iceServers;
  }
}
