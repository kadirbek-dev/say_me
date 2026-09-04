enum UserRole { patient, doctor }
enum AgeCategory { kids, teens, adults }
enum UserStatus { active, underReview, banned }

class UserModel {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String gender;
  final int age;
  final AgeCategory ageCategory;
  final bool isIdentityVerified;
  final String avatarUrl;

  // Поля для банов и модерации возраста
  final UserStatus status;
  final bool isAgeVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.gender,
    required this.age,
    required this.ageCategory,
    this.isIdentityVerified = false,
    this.avatarUrl = '',
    this.status = UserStatus.active,
    this.isAgeVerified = false,
  });

  static AgeCategory calculateAgeCategory(int age) {
    if (age >= 6 && age <= 13) return AgeCategory.kids;
    if (age >= 14 && age <= 17) return AgeCategory.teens;
    return AgeCategory.adults;
  }

  static UserStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'under_review':
        return UserStatus.underReview;
      case 'banned':
        return UserStatus.banned;
      case 'active':
      default:
        return UserStatus.active;
    }
  }

  static String _statusToString(UserStatus status) {
    switch (status) {
      case UserStatus.underReview:
        return 'under_review';
      case UserStatus.banned:
        return 'banned';
      case UserStatus.active:
        return 'active';
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final ageVal = (map['age'] as num?)?.toInt() ?? 18;
    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'doctor' ? UserRole.doctor : UserRole.patient,
      gender: map['gender'] ?? 'male',
      age: ageVal,
      ageCategory: calculateAgeCategory(ageVal),
      isIdentityVerified: map['is_identity_verified'] ?? false,
      avatarUrl: map['avatar_url'] ?? '',
      status: _parseStatus(map['status']),
      isAgeVerified: map['is_age_verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role == UserRole.doctor ? 'doctor' : 'patient',
      'gender': gender,
      'age': age,
      'age_category': ageCategory.name,
      'is_identity_verified': isIdentityVerified,
      'avatar_url': avatarUrl,
      'status': _statusToString(status),
      'is_age_verified': isAgeVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
    String? gender,
    int? age,
    AgeCategory? ageCategory,
    bool? isIdentityVerified,
    String? avatarUrl,
    UserStatus? status,
    bool? isAgeVerified,
  }) {
    final updatedAge = age ?? this.age;
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      age: updatedAge,
      ageCategory: ageCategory ?? (age != null ? calculateAgeCategory(updatedAge) : this.ageCategory),
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
    );
  }
}