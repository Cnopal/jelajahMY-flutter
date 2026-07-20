class AppUser {
  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.phone,
    required this.nationality,
    required this.profileImageUrl,
    required this.emailVerified,
  });

  final int id;
  final String firebaseUid;
  final String name;
  final String email;
  final String? phone;
  final String? nationality;
  final String? profileImageUrl;
  final bool emailVerified;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _toInt(json['id']),
      firebaseUid: json['firebase_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: _toNullableString(json['phone']),
      nationality: _toNullableString(json['nationality']),
      profileImageUrl: _toNullableString(json['profile_image_url']),
      emailVerified:
          json['email_verified'] == true || json['email_verified'] == 1,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _toNullableString(dynamic value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}
