import 'package:flutter/material.dart';
import 'package:mvvm/routers/application.dart';
import 'package:mvvm/routers/routers.dart';

/// 封装跳转工具类
class NavigatorUtil {
  ///
  static void goVideoPage(BuildContext context, String name, String password) {
    Application.router.navigateTo(context, Routers.video, replace: true);
  }
}
