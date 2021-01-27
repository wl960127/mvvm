/// 呼叫状态
enum CallSata {
  /// 开始呼叫
  callStateNew,

  /// 呼叫振铃
  callStateRinging,

  /// 呼叫邀请
  callStateInvite,

  /// 呼叫接通
  callStateConnected,

  /// 挂断
  callStateBye
}
