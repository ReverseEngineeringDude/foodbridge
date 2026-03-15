import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';

// ─────────────────────────────────────────────────────────────
// Color Palette — matches the whole app
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
  static const coral = Color(0xFFFF6B6B);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class NGOHomeScreen extends ConsumerStatefulWidget {
  const NGOHomeScreen({super.key});
  @override
  ConsumerState<NGOHomeScreen> createState() => _NGOHomeScreenState();
}

class _NGOHomeScreenState extends ConsumerState<NGOHomeScreen> {
  @override
  Widget build(BuildContext context) {
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
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        extendBody: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(context, ref),
                const SizedBox(height: 24),
                _buildStatsGrid(ref),
                const SizedBox(height: 28),
                _buildNearbyMapPreview(context, ref),
                const SizedBox(height: 28),
                _buildSectionRow(context),
                const SizedBox(height: 16),
                _buildAcceptedDonationsFeed(ref),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION HEADER ROW ──────────────────────────────────────
  Widget _buildSectionRow(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Recently Accepted',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _C.border)),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push('/accepted-donations'),
          child: Text(
            'View All',
            style: TextStyle(
              color: _C.pink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── ALL ORIGINAL FUNCTIONS — UNTOUCHED ────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'NGO';

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Row(
        children: [
          // Gradient ring avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              gradient: _C.gradientGreen,
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: _C.bg,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _C.surfaceAlt,
                child: const Icon(
                  Icons.corporate_fare_rounded,
                  color: _C.green,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome,',
                style: TextStyle(
                  color: _C.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _C.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamNgoAcceptedDonations(userId),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final accepted = donations
            .where(
              (d) =>
                  d.status == DonationStatus.accepted ||
                  d.status == DonationStatus.pickedUp,
            )
            .length;
        final received = donations
            .where((d) => d.status == DonationStatus.delivered)
            .length;
        final peopleFed = donations
            .where((d) => d.status == DonationStatus.delivered)
            .fold<int>(0, (sum, d) => sum + d.servings);
        final fedLabel = peopleFed >= 1000
            ? '${(peopleFed / 1000).toStringAsFixed(1)}k'
            : peopleFed.toString();

        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                _buildStatCell(
                  'Accepted',
                  accepted.toString(),
                  Icons.task_alt_outlined,
                  _C.amber,
                ),
                _statDivider(),
                _buildStatCell(
                  'Received',
                  received.toString(),
                  Icons.inventory_2_outlined,
                  _C.green,
                ),
                _statDivider(),
                _buildStatCell(
                  'People Fed',
                  fedLabel,
                  Icons.people_outline_rounded,
                  _C.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCell(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _C.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 44, color: _C.border);

  Widget _buildNearbyMapPreview(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamAvailableDonations(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: () => context.push('/nearby-donations'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: _C.gradientGreen,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEARBY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$count Donations Available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Browse food donations near you by state, district & area',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Browse Nearby',
                            style: TextStyle(
                              color: Color(0xFF2D6A4F),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF2D6A4F),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcceptedDonationsFeed(WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamNgoAcceptedDonations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _C.green, strokeWidth: 2),
            ),
          );
        }
        final donations = snapshot.data ?? [];
        final activeDonations = donations
            .where(
              (d) =>
                  d.status == DonationStatus.accepted ||
                  d.status == DonationStatus.pickedUp,
            )
            .toList();

        if (activeDonations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: const [
                Icon(Icons.inbox_outlined, color: _C.textMuted, size: 40),
                SizedBox(height: 12, width: double.infinity),
                Text(
                  'No accepted donations yet.',
                  style: TextStyle(
                    color: _C.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Browse nearby donations to get started.',
                  style: TextStyle(color: _C.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Column(
          children: activeDonations.take(2).map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSimpleDonationCard(
                d.donorName,
                '${d.servings} servings',
                'Ongoing',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSimpleDonationCard(String donor, String items, String status) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.green.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: _C.green.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.corporate_fare_rounded,
                color: _C.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor,
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$items  ·  $status',
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _C.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.green.withOpacity(0.25)),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: _C.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: _C.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
