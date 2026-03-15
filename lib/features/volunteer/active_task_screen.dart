import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// Unified Liquid Glass Palette
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF141416);
  static const surface = Color(0xFF1E1E22);
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

  static const gradientRoute = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
// Active Task Screen
// ─────────────────────────────────────────────────────────────
class ActiveTaskScreen extends ConsumerStatefulWidget {
  const ActiveTaskScreen({super.key});
  @override
  ConsumerState<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends ConsumerState<ActiveTaskScreen> {
  int _currentStep = 1;

  final List<String> _stepLabels = [
    'Go to Donor',
    'Pick Up Food',
    'Go to NGO',
    'Confirm Delivery',
  ];

  // ── LOGIC FUNCTIONS (UNCHANGED) ────────────────────────────
  void _updateStatus(Donation task) async {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      if (_currentStep == 3) {
        await ref.read(donationRepositoryProvider).updateDonation(task.id, {
          'status': DonationStatus.pickedUp.name,
        });
      }
    } else {
      await ref.read(donationRepositoryProvider).updateDonation(task.id, {
        'status': DonationStatus.delivered.name,
      });
      _showCompletionCelebration();
    }
  }

  void _showCompletionCelebration() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.pink.withOpacity(0.1),
                  border: Border.all(color: _C.pink.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: _C.pink,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Excellent Work!',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You\'ve successfully delivered food to the NGO.\nYour impact has been recorded!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.pop();
                  context.go('/volunteer-home');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _C.gradientPink,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _C.pink.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80), // Added padding for floating navbar
            ],
          ),
        ),
      ),
    );
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

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamVolunteerTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _C.bg,
            body: Center(
              child: CircularProgressIndicator(color: _C.pink, strokeWidth: 2),
            ),
          );
        }

        final activeTasks =
            snapshot.data
                ?.where(
                  (d) =>
                      d.status == DonationStatus.pickedUp ||
                      (d.status == DonationStatus.accepted &&
                          d.assignedVolunteerId == userId),
                )
                .toList() ??
            [];

        if (activeTasks.isEmpty) {
          return Scaffold(
            backgroundColor: _C.bg,
            appBar: _buildAppBar(context),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: _C.green,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No active tasks.',
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('Great job!', style: TextStyle(color: _C.textMuted)),
                ],
              ),
            ),
          );
        }

        final task = activeTasks.first;

        // Derive current step from task status if not already advanced by user in this session
        // Status: accepted -> step 1/2, pickedUp -> step 3/4
        int currentStep = _currentStep;
        if (task.status == DonationStatus.pickedUp && currentStep < 3) {
          currentStep = 3;
          // Sync back to state to avoid visual jumps on next build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentStep < 3) setState(() => _currentStep = 3);
          });
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
            body: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildRouteOverview(task),
                          const SizedBox(height: 24),
                          _buildStepIndicator(),
                          const SizedBox(height: 32),
                          const _SectionLabel('Delivery Timeline'),
                          const SizedBox(height: 16),
                          _buildTimeline(),
                          const SizedBox(height: 32),
                          const _SectionLabel('Quick Contact'),
                          const SizedBox(height: 16),
                          _buildContactBar(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomAction(task),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: GestureDetector(
          onTap: () async {
            if (context.canPop()) {
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
        'Active Delivery',
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRouteOverview(Donation task) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: _C.gradientRoute,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.amber.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildRoutePoint(
              Icons.store_rounded,
              'Pickup',
              task.donorName,
              task.pickupAddress,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 2, height: 20, color: Colors.white24),
              ),
            ),
            FutureBuilder(
              future: task.acceptedByNgoId != null
                  ? ref
                        .read(userRepositoryProvider)
                        .getUser(task.acceptedByNgoId!)
                  : Future.value(null),
              builder: (context, snap) {
                final ngoName = snap.data?.name ?? 'Assigned NGO';
                final ngoAddress = snap.data?.address ?? 'NGO Address not set';
                return _buildRoutePoint(
                  Icons.location_on_rounded,
                  'Deliver to',
                  ngoName,
                  ngoAddress,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePoint(
    IconData icon,
    String label,
    String name,
    String address,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                address,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.pink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: _C.gradientPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Step $_currentStep',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CURRENT TASK',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _stepLabels[_currentStep - 1],
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: List.generate(4, (index) {
          final isCompleted = _currentStep > index + 1;
          final isCurrent = _currentStep == index + 1;
          final color = isCompleted
              ? _C.green
              : (isCurrent ? _C.pink : _C.textMuted);

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCurrent ? color : color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : (isCurrent
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: color.withOpacity(0.15),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepLabels[index],
                          style: TextStyle(
                            color: isCurrent
                                ? _C.textPrimary
                                : _C.textSecondary,
                            fontSize: 15,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Active now',
                              style: TextStyle(
                                color: _C.pink,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContactBar() {
    return Row(
      children: [
        _buildContactButton('Call Donor', Icons.phone_rounded, _C.amber),
        const SizedBox(width: 12),
        _buildContactButton('Call NGO', Icons.phone_rounded, _C.blue),
      ],
    );
  }

  Widget _buildContactButton(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(Donation task) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: GestureDetector(
        onTap: () => _updateStatus(task),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _C.gradientPink,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _C.pink.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _currentStep == 4
                  ? 'Confirm Final Delivery'
                  : _stepLabels[_currentStep - 1],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
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
          text.toUpperCase(),
          style: const TextStyle(
            color: _C.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }
}
