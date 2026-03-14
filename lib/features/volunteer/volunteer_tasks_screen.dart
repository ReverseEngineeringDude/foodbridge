import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// Dark Theme Color Palette
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

// ─────────────────────────────────────────────────────────────
// Nav Item Data
// ─────────────────────────────────────────────────────────────
class VolunteerTasksScreen extends ConsumerWidget {
  const VolunteerTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final userId = ref.watch(authServiceProvider).currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: const Center(
          child: Text(
            'Please log in',
            style: TextStyle(color: _C.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
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
          'My Tasks',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<List<Donation>>(
        stream: ref
            .watch(donationRepositoryProvider)
            .streamVolunteerTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _C.pink, strokeWidth: 2),
            );
          }

          final all = snapshot.data ?? [];

          final active = all
              .where(
                (d) =>
                    d.status == DonationStatus.accepted ||
                    d.status == DonationStatus.pickedUp,
              )
              .toList();

          final completed = all
              .where((d) => d.status == DonationStatus.delivered)
              .toList();

          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
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
                        Icons.delivery_dining_rounded,
                        size: 44,
                        color: _C.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No tasks yet.',
                      style: TextStyle(
                        color: _C.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accept a delivery from the home screen\nto get started.',
                      style: TextStyle(
                        color: _C.textMuted,
                        fontSize: 13,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            physics: const BouncingScrollPhysics(),
            children: [
              if (active.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildGroupHeader('Active Tasks', active.length, _C.pink),
                const SizedBox(height: 14),
                ...active.map((d) => _buildTaskCard(context, d)),
                const SizedBox(height: 28),
              ],
              if (completed.isNotEmpty) ...[
                _buildGroupHeader('Completed', completed.length, _C.green),
                const SizedBox(height: 14),
                ...completed.map((d) => _buildTaskCard(context, d)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── UNTOUCHED FUNCTIONS ────────────────────────────────────

  Widget _buildGroupHeader(String title, int count, Color accent) {
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
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.28)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Donation d) {
    final isActive =
        d.status == DonationStatus.accepted ||
        d.status == DonationStatus.pickedUp;
    final color = _statusColor(d.status);
    final date = DateFormat('MMM d, h:mm a').format(d.createdAt);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withOpacity(0.30) : _C.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.delivery_dining_rounded
                        : Icons.check_circle_outline_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.foodName,
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.28)),
                  ),
                  child: Text(
                    _statusLabel(d.status),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: _C.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'From: ${d.donorName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: _C.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (isActive)
              _GradientButton(
                label: 'Continue',
                icon: Icons.directions_rounded,
                onTap: () => context.push('/active-task'),
              )
            else
              _OutlineButton(
                label: 'View Details',
                icon: Icons.info_outline_rounded,
                color: _C.blue,
                onTap: () =>
                    context.push('/donation/${d.id}?title=Delivery Details'),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(DonationStatus s) {
    switch (s) {
      case DonationStatus.accepted:
        return AppColors.accepted;
      case DonationStatus.pickedUp:
        return AppColors.pickedUp;
      case DonationStatus.delivered:
        return AppColors.delivered;
      default:
        return AppColors.expired;
    }
  }

  String _statusLabel(DonationStatus s) {
    switch (s) {
      case DonationStatus.accepted:
        return 'ACCEPTED';
      case DonationStatus.pickedUp:
        return 'EN ROUTE';
      case DonationStatus.delivered:
        return 'DELIVERED';
      default:
        return s.name.toUpperCase();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable Button Widgets  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: _C.gradientPink,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: _C.pink.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


