import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// Unified Liquid Glass Palette
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF141416);
  static const surface = Color(0xFF1E1E22);
  static const surfaceAlt = Color(0xFF252529);
  static const border = Color(0xFF2C2C32);

  static const pink = Color(0xFFE040A0);
  static const purple = Color(0xFF7B2FBE);
  static const amber = Color(0xFFF5A623);
  static const green = Color(0xFF3DD68C);
  static const blue = Color(0xFF5B8DEF);
  static const red = Color(0xFFFF4D4D);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: StreamBuilder<List<Donation>>(
            stream: ref.watch(donationRepositoryProvider).streamAllDonations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _C.pink,
                    strokeWidth: 2,
                  ),
                );
              }

              final donations = snapshot.data ?? [];
              if (donations.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 50),
                    duration: const Duration(milliseconds: 400),
                    child: _NotificationCard(donation: donations[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _C.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text(
            'Mark all read',
            style: TextStyle(
              color: _C.pink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you when there\'s\nan update on your deliveries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textMuted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Donation donation;
  const _NotificationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final info = _getNotificationInfo(donation);
    final diff = DateTime.now().difference(donation.createdAt);
    final isUnread = diff.inHours < 1;
    final timeStr = _getTimeString(diff);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnread ? info.color.withOpacity(0.3) : _C.border,
          width: 1.5,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: info.color.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.icon, color: info.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      info.title,
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _C.pink,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info.body,
                  style: TextStyle(
                    color: isUnread ? _C.textPrimary : _C.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: _C.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: _C.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _NotifInfo _getNotificationInfo(Donation d) {
    switch (d.status) {
      case DonationStatus.available:
        return _NotifInfo(
          'New Donation!',
          '${d.donorName} shared "${d.foodName}".',
          Icons.local_fire_department_rounded,
          _C.blue,
        );
      case DonationStatus.accepted:
        return _NotifInfo(
          'Donation Accepted',
          '"${d.foodName}" is now being handled.',
          Icons.check_circle_rounded,
          _C.amber,
        );
      case DonationStatus.pickedUp:
        return _NotifInfo(
          'In Transit',
          'Volunteer has picked up "${d.foodName}".',
          Icons.delivery_dining_rounded,
          _C.purple,
        );
      case DonationStatus.delivered:
        return _NotifInfo(
          'Delivery Success',
          '"${d.foodName}" reached the destination.',
          Icons.verified_rounded,
          _C.green,
        );
      case DonationStatus.expired:
        return _NotifInfo(
          'Donation Expired',
          '"${d.foodName}" is no longer active.',
          Icons.timer_off_rounded,
          _C.red,
        );
    }
  }

  String _getTimeString(Duration diff) {
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _NotifInfo {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  _NotifInfo(this.title, this.body, this.icon, this.color);
}
