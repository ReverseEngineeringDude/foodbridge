import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

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

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientActive = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
// Nav Item Data
// ─────────────────────────────────────────────────────────────
class VolunteerHomeScreen extends ConsumerWidget {
  const VolunteerHomeScreen({super.key});

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
        // extendBody lets the scroll content flow UNDER the nav bar
        extendBody: true,
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
                _ActiveTaskCard(),
                const SizedBox(height: 24),
                _StatsBanner(),
                const SizedBox(height: 32),
                const _SectionLabel('Available Deliveries'),
                const SizedBox(height: 16),
                _AvailableTasksList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────
// Header  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final name =
        user?.displayName ?? user?.email?.split('@').first ?? 'Volunteer';

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
                  Icons.delivery_dining,
                  color: _C.pink,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ready to help?',
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
// Active Task Card  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _ActiveTaskCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamVolunteerTasks(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final activeTasks = snapshot.data!
            .where(
              (d) =>
                  d.status == DonationStatus.pickedUp ||
                  (d.status == DonationStatus.accepted &&
                      d.assignedVolunteerId == userId),
            )
            .toList();

        if (activeTasks.isEmpty) return const SizedBox.shrink();
        final task = activeTasks.first;

        return FadeInRight(
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: () => context.go('/active-task'),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: _C.gradientActive,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _C.amber.withOpacity(0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ACTIVE TASK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pickup from ${task.donorName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Deliver to: NGO',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _GradientDetailChip(
                        icon: Icons.restaurant_rounded,
                        label: task.foodName,
                      ),
                      const SizedBox(width: 12),
                      _GradientDetailChip(
                        icon: Icons.people_outline_rounded,
                        label: '${task.servings} servings',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GradientDetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Banner  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _StatsBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamVolunteerTasks(userId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final tasksDone = tasks
            .where((d) => d.status == DonationStatus.delivered)
            .length;

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final thisWeek = tasks
            .where(
              (d) =>
                  d.status == DonationStatus.delivered &&
                  d.createdAt.isAfter(weekStart),
            )
            .length;

        final deliveredDates =
            tasks
                .where((d) => d.status == DonationStatus.delivered)
                .map(
                  (d) => DateTime(
                    d.createdAt.year,
                    d.createdAt.month,
                    d.createdAt.day,
                  ),
                )
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));

        int streak = 0;
        DateTime check = DateTime(now.year, now.month, now.day);
        for (final date in deliveredDates) {
          if (date == check ||
              date == check.subtract(const Duration(days: 1))) {
            streak++;
            check = date.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

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
                  value: tasksDone.toString(),
                  label: 'Tasks Done',
                  color: _C.pink,
                  icon: Icons.check_circle_outline_rounded,
                ),
                _StatDivider(),
                _StatCell(
                  value: thisWeek.toString(),
                  label: 'This Week',
                  color: _C.blue,
                  icon: Icons.calendar_today_outlined,
                ),
                _StatDivider(),
                _StatCell(
                  value: streak.toString(),
                  label: 'Day Streak',
                  color: _C.amber,
                  icon: Icons.local_fire_department_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: _C.border);
}

// ─────────────────────────────────────────────────────────────
// Section Label  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
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
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Available Tasks List  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _AvailableTasksList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamDonationsByStatus(DonationStatus.accepted),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _C.pink, strokeWidth: 2),
            ),
          );
        }

        final tasks = snapshot.data!
            .where((d) => d.assignedVolunteerId == null)
            .toList();

        if (tasks.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: const [
                Icon(Icons.inbox_outlined, color: _C.textMuted, size: 40),
                SizedBox(height: 12),
                Text(
                  'No deliveries available',
                  style: TextStyle(
                    color: _C.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check back soon for new tasks.',
                  style: TextStyle(color: _C.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Column(
          children: tasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TaskCard(task: task),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Task Card  (UNCHANGED)
// ─────────────────────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  final Donation task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: _C.pink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${task.donorName}',
                        style: const TextStyle(
                          color: _C.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FutureBuilder(
                        future: task.acceptedByNgoId != null
                            ? ref
                                  .read(userRepositoryProvider)
                                  .getUser(task.acceptedByNgoId!)
                            : Future.value(null),
                        builder: (context, snap) {
                          final ngoName = snap.data?.name ?? 'Assigned NGO';
                          return Text(
                            'To: $ngoName',
                            style: const TextStyle(
                              color: _C.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      if (task.pickupAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.pickupAddress,
                          style: const TextStyle(
                            color: _C.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (task.foodName.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Tag(label: task.foodName, color: _C.green),
                  _Tag(label: '${task.servings} servings', color: _C.amber),
                ],
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final user = ref.read(authServiceProvider).currentUser;
                if (user != null) {
                  await ref.read(donationRepositoryProvider).updateDonation(
                    task.id,
                    {'assignedVolunteerId': user.uid},
                  );
                  if (context.mounted) context.go('/active-task');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _C.gradientPink,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _C.pink.withOpacity(0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Accept & Start Delivery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
