import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:mvvm/pages/common/web_view_page.dart';
import 'package:mvvm/routers/application.dart';

/// 封装跳转工具类
class NavigatorUtil {
  ///
  static Future jump(BuildContext context, String path,
      {bool replace = false,
      bool clearStack = false,
      TransitionType transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder transitionBuilder}) {
    if (path == null || path.isEmpty) {
      throw "empty path";
    }
    if (checkIsNativePath(path)) {
      return Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => (CommonWebViewPage(path))));
    } else {
      return Application.router.navigateTo(context, path,
          replace: replace,
          clearStack: clearStack,
          transition: transition,
          transitionDuration: transitionDuration,
          transitionBuilder: transitionBuilder);
    }
  }

  ///判断是否是原生的路由 路径，是的话则需要 调原生跳转
  static bool checkIsNativePath(String path) {
    return (path.startsWith("http://") || path.startsWith("https://")) ||
        (path.startsWith("native://"));
  }
}
