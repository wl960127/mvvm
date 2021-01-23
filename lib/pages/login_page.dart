import 'package:flutter/material.dart';
import 'package:mvvm/di/net/result_code.dart';
import 'package:mvvm/routers/application.dart';
import 'package:mvvm/routers/routers.dart';
import 'package:mvvm/viewmodel/login_provider.dart';
import 'package:mvvm/widgets/toast.dart';

import 'common/base.dart';

///
class LoginPage extends PageProvideNode<LoginProvider> {
  ///
  LoginPage() : super();

  @override
  Widget buildContent(BuildContext context) {
    return _LoginContentPage(mProvider);
  }
}

class _LoginContentPage extends StatefulWidget {
  final LoginProvider provider;

  _LoginContentPage(this.provider);

  @override
  __LoginContentPageState createState() => __LoginContentPageState();
}

///
class __LoginContentPageState extends State<_LoginContentPage>
    with TickerProviderStateMixin<_LoginContentPage>
    implements Presenter {
  LoginProvider provider;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
  }

  @override
  void onClick(String action) {
    switch (action) {
      case "login":
        login();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text("登录"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                    width: 260.0,
                    child: TextField(
                      //键盘类型为文本
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        hintText: '请输入用户名',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          provider.username = value;
                        }
                      },
                    )),
                SizedBox(
                  width: 260.0,
                  child: TextField(
                    //键盘类型为数字
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      hintText: '请输入房间号',
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        provider.password = value;
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 260.0,
                  height: 48.0,
                ),
                SizedBox(
                  width: 260.0,
                  height: 48.0,
                  //登录按钮
                  child: RaisedButton(
                    child: Text(
                      '登录',
                    ),
                    onPressed: () {
                      Application.router.navigateTo(context, Routers.main);

                      // onClick('login');
                    },
                  ),
                ),
              ]),

          // child: Selector<LoginProvider, String>(
          //   selector: (_, data) => data.mResponse,
          //   builder: (context, value, child) {
          //     return Text(value);
          //   },
          // ),
        ),
      ),
    );
  }

  /// 登录
  ///
  /// 调用 [mProvide] 的 login 方法并进行订阅
  /// 请求开始时：启动动画 [AnimationStatus.forward]
  /// 请求结束时：反转动画 [AnimationStatus.reverse]
  /// 成功 ：弹出 'login success'
  /// 失败 ：[dispatchFailure] 显示错误原因
  void login() {
    final s = provider.login().doOnListen(() {
      print("page 请求开始");
    }).doOnDone(() {
      print("page 请求结束");
    }).listen((value) {
      Application.router.navigateTo(context, '/video', replace: true);
      print("page 请求结果 $value");
      Toast.show("login success", context, type: Toast.SUCCESS);
    }, onError: (e) {
      print("page 请求异常 ${e.toString()}");
      dispatchFailure(context, e);
    });
    provider.addSubscription(s);
  }
}
