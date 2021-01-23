import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mvvm/viewmodel/start_provider.dart';

import 'common/base.dart';

///
class StartPage extends PageProvideNode<StartProvider> {
// class StartPage extends StatelessWidget {
  ///
  StartPage() : super();

  ///

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Text("😫啊啊啊"),
    );
  }
}
