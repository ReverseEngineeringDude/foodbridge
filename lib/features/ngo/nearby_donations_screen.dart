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
import 'package:foodbridge/shared/widgets/location_selector.dart';
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

class NearbyDonationsScreen extends ConsumerStatefulWidget {
  const NearbyDonationsScreen({super.key});

  @override
  ConsumerState<NearbyDonationsScreen> createState() =>
      _NearbyDonationsScreenState();
}

class _NearbyDonationsScreenState extends ConsumerState<NearbyDonationsScreen> {
  String? _filterDistrict;
  String? _filterSubDistrict;
  String? _filterVillage;
  bool _showFilters = false;

  // ── LOGIC FUNCTIONS (UNCHANGED) ────────────────────────────
  Future<void> _acceptDonation(Donation donation) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await ref.read(donationRepositoryProvider).updateDonation(donation.id, {
        'status': DonationStatus.accepted.name,
        'acceptedByNgoId': user.uid,
      });
      if (mounted) {
        _showSnackBar('Donation accepted successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to accept: $e');
    }
  }

  List<Donation> _applyFilter(List<Donation> donations) {
    if (_filterDistrict == null &&
        _filterSubDistrict == null &&
        _filterVillage == null) {
      return donations;
    }
    return donations.where((d) {
      final addr = d.pickupAddress.toLowerCase();
      if (_filterVillage != null &&
          addr.contains(_filterVillage!.toLowerCase()))
        return true;
      if (_filterSubDistrict != null &&
          addr.contains(_filterSubDistrict!.toLowerCase()))
        return true;
      if (_filterDistrict != null &&
          addr.contains(_filterDistrict!.toLowerCase()))
        return true;
      return _filterDistrict == null;
    }).toList();
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _C.red : _C.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI REDESIGN ────────────────────────────────────────────

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
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildFilterPanel(),
            _buildActiveFilterChips(),
            Expanded(
              child: StreamBuilder<List<Donation>>(
                stream: ref
                    .watch(donationRepositoryProvider)
                    .streamAvailableDonations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _C.pink,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final rawDonations = snapshot.data ?? [];
                  final donations = _applyFilter(rawDonations);

                  if (donations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 50),
                        duration: const Duration(milliseconds: 400),
                        child: _DonationItemCard(
                          donation: donations[index],
                          onAccept: () => _acceptDonation(donations[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: GestureDetector(
          onTap: () async {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              await handleHomeNavigation(context, ref);
            }
          },
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
        'Nearby Food',
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _filterDistrict != null
                  ? _C.pink.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: _filterDistrict != null ? _C.pink : _C.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _C.border),
              ),
              child: LocationSelector(
                initialDistrict: _filterDistrict,
                initialSubDistrict: _filterSubDistrict,
                initialVillage: _filterVillage,
                onChanged: (district, subDistrict, village) {
                  setState(() {
                    _filterDistrict = district;
                    _filterSubDistrict = subDistrict;
                    _filterVillage = village;
                  });
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFilterChips() {
    if (_filterDistrict == null &&
        _filterSubDistrict == null &&
        _filterVillage == null) {
      return const SizedBox.shrink();
    }
    final label = [
      _filterVillage,
      _filterSubDistrict,
      _filterDistrict,
    ].where((e) => e != null).join(', ');

    return FadeIn(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: _C.pink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _C.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _filterDistrict = null;
                _filterSubDistrict = null;
                _filterVillage = null;
              }),
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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
              Icons.search_off_rounded,
              size: 48,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No food nearby',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try clearing filters or check back later.',
            style: TextStyle(color: _C.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Donation Card
// ─────────────────────────────────────────────────────────────
class _DonationItemCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onAccept;

  const _DonationItemCard({required this.donation, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final diff = donation.expiresAt.difference(DateTime.now());
    final hoursExpiring = diff.inHours;
    final isExpired = diff.isNegative;

    final expText = isExpired ? 'Expired' : 'Exp. ${hoursExpiring}h';
    final expColor = isExpired
        ? _C.red
        : (hoursExpiring < 2 ? _C.amber : _C.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            donation.foodName,
                            style: const TextStyle(
                              color: _C.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildExpiryBadge(expText, expColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.donorName} • ~1.2 km',
                      style: const TextStyle(
                        color: _C.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Tag(label: donation.category, color: _C.blue),
                        _Tag(
                          label: '${donation.servings} servings',
                          color: _C.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: 'Details',
                  onTap: () => context.push(
                    '/donation/${donation.id}?heroTag=nearby_hero_${donation.id}',
                  ),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardButton(
                  label: 'Accept',
                  onTap: isExpired ? () {} : onAccept,
                  gradient: isExpired ? null : _C.gradientPink,
                  color: isExpired ? _C.surfaceAlt : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    Widget placeholder = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: _C.textMuted,
        size: 30,
      ),
    );

    if (donation.imageBase64List.isEmpty) return placeholder;

    try {
      final base64String = donation.imageBase64List.first;
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      final bytes = base64Decode(
        cleanBase64.trim().replaceAll(RegExp(r'\s+'), ''),
      );

      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
        ),
      );
    } catch (_) {
      return placeholder;
    }
  }

  Widget _buildExpiryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared UI Components
// ─────────────────────────────────────────────────────────────

class _CardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOutlined;
  final LinearGradient? gradient;
  final Color? color;

  const _CardButton({
    required this.label,
    required this.onTap,
    this.isOutlined = false,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          color: isOutlined
              ? Colors.transparent
              : (gradient == null ? color : null),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: _C.border, width: 1.5) : null,
          boxShadow: (!isOutlined && gradient != null)
              ? [
                  BoxShadow(
                    color: _C.pink.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isOutlined ? _C.textSecondary : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
