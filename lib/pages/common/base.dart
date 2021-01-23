import 'dart:async';

import 'package:dartin/dartin.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

/// 一般点击事件
abstract class Presenter {
  ///
  void onClick(String action);
}

/// 列表点击事件
abstract class ItemPresenter<T> {
  ///
  void onItemClick(String action, T item);
}

/// BaseProvide
class BaseProvide with ChangeNotifier {
  CompositeSubscription _compositeSubscription = CompositeSubscription();

  /// add [StreamSubscription] to [compositeSubscription]
  ///
  /// 在 [dispose]的时候能进行取消
  addSubscription(StreamSubscription subscription) {
    _compositeSubscription.add(subscription);
  }

  @override
  void dispose() {
    if (!_compositeSubscription.isDisposed) {
      _compositeSubscription.dispose();
    }
    super.dispose();
  }
}

/// page的基类 [PageProvideNode]
///
/// 隐藏了 [Provider] 的调用

abstract class PageProvideNode<T extends ChangeNotifier> extends StatelessWidget
    implements Presenter {
  ///
  final T mProvider;

  /// 构造函数
  ///
  /// [params] 代表注入ViewModel[mProvider]时所需的参数，需按照[mProvider]的构造方法顺序赋值
  PageProvideNode({List<dynamic> params})
      : mProvider = inject<T>(params: params);

  ///
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
        value: mProvider, child: buildContent(context));
  }

  @override
  void onClick(String action) {}
}
