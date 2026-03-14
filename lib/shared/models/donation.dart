import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus { available, accepted, pickedUp, delivered, expired }

class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String foodName;
  final String category;
  final int servings;
  final double quantityKg;
  final String description;
  final String pickupAddress;
  final DateTime pickupWindowStart;
  final DateTime pickupWindowEnd;
  /// Base64-encoded image strings (stored in Firestore)
  final List<String> imageBase64List;
  final DonationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  // Ngo tracking
  final String? acceptedByNgoId;
  
  // Volunteer tracking
  final String? assignedVolunteerId;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.foodName,
    required this.category,
    required this.servings,
    required this.quantityKg,
    required this.description,
    required this.pickupAddress,
    required this.pickupWindowStart,
    required this.pickupWindowEnd,
    required this.imageBase64List,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedByNgoId,
    this.assignedVolunteerId,
  });

  factory Donation.fromMap(Map<String, dynamic> data, String documentId) {
    return Donation(
      id: documentId,
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? 'Unknown Donor',
      foodName: data['foodName'] ?? '',
      category: data['category'] ?? 'Veg',
      servings: data['servings'] ?? 0,
      quantityKg: (data['quantityKg'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      pickupWindowStart: (data['pickupWindowStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickupWindowEnd: (data['pickupWindowEnd'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      imageBase64List: List<String>.from(data['imageBase64List'] ?? []),
      status: DonationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DonationStatus.available,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 4)),
      acceptedByNgoId: data['acceptedByNgoId'],
      assignedVolunteerId: data['assignedVolunteerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'foodName': foodName,
      'category': category,
      'servings': servings,
      'quantityKg': quantityKg,
      'description': description,
      'pickupAddress': pickupAddress,
      'pickupWindowStart': Timestamp.fromDate(pickupWindowStart),
      'pickupWindowEnd': Timestamp.fromDate(pickupWindowEnd),
      'imageBase64List': imageBase64List,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'acceptedByNgoId': acceptedByNgoId,
      'assignedVolunteerId': assignedVolunteerId,
    };
  }
}
