import 'package:flutter/material.dart';
import 'package:mvvm/pages/common/base.dart';
import 'package:mvvm/viewmodel/main_provider.dart';

/// 应用主界面
class MainPage extends PageProvideNode<MainProvider> {
  ///
  MainPage() : super();

  @override
  Widget buildContent(BuildContext context) {
    return _MainContentPage(mProvider);
  }
}

class _MainContentPage extends StatefulWidget {
  final MainProvider mProvider;

  _MainContentPage(this.mProvider);

  @override
  State<StatefulWidget> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContentPage>
    with TickerProviderStateMixin<_MainContentPage>
    implements Presenter {
  @override
  Widget build(BuildContext context) {
    return null;
  }

  @override
  void onClick(String action) {}
}
