import 'package:flutter/material.dart';
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

// --- Theme Colors for Profile ---
const _kBgDark = Color(0xFF141416);
const _kCardDark = Color(0xFF1E1E22);
const _kCardLighter = Color(0xFF252529);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF9999AA);
const _kGradientStart = Color(0xFFE040A0);
const _kGradientEnd = Color(0xFF7B2FBE);
const _kAccentOrange = Color(0xFFF5A623);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authServiceProvider).currentUser;

    if (authUser == null) {
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
          backgroundColor: _kBgDark,
          body: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: _kTextSecondary),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view your profile',
                style: TextStyle(color: _kTextSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kCardLighter,
                  foregroundColor: _kTextPrimary,
                ),
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
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
        backgroundColor: _kBgDark,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(authUser: authUser),
          ),
          SliverToBoxAdapter(
            child: _ProfileStats(userId: authUser.uid),
          ),
          SliverToBoxAdapter(
            child: _ActionButtonsRow(userId: authUser.uid),
          ),
          SliverToBoxAdapter(
            child: const _QuickIconsRow(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDesign.padding, 24, AppDesign.padding, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileMenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: _kAccentOrange,
                      title: 'Edit Profile',
                      subtitle: 'Update your name & phone',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      iconColor: _kGradientStart,
                      title: 'Notifications',
                      subtitle: 'Push, email & preferences',
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileMenuSection(
                  title: 'Support',
                  items: [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Help & Support',
                      subtitle: 'FAQs, contact us, report issue',
                      onTap: () => context.push('/support'),
                    ),
                    _MenuItem(
                      icon: Icons.verified_user_outlined,
                      iconColor: Colors.tealAccent,
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your data',
                      onTap: () => context.push('/privacy-policy'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const _LogoutButton(),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _ProfileHeader extends ConsumerWidget {
  final dynamic authUser;

  const _ProfileHeader({required this.authUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppUser?>(
      stream: ref.watch(userRepositoryProvider).streamUser(authUser.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final name = appUser?.name ?? authUser.displayName ?? authUser.email?.split('@').first ?? 'User';
        final email = authUser.email ?? '';
        final role = appUser?.role ?? AppRole.donor;
        final photoUrl = authUser.photoURL ?? appUser?.profileImageUrl;

        return FadeInDown(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Cover Banner
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kGradientStart, _kGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      color: Colors.black.withAlpha(80), // Dark overlay
                    ),
                  ),
                  // Avatar intersecting bottom exactly
                  Positioned(
                    bottom: -60,
                    child: Container(
                      width: 126,
                      height: 126,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_kGradientStart, _kGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0), // 4px gradient ring border
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kBgDark,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: _kBgDark,
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Icon(Icons.person, size: 60, color: _kTextSecondary),
                                      errorWidget: (context, url, err) => const Icon(Icons.person, size: 60, color: _kTextSecondary),
                                    ),
                                  )
                                : const Icon(Icons.person_rounded, size: 60, color: _kTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70), // Spacer for overlapping avatar
              Text(
                name,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: _kTextSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              _RoleBadge(role: role),
            ],
          ),
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AppRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kCardLighter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: const TextStyle(
          color: _kTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileStats extends ConsumerWidget {
  final String userId;

  const _ProfileStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine role (you could pass role directly if preferred)
    return StreamBuilder<AppUser?>(
      stream: ref.watch(userRepositoryProvider).streamUser(userId),
      builder: (context, userSnapshot) {
        final role = userSnapshot.data?.role ?? AppRole.donor;

        if (role == AppRole.donor) {
          return _DonorStats(userId: userId);
        }
        if (role == AppRole.volunteer) {
          return _VolunteerStats(userId: userId);
        }
        if (role == AppRole.ngo) {
          return _NgoStats(userId: userId);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DonorStats extends ConsumerWidget {
  final String userId;
  const _DonorStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamDonorDonations(userId),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final total = donations.length;
        final kgSaved = donations.fold<double>(0, (sum, d) => sum + d.quantityKg);
        final peopleFed = donations.fold<int>(0, (sum, d) => sum + d.servings);

        return FadeInUp(
          delay: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _kCardDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   Expanded(child: _StatItem(value: total.toString(), label: 'Donations')),
                  _Divider(),
                  Expanded(child: _StatItem(value: '${kgSaved.toStringAsFixed(0)}kg', label: 'Food Saved')),
                  _Divider(),
                  Expanded(child: _StatItem(value: peopleFed.toString(), label: 'People Fed')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolunteerStats extends ConsumerWidget {
  final String userId;
  const _VolunteerStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamVolunteerTasks(userId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final completed = tasks.where((d) => d.status == DonationStatus.delivered).length;
        final inProgress = tasks.where((d) => d.status == DonationStatus.pickedUp).length;

        return FadeInUp(
          delay: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _kCardDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _StatItem(value: tasks.length.toString(), label: 'Total Tasks')),
                  _Divider(),
                  Expanded(child: _StatItem(value: inProgress.toString(), label: 'In Progress')),
                  _Divider(),
                  Expanded(child: _StatItem(value: completed.toString(), label: 'Deliveries')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NgoStats extends ConsumerWidget {
  final String userId;
  const _NgoStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Donation>>(
      stream: ref.watch(donationRepositoryProvider).streamNgoAcceptedDonations(userId),
      builder: (context, snapshot) {
        final myAccepted = snapshot.data ?? [];
        final delivered = myAccepted.where((d) => d.status == DonationStatus.delivered).length;
        final inProgress = myAccepted.where((d) =>
            d.status == DonationStatus.accepted || d.status == DonationStatus.pickedUp).length;

        return FadeInUp(
          delay: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _kCardDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _StatItem(value: myAccepted.length.toString(), label: 'Accepted')),
                  _Divider(),
                  Expanded(child: _StatItem(value: inProgress.toString(), label: 'In Progress')),
                  _Divider(),
                  Expanded(child: _StatItem(value: delivered.toString(), label: 'Delivered')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: _kCardLighter,
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final String userId;
  const _ActionButtonsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/history'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTextPrimary,
                  side: const BorderSide(color: _kCardLighter, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('View History', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kGradientStart, _kGradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () => context.push('/donate'), // Changed to real path
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('New Donation', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
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
    return FadeInUp(
      delay: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuickIconBtn(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => context.push('/edit-profile'),
            ),
            const SizedBox(width: 32),
            _QuickIconBtn(
              icon: Icons.notifications_none_rounded,
              label: 'Alerts',
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: 32),
            _QuickIconBtn(
              icon: Icons.local_activity_outlined,
              label: 'Activity',
              onTap: () => context.push('/activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickIconBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _kCardLighter,
              shape: BoxShape.circle,
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_kGradientStart, _kGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: _kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _ProfileMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _kTextSecondary,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _kCardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildMenuItem(context, item),
                    if (index < items.length - 1)
                      Divider(height: 1, indent: 64, endIndent: 20, color: _kCardLighter),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _kTextPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kTextSecondary, size: 20),
            ],
          ),
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

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      delay: const Duration(milliseconds: 350),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLogout(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _kCardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withAlpha(40)),
            ),
            child: const Text(
              'Log Out',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out', style: TextStyle(color: _kTextPrimary)),
        content: const Text(
          'Are you sure you want to log out of FoodBridge?',
          style: TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to log out: $e')),
                  );
                }
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
