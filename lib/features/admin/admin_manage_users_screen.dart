import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

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

class AdminManageUsersScreen extends ConsumerStatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  ConsumerState<AdminManageUsersScreen> createState() =>
      _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState
    extends ConsumerState<AdminManageUsersScreen> {
  String _searchQuery = '';
  AppRole? _filterRole;

  // ── ORIGINAL MAPS — UNTOUCHED ──────────────────────────────
  static const _roleColors = {
    AppRole.donor: AppColors.primary,
    AppRole.ngo: AppColors.secondary,
    AppRole.volunteer: AppColors.pickedUp,
    AppRole.admin: AppColors.expired,
  };

  static const _roleIcons = {
    AppRole.donor: Icons.volunteer_activism,
    AppRole.ngo: Icons.corporate_fare,
    AppRole.volunteer: Icons.delivery_dining,
    AppRole.admin: Icons.admin_panel_settings,
  };

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
        if (context.canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () async {
              if (context.canPop()) {
                context.pop();
              } else {
                await handleHomeNavigation(context, ref);
              }
            },
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
            'Manage Users',
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
          _buildSearchBar(),
          _buildRoleFilter(),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: ref.watch(userRepositoryProvider).streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _C.pink,
                      strokeWidth: 2,
                    ),
                  );
                }

                var users = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  users = users
                      .where(
                        (u) =>
                            u.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            u.email.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();
                }

                if (_filterRole != null) {
                  users = users.where((u) => u.role == _filterRole).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: _C.textMuted,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No users found',
                          style: TextStyle(
                            color: _C.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) => _buildUserCard(users[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  // ── ALL ORIGINAL FUNCTIONS — UNTOUCHED ────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: _C.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _C.textMuted,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(bottom: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _filterChip('All', null),
            const SizedBox(width: 8),
            ...AppRole.values.map(
              (r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(r.name.toUpperCase(), r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, AppRole? role) {
    final isSelected = _filterRole == role;
    final Color color = role != null
        ? (_roleColors[role] ?? _C.textSecondary)
        : _C.pink;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
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

  Widget _buildUserCard(AppUser user) {
    final color = _roleColors[user.role] ?? _C.textSecondary;
    final icon = _roleIcons[user.role] ?? Icons.person_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? '(No name)' : user.name,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showUserActions(user),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: _C.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserActions(AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.name.isEmpty ? user.email : user.name,
              style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: const TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (_roleColors[user.role] ?? _C.textSecondary).withOpacity(
                  0.12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Role: ${user.role.name}',
                style: TextStyle(
                  fontSize: 11,
                  color: _roleColors[user.role] ?? _C.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 1,
              color: _C.border,
            ),
            const Text(
              'Change Role',
              style: TextStyle(
                color: _C.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppRole.values
                  .where((r) => r != user.role && r != AppRole.admin)
                  .map((r) {
                    final rColor = _roleColors[r] ?? _C.textSecondary;
                    final rIcon = _roleIcons[r] ?? Icons.person_outline;
                    return GestureDetector(
                      onTap: () async {
                        await ref
                            .read(userRepositoryProvider)
                            .saveUser(
                              AppUser(
                                id: user.id,
                                name: user.name,
                                email: user.email,
                                role: r,
                                phone: user.phone,
                                profileImageUrl: user.profileImageUrl,
                                createdAt: user.createdAt,
                                extraData: user.extraData,
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${user.name} role changed to ${r.name}',
                              ),
                              backgroundColor: _C.surfaceAlt,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: rColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: rColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rIcon, size: 14, color: rColor),
                            const SizedBox(width: 6),
                            Text(
                              r.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: rColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
