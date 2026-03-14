import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:foodbridge/shared/widgets/app_widgets.dart';

class DonationDetailScreen extends ConsumerStatefulWidget {
  final String donationId;
  final String heroTag;

  DonationDetailScreen({
    super.key,
    required this.donationId,
    required this.heroTag,
  });

  @override
  ConsumerState<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends ConsumerState<DonationDetailScreen> {
  late Future<Donation?> _donationFuture;

  @override
  void initState() {
    super.initState();
    _donationFuture = ref.read(donationRepositoryProvider).getDonation(widget.donationId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Donation?>(
      future: _donationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final donation = snapshot.data;
        if (donation == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Donation not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: widget.heroTag,
                    child: _buildHeaderImage(donation),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withAlpha(200),
                    child: const BackButton(color: Colors.black),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesign.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildChip(donation.status.name.toUpperCase(), _getStatusColor(donation.status)),
                          _buildExpiryText(donation),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(donation.foodName, style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('${donation.donorName} • ~1.2 km away', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildSection('Food Details', donation.description.isEmpty ? 'No description provided.' : donation.description),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoBox('Quantity', '${donation.servings} servings'),
                          const SizedBox(width: 16),
                          _buildInfoBox('Category', donation.category),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSection('Pickup Location', ''),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(30)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pickup Address', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    donation.pickupAddress,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Spacing for fab
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: donation.status == DonationStatus.available ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppPrimaryButton(
              text: 'Accept This Donation',
              onPressed: () => _handleAccept(ref, donation),
            ),
          ) : null,
        );
      },
    );
  }

  Widget _buildHeaderImage(Donation donation) {
    if (donation.imageBase64List.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
      );
    }

    try {
      String base64str = donation.imageBase64List.first;
      if (base64str.contains(',')) {
        base64str = base64str.split(',').last;
      }
      base64str = base64str.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(base64str);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    }
  }

  Widget _buildExpiryText(Donation donation) {
    final diff = donation.expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return const Text('Expired', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12));
    }
    return Text(
      'Expiring in ${diff.inHours}h ${diff.inMinutes % 60}m',
      style: TextStyle(
        color: diff.inHours < 2 ? Colors.red : Colors.orange,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available: return AppColors.available;
      case DonationStatus.accepted: return AppColors.accepted;
      case DonationStatus.pickedUp: return AppColors.primary;
      case DonationStatus.delivered: return AppColors.delivered;
      case DonationStatus.expired: return AppColors.expired;
    }
  }

  void _handleAccept(WidgetRef ref, Donation donation) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await ref.read(donationRepositoryProvider).updateDonation(donation.id, {
        'status': DonationStatus.accepted.name,
        'acceptedByNgoId': user.uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation accepted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
