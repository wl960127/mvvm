import 'package:mvvm/di/net/request.dart';
import 'package:rxdart/rxdart.dart';

///
class LoginService {
  /// 登录
  Observable login() => get("login");
}

/// 登录接口
///
class LoginRepository {
  final LoginService _loginService;

  ///
  LoginRepository(this._loginService);

  ///
  Observable login(String username, String password) {
    return _loginService.login();
  }
}
