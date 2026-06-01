import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/alert_viewmodel.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/entities/user_entity.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final alertState = ref.watch(alertViewModelProvider);
    final alertNotifier = ref.read(alertViewModelProvider.notifier);

    final currentUser = authState.user;
    final hasOwnAlert = alertState.currentOwnAlert != null;

    // Error listener
    ref.listen<AlertState>(alertViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
        alertNotifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eco Pánico Los Ceibos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Hola, ${currentUser?.fullName ?? "Vecino"}',
              style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Indicator of Admin Role
          if (currentUser?.isAdmin ?? false)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            _buildStatusHeader(alertState),
            const SizedBox(height: 24),

            // Own alert resolve controller (if user has active panic alert)
            if (hasOwnAlert) ...[
              _buildOwnAlertController(context, alertState.currentOwnAlert!, alertNotifier),
              const SizedBox(height: 24),
            ],

            // Giant Panic Buttons
            if (!hasOwnAlert) ...[
              const Text(
                'BOTONES DE EMERGENCIA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              _buildPanicButtons(context, alertState, alertNotifier),
              const SizedBox(height: 24),
            ],

            // Active alerts list
            const Text(
              'ALERTAS EN CURSO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            _buildActiveAlertsList(context, alertState, currentUser, alertNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(AlertState state) {
    final activeCount = state.activeAlerts.length;
    final isSafe = activeCount == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSafe ? AppColors.success.withOpacity(0.08) : AppColors.alert.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSafe ? AppColors.success.withOpacity(0.3) : AppColors.alert.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSafe ? AppColors.success : AppColors.alert,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSafe ? Icons.gpp_good_outlined : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe ? 'Sector Protegido' : 'Emergencia Comunitaria',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isSafe ? AppColors.success : AppColors.alert,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSafe
                      ? '${state.onlineNeighbors} vecinos alertas y conectados.'
                      : 'Hay $activeCount alerta(s) activa(s) en este momento.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnAlertController(BuildContext context, AlertEntity ownAlert, AlertViewModel notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.alert, Color(0xffb71c1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.alert.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'COMPARTIENDO TU UBICACIÓN...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white70),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Seguimiento Activo'),
                      content: const Text(
                        'Tu ubicación GPS se está actualizando cada 5 segundos en el mapa de todos los vecinos para facilitar tu rescate. Mantente a salvo.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO')),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ownAlert.type == 'robo'
                ? '🚨 ROBO EN CURSO REPORTADO'
                : ownAlert.type == 'sospechoso'
                    ? '⚠️ SOSPECHOSO REPORTADO'
                    : '🚨 EMERGENCIA ACTIVADA POR MOVIMIENTO',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Todos los vecinos han recibido una notificación de tu ubicación.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => notifier.resolveAlert(ownAlert.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: const Text(
              'RESOLVER / ESTOY A SALVO',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButtons(BuildContext context, AlertState state, AlertViewModel notifier) {
    return Row(
      children: [
        // Button 1: Reportar Sospechoso
        Expanded(
          child: GestureDetector(
            onTap: () => _confirmAlertTrigger(context, 'sospechoso', 'medium', notifier),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.warning, Color(0xffe65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.visibility_outlined, color: Colors.white, size: 26),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportar\nSospechoso',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Alerta preventiva',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Button 2: Robo en Curso
        Expanded(
          child: GestureDetector(
            onTap: () => _confirmAlertTrigger(context, 'robo', 'critical', notifier),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.alert, Color(0xffb71c1c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alert.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 26),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Robo en\nCurso',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ALERTA CRÍTICA',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmAlertTrigger(BuildContext context, String type, String level, AlertViewModel notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == 'robo' ? '🚨 ¿Confirmar Robo en Curso?' : '⚠️ ¿Confirmar Reporte Sospechoso?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          type == 'robo'
              ? 'Se emitirá una ALERTA CRÍTICA a todos los vecinos. Tu ubicación en tiempo real se compartirá inmediatamente.'
              : 'Se emitirá un reporte de actividad sospechosa a la comunidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.triggerEmergencyAlert(type: type, level: level);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'robo' ? AppColors.alert : AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsList(BuildContext context, AlertState state, UserEntity? currentUser, AlertViewModel notifier) {
    if (state.activeAlerts.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
              SizedBox(height: 12),
              Text(
                'No hay alertas activas en el sector.',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Todo está tranquilo en Los Ceibos.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.activeAlerts.length,
      itemBuilder: (context, index) {
        final alert = state.activeAlerts[index];
        final isCritical = alert.isCritical;
        final timeString = DateFormat('HH:mm').format(alert.timestamp);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCritical ? AppColors.alert : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alert.type == 'robo'
                              ? 'ROBO EN CURSO'
                              : alert.type == 'sospechoso'
                                  ? 'ACTIVIDAD SOSPECHOSA'
                                  : 'EMERGENCIA MOVIMIENTO',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isCritical ? AppColors.alert : AppColors.warning,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeString,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vecino: ${alert.neighborName} (${alert.neighborHouseNumber})',
                        style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicación: ${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Admin controls or Neighbor respond option
                    if (currentUser?.isAdmin ?? false) ...[
                      TextButton(
                        onPressed: () => notifier.resolveAlert(alert.id),
                        style: TextButton.styleFrom(foregroundColor: AppColors.success),
                        child: const Text('RESOLVER', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (alert.status == 'activa')
                      ElevatedButton(
                        onPressed: () => notifier.attendAlert(alert.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('ATENDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EN ATENCIÓN',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
