import 'package:dio/dio.dart';
import 'package:mvvm/pages/common/base.dart';
import 'package:mvvm/repo/login_repo.dart';
import 'package:rxdart/rxdart.dart';

///
class LoginProvider extends BaseProvide {
  ///
  String username = "";

  ///
  String password = "";

  ///
  final String title;
  final LoginRepository _loginRepo;

  /// 结果
  String response = "";

  ///
  String get mResponse => response;

  ///
  set _setResponse(String result) {
    response = result;
    notifyListeners();
  }

  ///
  LoginProvider(this.title, this._loginRepo);

  ///
  /// 登录
  ///
  /// 调用 model 的 login 方法进行登录
  /// 传入 [username] 和 [password]
  /// 成功：显示返回的信息
  /// 失败: 处理错误，显示错误信息
  /// 订阅开始：loading = true
  /// 订阅结束：loading = false
  /// 返回 [Observable] 给 View 层
  Observable login() => _loginRepo.login(username, password).doOnData((event) {
        print("provider doOnData event ${event}");
        _setResponse = event.toString();
        print("provider doOnData _response $response");
      }).doOnError((e, stacktrace) {
        if (e is DioError) {
          _setResponse = e.response.data.toString();
        }
      }).doOnListen(() {
        print("provider 请求开始");
      }).doOnDone(() {
        print("provider 请求结束");
      });
}
