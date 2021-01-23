import 'package:flutter/material.dart';
import 'package:mvvm/pages/common/base.dart';
import 'package:mvvm/pages/video_call.dart';
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
    with TickerProviderStateMixin<_MainContentPage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> _widgetOptions = <Widget>[
    VideoCallPage(),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void deactivate() {
    super.deactivate();
    //关闭信令
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('主界面'),
        centerTitle: true,
        leading: Text(''),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'RTC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  /// 连接ws
  _connect() {}
}
