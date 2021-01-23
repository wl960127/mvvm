import 'package:mvvm/generated/json/base/json_convert_content.dart';

///
class LoginEntity with JsonConvert<LoginEntity> {
  String id;
  String sex;
  String username;

  // LoginEntity(this.id, this.sex, this.username);

  ///
  String get loginID {
    return this.id;
  }

  ///
  String get loginSex {
    return this.sex;
  }

  ///
  String get loginUserName {
    return this.username;
  }

  @override
  String toString() {
    return 'LoginEntity{id: $id, sex: $sex, username: $username}';
  }
}
