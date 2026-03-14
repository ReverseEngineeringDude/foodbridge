import 'package:cloud_firestore/cloud_firestore.dart';

enum AppRole { donor, ngo, volunteer, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? extraData; // For NGO registration number, Volunteer vehicle info, etc.

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    this.extraData,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: AppRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => AppRole.donor,
      ),
      phone: data['phone'],
      address: data['address'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      extraData: data['extraData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'extraData': extraData,
    };
  }
}
