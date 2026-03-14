import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:intl/intl.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// Dark Theme Color Palette (Unified)
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
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Text(
            'Please log in',
            style: TextStyle(color: _C.textSecondary),
          ),
        ),
      );
    }

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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: StreamBuilder<List<Donation>>(
                  stream: ref
                      .watch(donationRepositoryProvider)
                      .streamDonorDonations(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _C.pink,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final allDonations = snapshot.data ?? [];
                    final delivered = allDonations
                        .where((d) => d.status == DonationStatus.delivered)
                        .toList();
                    final expired = allDonations
                        .where((d) => d.status == DonationStatus.expired)
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildList(allDonations),
                        _buildList(delivered),
                        _buildList(expired),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
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
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR CONTRIBUTIONS',
                style: TextStyle(
                  color: _C.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Donation History',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: _C.textMuted,
        indicator: BoxDecoration(
          gradient: _C.gradientPink,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _C.pink.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Delivered'),
          Tab(text: 'Expired'),
        ],
      ),
    );
  }

  Widget _buildList(List<Donation> items) {
    if (items.isEmpty) {
      return Center(
        child: FadeIn(
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
                  Icons.history_rounded,
                  size: 40,
                  color: _C.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No donations found',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your history will appear here',
                style: TextStyle(color: _C.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 400),
          child: _DonationHistoryCard(item: items[index]),
        );
      },
    );
  }
}

class _DonationHistoryCard extends StatelessWidget {
  final Donation item;
  const _DonationHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    final date = DateFormat('d MMM yyyy').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: item.imageBase64List.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(
                        item.imageBase64List.first.contains(',')
                            ? item.imageBase64List.first.split(',').last
                            : item.imageBase64List.first,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(Icons.restaurant_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Tag(label: '${item.servings} servings', color: _C.amber),
                    const SizedBox(width: 8),
                    _Tag(label: date, color: _C.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: item.status, color: statusColor),
        ],
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
        return Colors.redAccent;
      default:
        return _C.textMuted;
    }
  }
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
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
