import 'base_entity.dart';

///
class ErrorEntity extends BaseEntity {
  ///
  int code;

  ///
  String message;

  ///
  ErrorEntity({this.code, this.message});
}
