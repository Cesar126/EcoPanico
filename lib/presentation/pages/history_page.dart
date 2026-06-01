import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/alert_viewmodel.dart';
import '../../domain/entities/alert_entity.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final currentUser = authState.user;

    final allAlerts = alertState.alertsHistory;
    final activeAlerts = allAlerts.where((a) => a.status == 'activa' || a.status == 'en_atencion').toList();
    final resolvedAlerts = allAlerts.where((a) => a.status == 'resuelta').toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Historial de Alertas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Activas (${activeAlerts.length})'),
            Tab(text: 'Resueltas (${resolvedAlerts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsList(activeAlerts, currentUser),
          _buildAlertsList(resolvedAlerts, currentUser),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<AlertEntity> alerts, var currentUser) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.secondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'No hay registros en esta sección.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final dateString = DateFormat('dd/MM/yyyy • HH:mm').format(alert.timestamp);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: alert.status == 'activa'
                            ? AppColors.alert.withOpacity(0.1)
                            : alert.status == 'en_atencion'
                                ? AppColors.warning.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert.status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: alert.status == 'activa'
                              ? AppColors.alert
                              : alert.status == 'en_atencion'
                                  ? AppColors.warning
                                  : AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  alert.type == 'robo'
                      ? '🚨 ROBO EN CURSO'
                      : alert.type == 'sospechoso'
                          ? '⚠️ ACTIVIDAD SOSPECHOSA'
                          : '🚨 EMERGENCIA POR MOVIMIENTO',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vecino: ${alert.neighborName}\nDirección: Casa ${alert.neighborHouseNumber}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.4),
                ),
                if (alert.status == 'resuelta' && alert.resolvedBy != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Resuelta por: ${alert.resolvedBy}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Admin Actions or response action
                if (alert.status != 'resuelta' && (currentUser?.isAdmin ?? false)) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref.read(alertViewModelProvider.notifier).resolveAlert(alert.id);
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.success),
                        child: const Text('RESOLVER ALERTA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
