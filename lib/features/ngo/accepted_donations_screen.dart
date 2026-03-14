import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:intl/intl.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

class AcceptedDonationsScreen extends ConsumerWidget {
  const AcceptedDonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

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
          title: const Text('Accepted Donations'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                await handleHomeNavigation(context, ref);
              }
            },
          ),
        ),
        body: StreamBuilder<List<Donation>>(
          stream: ref.watch(donationRepositoryProvider).streamNgoAcceptedDonations(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fact_check_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No accepted donations yet', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDesign.padding),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final donation = items[index];
                final time = DateFormat('MMM d, h:mm a').format(donation.createdAt);
                
                Color statusColor = AppColors.available;
                switch (donation.status) {
                  case DonationStatus.available: statusColor = AppColors.available; break;
                  case DonationStatus.accepted: statusColor = AppColors.accepted; break;
                  case DonationStatus.pickedUp: statusColor = AppColors.primary; break;
                  case DonationStatus.delivered: statusColor = AppColors.delivered; break;
                  case DonationStatus.expired: statusColor = AppColors.expired; break;
                }

                return FadeInUp(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: AppDesign.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                donation.foodName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                donation.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${donation.servings} servings', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Spacer(),
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.business, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(donation.donorName, style: const TextStyle(fontWeight: FontWeight.w500))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push('/donation/${donation.id}?heroTag=accepted_hero_${donation.id}'),
                            child: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
