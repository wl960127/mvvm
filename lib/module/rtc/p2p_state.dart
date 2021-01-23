///
enum P2PState {
  /// 加入房间
  callStateJoinRoom,

  /// 挂断
  callStateHangUp,

  /// 连接打开
  connectionOpen,

  /// 连接关闭
  connectionClosed,

  /// 连接错误
  connectionError,
}
