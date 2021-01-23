import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:mvvm/pages/login_page.dart';
import 'package:mvvm/pages/main_page.dart';

import 'file:///G:/study/flutterDemo/mvvm/lib/pages/video_call.dart';

///
var rootHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return LoginPage();
  // String message = params["message"]?.first;
  // String colorHex = params["color_hex"]?.first;
  // String result = params["result"]?.first;
  // Color color = Color(0xFFFFFFFF);
  // if (colorHex != null && colorHex.length > 0) {
  //   color = Color(ColorHelpers.fromHexString(colorHex));
  // }
  // return DemoSimpleComponent(message: message, color: color, result: result);
});

///
var videoHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  // String name = params['name']?.first;
  // String password = params['password']?.first;
  // print('$name  啊哈哈哈 $password');
  return VideoCallPage();
});

///
var mainHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MainPage();
});

///
var errorHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Scaffold(
    body: Center(
      child: Text('没有找到对应的页面'),
    ),
  );
});