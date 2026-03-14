import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:foodbridge/shared/widgets/location_selector.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

class NearbyDonationsScreen extends ConsumerStatefulWidget {
  const NearbyDonationsScreen({super.key});

  @override
  ConsumerState<NearbyDonationsScreen> createState() => _NearbyDonationsScreenState();
}

class _NearbyDonationsScreenState extends ConsumerState<NearbyDonationsScreen> {
  String? _filterDistrict;
  String? _filterSubDistrict;
  String? _filterVillage;
  bool _showFilters = false;

  Future<void> _acceptDonation(Donation donation) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await ref.read(donationRepositoryProvider).updateDonation(
        donation.id,
        {
          'status': DonationStatus.accepted.name,
          'acceptedByNgoId': user.uid,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation accepted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  List<Donation> _applyFilter(List<Donation> donations) {
    if (_filterDistrict == null && _filterSubDistrict == null && _filterVillage == null) {
      return donations;
    }
    return donations.where((d) {
      final addr = d.pickupAddress.toLowerCase();
      if (_filterVillage != null && addr.contains(_filterVillage!.toLowerCase())) return true;
      if (_filterSubDistrict != null && addr.contains(_filterSubDistrict!.toLowerCase())) return true;
      if (_filterDistrict != null && addr.contains(_filterDistrict!.toLowerCase())) return true;
      return _filterDistrict == null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Food'),
          actions: [
            IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(
                Icons.filter_list,
                color: _filterDistrict != null ? AppColors.primary : null,
              ),
              tooltip: 'Filter by location',
            ),
          ],
        ),
        body: Column(
          children: [
            // Location filter header
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: LocationSelector(
                        initialDistrict: _filterDistrict,
                        initialSubDistrict: _filterSubDistrict,
                        initialVillage: _filterVillage,
                        onChanged: (district, subDistrict, village) {
                          setState(() {
                            _filterDistrict = district;
                            _filterSubDistrict = subDistrict;
                            _filterVillage = village;
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_filterDistrict != null || _filterSubDistrict != null || _filterVillage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [_filterVillage, _filterSubDistrict, _filterDistrict].where((e) => e != null).join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _filterDistrict = null;
                        _filterSubDistrict = null;
                        _filterVillage = null;
                      }),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Donation>>(
                stream: ref.watch(donationRepositoryProvider).streamAvailableDonations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rawDonations = snapshot.data ?? [];
                  final donations = _applyFilter(rawDonations);

                  if (donations.isEmpty) {
                    return const Center(child: Text('No donations available nearby right now.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      return FadeInUp(
                        child: _buildDonationItemCard(donations[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDonationItemCard(Donation donation) {
    final hoursExpiring = donation.expiresAt.difference(DateTime.now()).inHours;
    final expText = hoursExpiring > 0 ? 'Exp. ${hoursExpiring}h' : 'Expired';
    final expColor = hoursExpiring > 1 ? Colors.orange : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDonationThumbnail(donation.imageBase64List),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            donation.foodName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: expColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            expText,
                            style: TextStyle(color: expColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${donation.donorName} • ~1.2 km away',
                            style: const TextStyle(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTag(donation.category, AppColors.available),
                        _buildTag('${donation.servings} servings', AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/donation/${donation.id}?heroTag=nearby_hero_${donation.id}'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptDonation(donation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationThumbnail(List<String> imageBase64List) {
    if (imageBase64List.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 32),
      );
    }
    try {
      String base64str = imageBase64List.first;
      if (base64str.contains(',')) {
        base64str = base64str.split(',').last;
      }
      // Remove whitespace/newlines that might break base64Decode
      base64str = base64str.replaceAll(RegExp(r'\s+'), '');
      
      final bytes = base64Decode(base64str);
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 32),
      );
    }
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
