import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/alert_viewmodel.dart';
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
}
