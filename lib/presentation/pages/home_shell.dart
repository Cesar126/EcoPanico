import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../../domain/entities/alert_entity.dart';
import '../viewmodels/alert_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dashboard_page.dart';
import 'map_page.dart';
import 'chat_page.dart';
import 'history_page.dart';
import 'profile_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    MapPage(),
    ChatPage(),
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertViewModelProvider);
    final hasActiveEmergency = alertState.activeAlerts.isNotEmpty;

    // Listen for new real-time alerts to display an in-app notification banner
    ref.listen<AlertState>(alertViewModelProvider, (previous, next) {
      final currentUser = ref.read(authViewModelProvider).user;
      if (currentUser == null) return;

      final prevIds = previous?.activeAlerts.map((a) => a.id).toSet() ?? {};
      final newAlerts = next.activeAlerts.where((a) => !prevIds.contains(a.id)).toList();

      for (final alert in newAlerts) {
        final age = DateTime.now().difference(alert.timestamp);
        if (alert.neighborId != currentUser.id && alert.status == 'activa' && age.inSeconds < 60) {
          _showInAppNotificationBanner(context, alert);
        }
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasActiveEmergency,
              backgroundColor: AppColors.alert,
              label: Text(alertState.activeAlerts.length.toString()),
              child: const Icon(Icons.map_outlined, color: AppColors.secondary),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasActiveEmergency,
              backgroundColor: AppColors.alert,
              label: Text(alertState.activeAlerts.length.toString()),
              child: const Icon(Icons.map, color: AppColors.primary),
            ),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.secondary),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.secondary),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showInAppNotificationBanner(BuildContext context, AlertEntity alert) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🚨 ¡ALERTA EN TU SECTOR! (${alert.type.toUpperCase().replaceAll('_', ' ')})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vecino: ${alert.neighborName} (Casa ${alert.neighborHouseNumber})',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  Text(
                    'Teléfono: ${alert.neighborPhone}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.alert,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'VER MAPA',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _currentIndex = 1);
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
