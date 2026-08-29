import 'user_profile.dart';

class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    required this.profile,
  });

  final String id;
  final String name;
  final String? email;
  final UserProfile profile;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile': profile.toJson(),
      };

  static User fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      );
}
