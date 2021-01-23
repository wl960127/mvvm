import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/app_module.dart';
import 'routers/application.dart';
import 'routers/routers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  Provider.debugCheckInvalidValueType = null;
  runApp(MyApp());
}

///
class MyApp extends StatefulWidget {
  @override
  State createState() {
    return MyAppState();
  }
}

///
class MyAppState extends State<MyApp> {
  ///
  MyAppState() {
    final router = FluroRouter();
    Routers.configureRoutes(router);
    Application.router = router;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: Application.router.generator,
    );
  }
}
