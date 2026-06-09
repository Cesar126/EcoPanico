import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../domain/entities/user_entity.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminViewModelProvider);
    final adminNotifier = ref.read(adminViewModelProvider.notifier);

    // Alert errors
    ref.listen<AdminState>(adminViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
        adminNotifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Administración Los Ceibos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics cards grid
                  _buildStatsGrid(adminState),
                  const SizedBox(height: 24),

                  const Text(
                    'GESTIÓN DE VECINOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),

                  // Users list
                  _buildUsersList(context, adminState.users, adminNotifier),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid(AdminState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Vecinos Registrados', state.totalNeighbors.toString(), Icons.people_outline, AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Administradores', state.totalAdmins.toString(), Icons.admin_panel_settings_outlined, AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Vecinos Online', state.onlineCount.toString(), Icons.wifi_tethering, AppColors.success)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Usuarios', state.totalUsers.toString(), Icons.grid_view_outlined, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, List<UserEntity> users, AdminViewModel notifier) {
    if (users.isEmpty) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No hay usuarios registrados.', textAlign: TextAlign.center),
        ),
      );
    }

    // Group users by community
    final Map<String, List<UserEntity>> groupedUsers = {};
    for (final user in users) {
      final comm = user.community.isEmpty ? 'Sin Comunidad' : user.community;
      groupedUsers.putIfAbsent(comm, () => []).add(user);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groupedUsers.entries.map((entry) {
        final communityName = entry.key;
        final communityUsers = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ExpansionTile(
            title: Text(
              '$communityName (${communityUsers.length} vecinos)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            initiallyExpanded: true,
            shape: const Border(), // Remove default expansion tile borders
            collapsedShape: const Border(),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: communityUsers.map((user) {
              final isConnected = user.isConnected;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: AppColors.surface.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: user.photoUrl != null
                            ? (user.photoUrl!.startsWith('http')
                                ? NetworkImage(user.photoUrl!)
                                : FileImage(File(user.photoUrl!)) as ImageProvider)
                            : null,
                        child: user.photoUrl == null ? const Icon(Icons.person, color: AppColors.secondary) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.success : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    'Casa ${user.houseNumber} • Rol: ${user.role.toUpperCase()}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.secondary),
                    onSelected: (action) {
                      if (action == 'change_role') {
                        _showRoleDialog(context, user, notifier);
                      } else if (action == 'delete') {
                        _showDeleteConfirmDialog(context, user, notifier);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'change_role',
                        child: Row(
                          children: [
                            const Icon(Icons.security, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(user.role == 'admin' ? 'Cambiar a Vecino' : 'Cambiar a Admin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.alert),
                            const SizedBox(width: 8),
                            Text('Eliminar Usuario', style: TextStyle(color: AppColors.alert)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _showRoleDialog(BuildContext context, UserEntity user, AdminViewModel notifier) {
    final nextRole = user.role == 'admin' ? 'vecino' : 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cambiar Rol de Usuario?'),
        content: Text('Estás por cambiar el rol de "${user.fullName}" a ${nextRole.toUpperCase()}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.changeUserRole(user.id, nextRole);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('CAMBIAR'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserEntity user, AdminViewModel notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Usuario?', style: TextStyle(color: AppColors.alert)),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente a "${user.fullName}" de la comunidad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.removeUser(user.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert, foregroundColor: Colors.white),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
