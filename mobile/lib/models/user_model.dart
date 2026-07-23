class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? fullName;
  final String role;
  final String? level;
  final bool isVerified;

  const UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    this.fullName,
    required this.role,
    this.level,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String? ?? 'user',
      level: json['level'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  bool get needsPlacementTest => level == null;

  String get levelLabel {
    switch (level) {
      case 'beginner':
        return 'مبتدی';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'پیشرفته';
      default:
        return 'نامشخص';
    }
  }
}
