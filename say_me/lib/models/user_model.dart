enum UserRole { patient, doctor }
enum AgeCategory { kids, teens, adults }

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
  });

  static AgeCategory calculateAgeCategory(int age) {
    if (age >= 6 && age <= 13) return AgeCategory.kids;
    if (age >= 14 && age <= 17) return AgeCategory.teens;
    return AgeCategory.adults;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final ageVal = map['age'] ?? 18;
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
      'is_identity_verified': isIdentityVerified,
      'avatar_url': avatarUrl,
    };
  }
}