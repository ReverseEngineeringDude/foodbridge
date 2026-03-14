import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/models/donation.dart';

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
}

class AdminSystemReportsScreen extends ConsumerWidget {
  const AdminSystemReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _C.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'System Reports',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Donation Overview'),
            const SizedBox(height: 14),
            _buildDonationStats(ref),
            const SizedBox(height: 28),
            _buildSectionHeader('User Breakdown'),
            const SizedBox(height: 14),
            _buildUserStats(ref),
            const SizedBox(height: 28),
            _buildSectionHeader('Impact Metrics'),
            const SizedBox(height: 14),
            _buildImpactStats(ref),
          ],
        ),
      ),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }

  // ── ALL ORIGINAL FUNCTIONS — UNTOUCHED ────────────────────
  Widget _buildDonationStats(WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamAllDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final available = donations
            .where((d) => d.status == DonationStatus.available)
            .length;
        final accepted = donations
            .where((d) => d.status == DonationStatus.accepted)
            .length;
        final pickedUp = donations
            .where((d) => d.status == DonationStatus.pickedUp)
            .length;
        final delivered = donations
            .where((d) => d.status == DonationStatus.delivered)
            .length;
        final expired = donations
            .where((d) => d.status == DonationStatus.expired)
            .length;

        return _buildReportGroup([
          _RowData(
            'Total Donations',
            donations.length.toString(),
            Icons.restaurant_outlined,
            _C.pink,
          ),
          _RowData(
            'Available',
            available.toString(),
            Icons.check_circle_outline,
            _C.blue,
          ),
          _RowData(
            'Accepted',
            accepted.toString(),
            Icons.task_alt_outlined,
            _C.amber,
          ),
          _RowData(
            'Picked Up',
            pickedUp.toString(),
            Icons.local_shipping_outlined,
            _C.purple,
          ),
          _RowData(
            'Delivered',
            delivered.toString(),
            Icons.done_all_rounded,
            _C.green,
          ),
          _RowData(
            'Expired',
            expired.toString(),
            Icons.cancel_outlined,
            _C.coral,
          ),
        ]);
      },
    );
  }

  Widget _buildUserStats(WidgetRef ref) {
    return StreamBuilder<List<AppUser>>(
      stream: ref.watch(userRepositoryProvider).streamAllUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final donors = users.where((u) => u.role == AppRole.donor).length;
        final ngos = users.where((u) => u.role == AppRole.ngo).length;
        final volunteers = users
            .where((u) => u.role == AppRole.volunteer)
            .length;
        final admins = users.where((u) => u.role == AppRole.admin).length;

        return _buildReportGroup([
          _RowData(
            'Total Users',
            users.length.toString(),
            Icons.people_outline_rounded,
            _C.pink,
          ),
          _RowData(
            'Donors',
            donors.toString(),
            Icons.volunteer_activism_outlined,
            _C.amber,
          ),
          _RowData(
            'NGOs',
            ngos.toString(),
            Icons.corporate_fare_rounded,
            _C.green,
          ),
          _RowData(
            'Volunteers',
            volunteers.toString(),
            Icons.delivery_dining_rounded,
            _C.blue,
          ),
          _RowData(
            'Admins',
            admins.toString(),
            Icons.admin_panel_settings_outlined,
            _C.coral,
          ),
        ]);
      },
    );
  }

  Widget _buildImpactStats(WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamAllDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final delivered = donations.where(
          (d) => d.status == DonationStatus.delivered,
        );
        final totalKg = delivered.fold<double>(0, (s, d) => s + d.quantityKg);
        final totalServings = delivered.fold<int>(0, (s, d) => s + d.servings);

        return _buildReportGroup([
          _RowData(
            'Total kg Delivered',
            totalKg.toStringAsFixed(1),
            Icons.scale_outlined,
            _C.green,
          ),
          _RowData(
            'Total Servings Provided',
            totalServings.toString(),
            Icons.people_outline_rounded,
            _C.blue,
          ),
        ]);
      },
    );
  }

  // ── REDESIGNED REPORT ROW RENDERER ────────────────────────
  Widget _buildReportGroup(List<_RowData> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              _buildReportRow(
                e.value.label,
                e.value.value,
                e.value.icon,
                e.value.color,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: _C.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
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
                color: _C.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple data holder for report rows
class _RowData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _RowData(this.label, this.value, this.icon, this.color);
}
