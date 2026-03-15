import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:intl/intl.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// Color Palette
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
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
        appBar: _buildAppBar(context, ref),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(ref),
              const SizedBox(height: 32),
              _buildSectionHeader('Management'),
              const SizedBox(height: 16),
              _buildManagementGrid(context),
              const SizedBox(height: 32),
              _buildSectionHeader('NGO Approvals'),
              const SizedBox(height: 16),
              _buildPendingNGOsList(context, ref),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text(
        'Admin Console',
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => _showSettings(context, ref),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: _C.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── SECTION HEADER ─────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }

  // ── STATS GRID — FUNCTIONS UNTOUCHED ───────────────────────
  Widget _buildStatsGrid(WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: [
        _buildUsersStat(ref),
        _buildActiveDonationsStat(ref),
        _buildPendingNGOsStat(ref),
        _buildDeliveredKgStat(ref),
      ],
    );
  }

  Widget _buildUsersStat(WidgetRef ref) {
    return StreamBuilder<List<AppUser>>(
      stream: ref.watch(userRepositoryProvider).streamAllUsers(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildStatCard(
          'Total Users',
          count.toString(),
          Icons.people_outline_rounded,
          _C.pink,
        );
      },
    );
  }

  Widget _buildActiveDonationsStat(WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamAvailableDonations(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildStatCard(
          'Active Donations',
          count.toString(),
          Icons.restaurant_rounded,
          _C.amber,
        );
      },
    );
  }

  Widget _buildPendingNGOsStat(WidgetRef ref) {
    return StreamBuilder<List<AppUser>>(
      stream: ref.watch(userRepositoryProvider).streamPendingNGOs(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildStatCard(
          'Pending NGOs',
          count.toString(),
          Icons.corporate_fare_rounded,
          _C.coral,
        );
      },
    );
  }

  Widget _buildDeliveredKgStat(WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamAllDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final deliveredDonations = donations.where(
          (d) => d.status == DonationStatus.delivered,
        );
        final totalKg = deliveredDonations.fold<double>(
          0,
          (sum, d) => sum + d.quantityKg,
        );
        return _buildStatCard(
          'Delivered (kg)',
          totalKg.toStringAsFixed(1),
          Icons.done_all_rounded,
          _C.green,
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── MANAGEMENT GRID — FUNCTION UNTOUCHED ───────────────────
  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionTile(
          context,
          'Manage Users',
          Icons.manage_accounts_rounded,
          _C.pink,
          '/admin-users',
        ),
        _buildActionTile(
          context,
          'Donation Monitor',
          Icons.monitor_heart_outlined,
          _C.green,
          '/admin-donations',
        ),
        _buildActionTile(
          context,
          'System Reports',
          Icons.analytics_outlined,
          _C.amber,
          '/admin-reports',
        ),
        _buildActionTile(
          context,
          'Notifications',
          Icons.campaign_outlined,
          _C.blue,
          '/notifications',
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.08),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _C.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── NGO APPROVALS — FUNCTIONS UNTOUCHED ────────────────────
  Widget _buildPendingNGOsList(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<AppUser>>(
      stream: ref.watch(userRepositoryProvider).streamPendingNGOs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _C.pink, strokeWidth: 2),
            ),
          );
        }
        final ngos = snapshot.data ?? [];
        if (ngos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: _C.green,
                  size: 36,
                ),
                SizedBox(height: 10, width: double.infinity),
                Text(
                  'No pending NGO approvals.',
                  style: TextStyle(
                    color: _C.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: ngos
              .map(
                (ngo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNGORequestCard(context, ref, ngo),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNGORequestCard(
    BuildContext context,
    WidgetRef ref,
    AppUser ngo,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.amber.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: _C.amber.withOpacity(0.06),
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
                color: _C.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.corporate_fare_rounded,
                color: _C.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ngo.name,
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Requested on ${DateFormat('yyyy-MM-dd').format(ngo.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showNGOReviewSheet(context, ref, ngo),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: _C.gradientPink,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.pink.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNGOReviewSheet(BuildContext context, WidgetRef ref, AppUser ngo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.corporate_fare_rounded,
                    color: _C.amber,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo.name,
                        style: const TextStyle(
                          color: _C.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ngo.email,
                        style: const TextStyle(
                          color: _C.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              height: 1,
              color: _C.border,
            ),
            if (ngo.phone != null) ...[
              _reviewRow(Icons.phone_outlined, 'Phone', ngo.phone!),
              const SizedBox(height: 10),
            ],
            if (ngo.extraData?['registrationNumber'] != null)
              _reviewRow(
                Icons.badge_outlined,
                'Reg. No.',
                ngo.extraData!['registrationNumber'],
              ),
            _reviewRow(
              Icons.calendar_today_outlined,
              'Applied on',
              DateFormat('MMM d, yyyy').format(ngo.createdAt),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await ref
                          .read(userRepositoryProvider)
                          .saveUser(
                            AppUser(
                              id: ngo.id,
                              name: ngo.name,
                              email: ngo.email,
                              role: ngo.role,
                              phone: ngo.phone,
                              profileImageUrl: ngo.profileImageUrl,
                              createdAt: ngo.createdAt,
                              extraData: {
                                ...?ngo.extraData,
                                'isApproved': false,
                              },
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _C.coral.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.coral.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            color: _C.coral,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reject',
                            style: TextStyle(
                              color: _C.coral,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await ref
                          .read(userRepositoryProvider)
                          .saveUser(
                            AppUser(
                              id: ngo.id,
                              name: ngo.name,
                              email: ngo.email,
                              role: ngo.role,
                              phone: ngo.phone,
                              profileImageUrl: ngo.profileImageUrl,
                              createdAt: ngo.createdAt,
                              extraData: {
                                ...?ngo.extraData,
                                'isApproved': true,
                              },
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${ngo.name} approved!'),
                            backgroundColor: _C.surfaceAlt,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_C.green, const Color(0xFF1EAD66)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _C.green.withOpacity(0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Approve',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _C.textMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: _C.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _C.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Admin Settings',
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _settingsTile(
              ctx,
              context,
              'Manage Users',
              Icons.person_outline_rounded,
              _C.pink,
              '/admin-users',
            ),
            _settingsTile(
              ctx,
              context,
              'Notifications',
              Icons.notifications_none_rounded,
              _C.blue,
              '/notifications',
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 1,
              color: _C.border,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.coral.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: _C.coral,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: _C.coral,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 100),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext ctx,
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          context.push(route);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _C.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
