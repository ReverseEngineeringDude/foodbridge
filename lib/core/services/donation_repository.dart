import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/shared/models/donation.dart';

final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  return DonationRepository(FirebaseFirestore.instance);
});

class DonationRepository {
  final FirebaseFirestore _firestore;

  DonationRepository(this._firestore);

  CollectionReference get _donations => _firestore.collection('donations');

  /// Creates a new donation in Firestore
  Future<void> createDonation(Donation donation) async {
    await _donations.doc(donation.id).set(donation.toMap());
  }

  /// Updates an existing donation
  Future<void> updateDonation(String id, Map<String, dynamic> data) async {
    await _donations.doc(id).update(data);
  }

  /// Fetches a single donation by ID
  Future<Donation?> getDonation(String id) async {
    final doc = await _donations.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  /// Streams all available donations for NGOs to see
  Stream<List<Donation>> streamAvailableDonations() {
    return _donations
        .where('status', isEqualTo: DonationStatus.available.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams donations by a specific status
  Stream<List<Donation>> streamDonationsByStatus(DonationStatus status) {
    return _donations
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams donations created by a specific donor
  Stream<List<Donation>> streamDonorDonations(String donorId) {
    return _donations
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams donations assigned to a specific volunteer
  Stream<List<Donation>> streamVolunteerTasks(String volunteerId) {
    return _donations
        .where('assignedVolunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams donations accepted by a specific NGO
  Stream<List<Donation>> streamNgoAcceptedDonations(String ngoId) {
    return _donations
        .where('acceptedByNgoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams all donations (for Admin)
  Stream<List<Donation>> streamAllDonations() {
    return _donations
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
