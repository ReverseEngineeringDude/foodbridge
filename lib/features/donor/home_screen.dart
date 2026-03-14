import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
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
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);
  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradientImpact = LinearGradient(
    colors: [Color(0xFF3DD68C), Color(0xFF1EAD66)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
// Donor Home Screen
// ─────────────────────────────────────────────────────────────


class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});
  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _Header(),
              const SizedBox(height: 28),
              _ImpactBanner(),
              const SizedBox(height: 24),
              _DonorStatsRow(),
              const SizedBox(height: 32),
              _DonateCTA(),
              const SizedBox(height: 32),
              const _SectionLabel('Recent Donations'),
              const SizedBox(height: 16),
              _RecentDonationsList(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Donor';

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              gradient: _C.gradientPink,
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
                  Icons.favorite_rounded,
                  color: _C.pink,
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
                'Making a difference,',
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
          Container(
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Impact Banner
// ─────────────────────────────────────────────────────────────
class _ImpactBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: _C.gradientImpact,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.green.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImpactBadge(),
                  SizedBox(height: 14),
                  Text(
                    '125 kg saved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'of food kept from waste.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'YOUR IMPACT 🎉',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────
class _DonorStatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamDonorDonations(userId),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final active = all
            .where(
              (d) =>
                  d.status == DonationStatus.available ||
                  d.status == DonationStatus.accepted,
            )
            .length;
        final delivered = all
            .where((d) => d.status == DonationStatus.delivered)
            .length;

        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                _StatCell(
                  value: active.toString(),
                  label: 'Active',
                  color: _C.amber,
                  icon: Icons.pending_outlined,
                ),
                _StatDivider(),
                _StatCell(
                  value: delivered.toString(),
                  label: 'Delivered',
                  color: _C.green,
                  icon: Icons.check_circle_outline,
                ),
                _StatDivider(),
                _StatCell(
                  value: all.length.toString(),
                  label: 'Total',
                  color: _C.blue,
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Donate CTA
// ─────────────────────────────────────────────────────────────
class _DonateCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => context.push('/donate'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.pink.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.pink.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: _C.gradientPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donate Food Now',
                      style: TextStyle(
                        color: _C.pink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Help feed someone today',
                      style: TextStyle(color: _C.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _C.pink,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recent Donations
// ─────────────────────────────────────────────────────────────
class _RecentDonationsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamDonorDonations(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.pink));
        }
        final donations = snapshot.data!.take(3).toList();
        if (donations.isEmpty) return const _EmptyDonationsPlaceholder();
        return Column(
          children: donations.map((d) => _DonationCard(donation: d)).toList(),
        );
      },
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;
  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final accentColor = _getStatusColor(donation.status);
    final time = DateFormat('MMM d, h:mm a').format(donation.createdAt);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            _ImagePreview(
              base64: donation.imageBase64List.isNotEmpty
                  ? donation.imageBase64List.first
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.foodName,
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(color: _C.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _Tag(
                        label: '${donation.servings} servings',
                        color: _C.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: donation.status, color: accentColor),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus s) {
    switch (s) {
      case DonationStatus.available:
        return _C.blue;
      case DonationStatus.accepted:
        return _C.amber;
      case DonationStatus.pickedUp:
        return _C.purple;
      case DonationStatus.delivered:
        return _C.green;
      default:
        return _C.textMuted;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Components
// ─────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _C.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: _C.border);
}

class _StatusBadge extends StatelessWidget {
  final DonationStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? base64;
  const _ImagePreview({this.base64});

  @override
  Widget build(BuildContext context) {
    // FIX 4 — original used base64!.split(',').last which crashes when the
    //          stored string has no comma (plain base64 has no comma prefix).
    //          Now safely strips the data URI prefix if present, falls back
    //          to the icon on any decode error.
    Widget? imageWidget;
    if (base64 != null) {
      try {
        final raw = base64!.contains(',') ? base64!.split(',').last : base64!;
        final bytes = base64Decode(raw.replaceAll(RegExp(r'\s+'), ''));
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, width: 64, height: 64),
        );
      } catch (_) {
        imageWidget = null; // fall through to icon
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          imageWidget ??
          const Icon(Icons.restaurant_rounded, color: _C.textMuted, size: 24),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
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
}

class _EmptyDonationsPlaceholder extends StatelessWidget {
  const _EmptyDonationsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: _C.textMuted,
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'No donations yet',
            style: TextStyle(
              color: _C.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Start your journey by donating food.',
            style: TextStyle(color: _C.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Liquid Glass Bottom Nav
// ─────────────────────────────────────────────────────────────

