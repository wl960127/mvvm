import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'router_handler.dart';

/// 路由
class Routers {
  static String root = '/';
  static String login = '/login';
  static String video = '/video';
  static String main = '/main';

  /// 路由跳转
  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      print("ROUTE WAS NOT FOUND !!!");
      return null;
    });

    router.define(root, handler: rootHandler);
    router.define(main, handler: mainHandler);
    router.define(video, handler: videoHandler);
  }
}
