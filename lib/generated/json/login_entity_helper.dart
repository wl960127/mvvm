import 'package:mvvm/data/entity/login_entity.dart';

loginEntityFromJson(LoginEntity data, Map<String, dynamic> json) {
  if (json['id'] != null) {
    data.id = json['id'].toString();
  }
  if (json['sex'] != null) {
    data.sex = json['sex'].toString();
  }
  if (json['username'] != null) {
    data.username = json['username'].toString();
  }
  return data;
}

Map<String, dynamic> loginEntityToJson(LoginEntity entity) {
  final Map<String, dynamic> data = Map<String, dynamic>();
  data['id'] = entity.id;
  data['sex'] = entity.sex;
  data['username'] = entity.username;
  return data;
}
