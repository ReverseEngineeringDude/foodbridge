import 'dart:convert';
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

class DonationDetailScreen extends ConsumerStatefulWidget {
  final String donationId;
  final String heroTag;

  const DonationDetailScreen({
    super.key,
    required this.donationId,
    required this.heroTag,
  });

  @override
  ConsumerState<DonationDetailScreen> createState() =>
      _DonationDetailScreenState();
}

class _DonationDetailScreenState extends ConsumerState<DonationDetailScreen> {
  late Future<Donation?> _donationFuture;

  @override
  void initState() {
    super.initState();
    _donationFuture = ref
        .read(donationRepositoryProvider)
        .getDonation(widget.donationId);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return FutureBuilder<Donation?>(
      future: _donationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _C.bg,
            body: Center(
              child: CircularProgressIndicator(color: _C.pink, strokeWidth: 2),
            ),
          );
        }

        final donation = snapshot.data;
        if (donation == null) {
          return Scaffold(
            backgroundColor: _C.bg,
            appBar: AppBar(backgroundColor: _C.bg, elevation: 0),
            body: const Center(
              child: Text(
                'Donation not found',
                style: TextStyle(color: _C.textSecondary),
              ),
            ),
          );
        }

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
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(donation),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 400),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusBadge(status: donation.status),
                              _buildExpiryText(donation),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInLeft(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            donation.foodName,
                            style: const TextStyle(
                              color: _C.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeInLeft(
                          delay: const Duration(milliseconds: 100),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                size: 16,
                                color: _C.pink,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${donation.donorName} • ~1.2 km away',
                                style: const TextStyle(
                                  color: _C.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionDivider(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Food Details'),
                        const SizedBox(height: 12),
                        Text(
                          donation.description.isEmpty
                              ? 'No description provided.'
                              : donation.description,
                          style: const TextStyle(
                            color: _C.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildInfoTile(
                              'Quantity',
                              '${donation.servings} servings',
                              Icons.people_outline_rounded,
                              _C.amber,
                            ),
                            const SizedBox(width: 16),
                            _buildInfoTile(
                              'Category',
                              donation.category,
                              Icons.restaurant_menu_rounded,
                              _C.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildSectionTitle('Pickup Location'),
                        const SizedBox(height: 16),
                        _buildLocationCard(donation.pickupAddress),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: donation.status == DonationStatus.available
                ? FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _GlassActionButton(
                        label: 'Accept This Donation',
                        onTap: () => _handleAccept(ref, donation),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(Donation donation) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: _C.bg,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GestureDetector(
          onTap: () async {
            if (context.canPop()) {
              context.pop();
            } else {
              await handleHomeNavigation(context, ref);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: widget.heroTag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildHeaderImage(donation),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.bg, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(Donation donation) {
    if (donation.imageBase64List.isEmpty) {
      return Container(
        color: _C.surfaceAlt,
        child: const Icon(
          Icons.restaurant_rounded,
          size: 80,
          color: _C.textMuted,
        ),
      );
    }

    try {
      String base64str = donation.imageBase64List.first;
      if (base64str.contains(',')) {
        base64str = base64str.split(',').last;
      }
      base64str = base64str.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(base64str);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      return Container(
        color: _C.surfaceAlt,
        child: const Icon(
          Icons.broken_image_rounded,
          size: 80,
          color: _C.textMuted,
        ),
      );
    }
  }

  Widget _buildExpiryText(Donation donation) {
    final diff = donation.expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return const Text(
        'EXPIRED',
        style: TextStyle(
          color: _C.red,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1,
        ),
      );
    }
    final color = diff.inHours < 2 ? _C.red : _C.amber;
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          'EXPIRING IN ${diff.inHours}h ${diff.inMinutes % 60}m',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _C.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSectionDivider() => Container(height: 1, color: _C.border);

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: _C.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: _C.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: _C.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PICKUP ADDRESS',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAccept(WidgetRef ref, Donation donation) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await ref.read(donationRepositoryProvider).updateDonation(donation.id, {
        'status': DonationStatus.accepted.name,
        'acceptedByNgoId': user.uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Donation accepted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _C.surfaceAlt,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: _C.red,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Components
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final DonationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
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
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
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
      case DonationStatus.expired:
        return _C.red;
    }
  }
}

class _GlassActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _C.gradientPink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _C.pink.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
