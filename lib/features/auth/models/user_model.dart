class UserModel {
  final String id;
  final String name;
  final String email;
  final Map<String,String>? fcmTokens;

  UserModel({required this.id,required this.name,required this.email,this.fcmTokens});

  Map<String,dynamic>toMap(){
    return {
      'id': id,
      'name': name,
      'email': email,
      'fcmTokens':fcmTokens
    };
  }

  factory UserModel.fromMap(Map<String,dynamic>map){
    return UserModel(
      id: map['id'], 
      name: map['name'],
      email: map['email'],
      fcmTokens: map['fcmTokens']!=null?
           Map<String,String>.from(map['fcmTokens']):null
      );
  }
}