import 'package:rxdart/rxdart.dart';

import 'dio_manager.dart';

///
Future _get(String url, {Map<String, dynamic> params}) async {
  var response = await DioManager().dio.get(url, queryParameters: params);
  return response.data;
}

///
Future _post(String url, Map<String, dynamic> params) async {
  var response = await DioManager().dio.post(url, data: params);
  return response.data;
}

///
Observable get(String url, {Map<String, dynamic> params}) =>
    Observable.fromFuture(_get(url, params: params)).asBroadcastStream();

///
Observable post(String url, Map<String, dynamic> params) =>
    Observable.fromFuture(_post(url, params)).asBroadcastStream();
