import 'entity_factory.dart';

///
class BaseEntity<T> {
  int code;
  String message;
  T data;

  int get reponseCode {
    return this.code;
  }

  String get reponseMsg {
    return this.message;
  }

  T get reponseData {
    return this.data;
  }

  ///
  BaseEntity({this.code, this.message, this.data});

  ///
  factory BaseEntity.fromJson(json) {
    return BaseEntity(
      code: json["code"] as int,
      message: json["msg"] as String,
      // data值需要经过工厂转换为我们传进来的类型
      data: EntityFactory.generateOBJ<T>(json["data"]),
    );
  }

  @override
  String toString() {
    return 'BaseEntity{code: $code, message: $message, data: $data}';
  }
}
