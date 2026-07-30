import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.birthDate,
    required this.userType,
    required this.address,
    required this.avatarPath,
  });

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final DateTime? birthDate;
  final String userType;
  final String address;
  final String? avatarPath;

  factory UserProfile.fromMap(Map<String, dynamic> map, User user) {
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: _stringValue(map['full_name']),
      phoneNumber: _stringValue(map['phone_number']),
      birthDate: _dateValue(map['birth_date']),
      userType: _stringValue(map['user_type']),
      address: _stringValue(map['address']),
      avatarPath: _nullableStringValue(map['avatar_path']),
    );
  }

  factory UserProfile.fromAccount(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: _stringValue(metadata['full_name']),
      phoneNumber: _stringValue(metadata['phone_number']),
      birthDate: _dateValue(metadata['birth_date']),
      userType: _stringValue(metadata['user_type']),
      address: _stringValue(metadata['address']),
      avatarPath: _nullableStringValue(metadata['avatar_path']),
    );
  }

  int? ageOn(DateTime today) {
    final date = birthDate;
    if (date == null) return null;
    var years = today.year - date.year;
    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String get userTypeLabel => switch (userType) {
    'senior' => 'Senior',
    'caregiver' => 'Caregiver',
    'family_member' => 'Family Member',
    _ => userType,
  };

  Map<String, dynamic> toDatabaseJson() => <String, dynamic>{
    'id': id,
    'full_name': fullName.trim(),
    'phone_number': phoneNumber.trim(),
    'birth_date': birthDate == null ? null : _dateOnly(birthDate!),
    'user_type': userType,
    'address': address.trim(),
    'avatar_path': avatarPath,
  };

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? userType,
    String? address,
    String? avatarPath,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  static String _stringValue(Object? value) => value is String ? value : '';

  static String? _nullableStringValue(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
