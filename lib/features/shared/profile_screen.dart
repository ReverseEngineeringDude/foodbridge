import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
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

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authServiceProvider).currentUser;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    if (authUser == null) {
      return _buildLoginRequired(context, ref);
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeroHeader(authUser: authUser)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _ProfileStats(userId: authUser.uid),
              ),
            ),
            SliverToBoxAdapter(child: _ActionButtonsRow(userId: authUser.uid)),
            SliverToBoxAdapter(child: const _QuickIconsRow()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 16),
                  _buildMenuContainer([
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: _C.amber,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      iconColor: _C.pink,
                      title: 'Notifications',
                      subtitle: 'Alerts and push settings',
                      onTap: () => context.push('/notifications'),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Support & Legal'),
                  const SizedBox(height: 16),
                  _buildMenuContainer([
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: _C.blue,
                      title: 'Help Center',
                      subtitle: 'FAQs and direct contact',
                      onTap: () => context.push('/support'),
                    ),
                    _MenuItem(
                      icon: Icons.verified_user_outlined,
                      iconColor: _C.green,
                      title: 'Privacy Policy',
                      subtitle: 'Data handling and terms',
                      onTap: () => context.push('/privacy-policy'),
                    ),
                  ]),
                  const SizedBox(height: 48),
                  const _LogoutButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeIn(
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _C.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              _buildMenuTile(entry.value),
              if (!isLast) Divider(height: 1, color: _C.border, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle ?? '',
                      style: const TextStyle(color: _C.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _C.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: FadeInDown(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _C.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  size: 48,
                  color: _C.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Log in to continue',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'View your impact and manage your account.',
                style: TextStyle(color: _C.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: _C.gradientPink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Hero Header
// ─────────────────────────────────────────────────────────────
class _ProfileHeroHeader extends ConsumerWidget {
  final dynamic authUser;
  const _ProfileHeroHeader({required this.authUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppUser?>(
      stream: ref.watch(userRepositoryProvider).streamUser(authUser.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final name = appUser?.name ?? authUser.displayName ?? 'User';
        final role = appUser?.role ?? AppRole.donor;
        final photoData = appUser?.profileImageUrl ?? authUser.photoURL;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Background Glow
            Positioned(
              top: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_C.pink.withOpacity(0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                // Large Visible Avatar
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _C.pink.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: _C.gradientPink,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: _C.bg,
                            child: _AvatarContent(photoData: photoData),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.bg, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                        child: Icon(
                          _getRoleIcon(role),
                          color: _C.pink,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.border),
                  ),
                  child: Text(
                    role.name.toUpperCase(),
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        );
      },
    );
  }

  IconData _getRoleIcon(AppRole role) {
    if (role == AppRole.volunteer) return Icons.delivery_dining_rounded;
    if (role == AppRole.ngo) return Icons.corporate_fare_rounded;
    return Icons.favorite_rounded;
  }
}

class _AvatarContent extends StatelessWidget {
  final String? photoData;
  const _AvatarContent({this.photoData});

  @override
  Widget build(BuildContext context) {
    if (photoData == null || photoData!.isEmpty) {
      return const Icon(Icons.person_rounded, size: 70, color: _C.textMuted);
    }

    if (photoData!.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoData!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, err) =>
              const Icon(Icons.person_rounded, size: 70, color: _C.textMuted),
        ),
      );
    }

    try {
      final cleanBase64 = photoData!.contains(',')
          ? photoData!.split(',').last
          : photoData!;
      return ClipOval(
        child: Image.memory(
          base64Decode(cleanBase64.trim().replaceAll(RegExp(r'\s+'), '')),
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person_rounded, size: 70, color: _C.textMuted),
        ),
      );
    } catch (_) {
      return const Icon(Icons.person_rounded, size: 70, color: _C.textMuted);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Frosted Stats
// ─────────────────────────────────────────────────────────────
class _ProfileStats extends ConsumerWidget {
  final String userId;
  const _ProfileStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppUser?>(
      stream: ref.watch(userRepositoryProvider).streamUser(userId),
      builder: (context, userSnapshot) {
        final role = userSnapshot.data?.role ?? AppRole.donor;

        return FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _C.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _buildRoleStats(role, ref),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleStats(AppRole role, WidgetRef ref) {
    if (role == AppRole.volunteer) {
      return StreamBuilder<List<Donation>>(
        stream: ref
            .watch(donationRepositoryProvider)
            .streamVolunteerTasks(userId),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final completed = tasks
              .where((d) => d.status == DonationStatus.delivered)
              .length;
          return _StatsRow(
            items: [
              _StatItem(value: tasks.length.toString(), label: 'Tasks'),
              _StatItem(
                value: completed.toString(),
                label: 'Delivered',
                color: _C.green,
              ),
            ],
          );
        },
      );
    }
    // Default Donor View
    return StreamBuilder<List<Donation>>(
      stream: ref
          .watch(donationRepositoryProvider)
          .streamDonorDonations(userId),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final peopleFed = donations.fold<int>(0, (sum, d) => sum + d.servings);
        return _StatsRow(
          items: [
            _StatItem(value: donations.length.toString(), label: 'Shared'),
            _StatItem(
              value: peopleFed.toString(),
              label: 'Fed',
              color: _C.amber,
            ),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(items.length, (index) {
        return Row(
          children: [
            items[index],
            if (index < items.length - 1)
              Container(
                width: 1,
                height: 30,
                color: _C.border,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
          ],
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _StatItem({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? _C.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _C.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Other Components (Unified)
// ─────────────────────────────────────────────────────────────

class _ActionButtonsRow extends StatelessWidget {
  final String userId;
  const _ActionButtonsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _GlassActionButton(
                label: 'History',
                icon: Icons.history_rounded,
                onTap: () => context.push('/history'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _GlassActionButton(
                label: 'Donate',
                icon: Icons.add_circle_rounded,
                gradient: _C.gradientPink,
                onTap: () => context.push('/donate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final LinearGradient? gradient;

  const _GlassActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? _C.surface : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient == null ? _C.border : Colors.white.withOpacity(0.1),
          ),
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: _C.pink.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickIconsRow extends StatelessWidget {
  const _QuickIconsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // _QuickIconBtn(
          //   icon: Icons.qr_code_rounded,
          //   label: 'My QR',
          //   onTap: () {},
          // ),
          // const SizedBox(width: 40),
          // _QuickIconBtn(
          //   icon: Icons.stars_rounded,
          //   label: 'Badges',
          //   onTap: () {},
          // ),
          // const SizedBox(width: 40),
          // _QuickIconBtn(
          //   icon: Icons.settings_rounded,
          //   label: 'Settings',
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }
}

class _QuickIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickIconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: Icon(icon, color: _C.textSecondary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleLogout(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: const Text(
          'Sign Out',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: _C.border),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: _C.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your session?',
            style: TextStyle(color: _C.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _C.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
