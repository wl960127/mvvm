import 'package:mvvm/data/entity/login_entity.dart';

///
class EntityFactory {
  static T generateOBJ<T>(jsonStr) {
    if (jsonStr == null) {
      return null;
    } else if (T.toString() == "LoginEntity") {
      var bean = LoginEntity().fromJson(jsonStr as Map<String, dynamic>);
      return bean as T;
    } else {
      return jsonStr as T;
    }
  }
}
