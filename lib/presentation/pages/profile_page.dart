import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/repository_providers.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/alert_viewmodel.dart';
import 'admin_dashboard_page.dart';

// Riverpod 3 Notifier definitions for settings
class VibrationSettingNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle(bool val) => state = val;
}

class SoundSettingNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle(bool val) => state = val;
}

class ShakeSettingNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle(bool val) => state = val;
}

final vibrationSettingProvider = NotifierProvider<VibrationSettingNotifier, bool>(() {
  return VibrationSettingNotifier();
});

final soundSettingProvider = NotifierProvider<SoundSettingNotifier, bool>(() {
  return SoundSettingNotifier();
});

final shakeSettingProvider = NotifierProvider<ShakeSettingNotifier, bool>(() {
  return ShakeSettingNotifier();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final alertState = ref.watch(alertViewModelProvider);
    final isMock = ref.watch(mockModeStateProvider);
    
    final vibration = ref.watch(vibrationSettingProvider);
    final sound = ref.watch(soundSettingProvider);
    final shake = ref.watch(shakeSettingProvider);

    final currentUser = authState.user;

    final ownAlertsCount = alertState.alertsHistory
        .where((a) => a.neighborId == currentUser?.id)
        .length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(currentUser, ownAlertsCount),
            const SizedBox(height: 24),

            if (currentUser?.isAdmin ?? false) ...[
              _buildAdminEntry(context),
              const SizedBox(height: 24),
            ],

            const Text(
              'CONFIGURACIÓN DE ALERTA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            _buildSettingsList(context, ref, vibration, sound, shake, isMock),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                ref.read(authViewModelProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alert,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserEntity? user, int alertsCount) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surface,
              backgroundImage: user?.photoUrl != null
                  ? (user!.photoUrl!.startsWith('http')
                      ? NetworkImage(user.photoUrl!)
                      : FileImage(File(user.photoUrl!)) as ImageProvider)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.secondary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'Vecino Los Ceibos',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${user?.community ?? "Los Ceibos"} • Casa ${user?.houseNumber ?? "N/A"} • ${user?.phone ?? "Sin teléfono"}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user?.address ?? 'Pasaje Los Ceibos',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Alertas Emitidas', alertsCount.toString(), AppColors.alert),
                Container(width: 1, height: 40, color: AppColors.surface),
                _buildStatItem('Estado Cuenta', 'Verificado', AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAdminEntry(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
        ),
        title: const Text(
          'Panel de Administración',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        subtitle: const Text('Gestionar vecinos, roles y parámetros del sistema.'),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        },
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, bool vibration, bool sound, bool shake, bool isMock) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              value: vibration,
              activeThumbColor: AppColors.primary,
              title: const Text('Vibración en Emergencias', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('El teléfono vibrará repetidamente al recibir o emitir alertas.', style: TextStyle(fontSize: 11)),
              onChanged: (val) {
                ref.read(vibrationSettingProvider.notifier).toggle(val);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              value: sound,
              activeThumbColor: AppColors.primary,
              title: const Text('Sonido de Alarma', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Reproducir un tono de sirena para alertarte.', style: TextStyle(fontSize: 11)),
              onChanged: (val) {
                ref.read(soundSettingProvider.notifier).toggle(val);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              value: shake,
              activeThumbColor: AppColors.primary,
              title: const Text('Detección por Agitación (Acelerómetro)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Agitar 3 veces consecutivas para emitir alerta médica/policial automática.', style: TextStyle(fontSize: 11)),
              onChanged: (val) {
                ref.read(shakeSettingProvider.notifier).toggle(val);
                ref.read(alertViewModelProvider.notifier).setShakeEnabled(val);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              value: isMock,
              activeThumbColor: AppColors.success,
              title: const Text('Modo Demo / Datos de Simulación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Permite simular movimiento GPS, chat y vecinos online.', style: TextStyle(fontSize: 11)),
              onChanged: (val) {
                if (!val && !AppConfig.firebaseInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ No se puede activar el servidor porque Firebase no se inicializó correctamente.'),
                      backgroundColor: AppColors.alert,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                ref.read(mockModeStateProvider.notifier).toggle(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
