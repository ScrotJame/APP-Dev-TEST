import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String department;
  final String unit;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.department,
    this.unit = '',
    required this.isActive,
    this.createdAt,
  });

  // Backward compatibility getter
  String get donVi => unit;

  UserModel copyWith({
    String? displayName,
    String? email,
    String? role,
    String? department,
    String? unit,
    String? donVi,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      unit: unit ?? donVi ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'department': department,
      'unit': unit,
      'donVi': unit,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      displayName: (map['displayName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? '') as String,
      department: (map['department'] ?? '') as String,
      unit: (map['unit'] ?? map['donVi'] ?? '') as String,
      isActive: (map['isActive'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    email,
    role,
    department,
    unit,
    isActive,
    createdAt,
  ];
}
