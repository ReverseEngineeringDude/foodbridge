import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:intl/intl.dart';

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

class AdminDonationMonitorScreen extends ConsumerStatefulWidget {
  const AdminDonationMonitorScreen({super.key});

  @override
  ConsumerState<AdminDonationMonitorScreen> createState() =>
      _AdminDonationMonitorScreenState();
}

class _AdminDonationMonitorScreenState
    extends ConsumerState<AdminDonationMonitorScreen> {
  DonationStatus? _filterStatus;

  // ── ORIGINAL MAP — UNTOUCHED ──────────────────────────────
  static const _statusColors = {
    DonationStatus.available: AppColors.available,
    DonationStatus.accepted: AppColors.accepted,
    DonationStatus.pickedUp: AppColors.pickedUp,
    DonationStatus.delivered: AppColors.delivered,
    DonationStatus.expired: AppColors.expired,
  };

  @override
  Widget build(BuildContext context) {
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
          'Donation Monitor',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: StreamBuilder<List<Donation>>(
              stream: ref
                  .watch(donationRepositoryProvider)
                  .streamAllDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _C.pink,
                      strokeWidth: 2,
                    ),
                  );
                }

                var donations = snapshot.data ?? [];
                if (_filterStatus != null) {
                  donations = donations
                      .where((d) => d.status == _filterStatus)
                      .toList();
                }

                if (donations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          color: _C.textMuted,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No donations found.',
                          style: TextStyle(
                            color: _C.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: donations.length,
                  itemBuilder: (context, index) =>
                      _buildDonationCard(donations[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── ALL ORIGINAL FUNCTIONS — UNTOUCHED ────────────────────
  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(bottom: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _filterChip('All', null),
            const SizedBox(width: 8),
            ...DonationStatus.values.map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(s.name.toUpperCase(), s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, DonationStatus? status) {
    final isSelected = _filterStatus == status;
    final Color color;
    if (status == null) {
      color = _C.pink;
    } else {
      color = _statusColors[status] ?? _C.textSecondary;
    }
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? _C.gradientPink : null,
          color: isSelected ? null : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.30),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _C.pink.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(Donation d) {
    final color = _statusColors[d.status] ?? _C.textSecondary;
    final time = DateFormat('MMM d, h:mm a').format(d.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  d.foodName,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Text(
                  d.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _infoChip(Icons.person_outline_rounded, d.donorName),
                _infoChip(
                  Icons.people_outline_rounded,
                  '${d.servings} servings',
                ),
                _infoChip(Icons.scale_outlined, '${d.quantityKg} kg'),
                _infoChip(Icons.access_time_rounded, time),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _C.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _C.textSecondary),
        ),
      ],
    );
  }
}
