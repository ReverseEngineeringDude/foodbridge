import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<Donation>>(
        stream: ref.watch(donationRepositoryProvider).streamAllDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final donations = snapshot.data ?? [];
          if (donations.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDesign.padding),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              return _buildNotificationFromDonation(donations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationFromDonation(Donation d) {
    String title;
    String body;
    IconData icon;
    Color color;

    switch (d.status) {
      case DonationStatus.available:
        title = 'New Donation Nearby!';
        body = '${d.donorName} added "${d.foodName}".';
        icon = Icons.location_on;
        color = AppColors.primary;
        break;
      case DonationStatus.accepted:
        title = 'Donation Accepted';
        body = '"${d.foodName}" has been accepted.';
        icon = Icons.check_circle;
        color = AppColors.accepted;
        break;
      case DonationStatus.pickedUp:
        title = 'Donation Picked Up';
        body = '"${d.foodName}" is on the way.';
        icon = Icons.local_shipping;
        color = AppColors.pickedUp;
        break;
      case DonationStatus.delivered:
        title = 'Delivery Successful';
        body = '"${d.foodName}" was delivered successfully.';
        icon = Icons.delivery_dining;
        color = AppColors.delivered;
        break;
      case DonationStatus.expired:
        title = 'Donation Expired';
        body = '"${d.foodName}" is no longer available.';
        icon = Icons.cancel;
        color = AppColors.expired;
        break;
    }

    final diff = DateTime.now().difference(d.createdAt);
    String timeStr;
    if (diff.inDays > 0) {
      timeStr = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      timeStr = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      timeStr = '${diff.inMinutes}m ago';
    } else {
      timeStr = 'Just now';
    }

    // Treat new donations within the last hour as 'unread' for UX flair
    final isUnread = diff.inHours < 1;

    return _buildNotificationItem(title, body, icon, color, timeStr, isUnread);
  }

  Widget _buildNotificationItem(String title, String body, IconData icon, Color color, String time, bool isUnread) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? color.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUnread ? color.withAlpha(30) : Colors.grey[100]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(fontSize: 12, color: isUnread ? AppColors.textPrimary : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
