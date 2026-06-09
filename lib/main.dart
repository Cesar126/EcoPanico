import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/config/app_colors.dart';
import 'core/config/app_config.dart';
import 'presentation/providers/repository_providers.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/email_verification_page.dart';
import 'presentation/pages/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize SharedPreferences to load mock configuration
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('⚠️ Error al inicializar SharedPreferences: $e');
  }

  // Try to initialize Firebase safely
  try {
    // If google-services.json / GoogleService-Info.plist are missing,
    // this will throw an exception, which we catch to fallback to Mock Mode.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.firebaseInitialized = true;
    
    // If successfully initialized, default mock mode to false unless user explicitly turned it on.
    final savedMock = prefs?.getBool(AppConfig.keyUseMock);
    AppConfig.useMockData = savedMock ?? false;
    debugPrint('🎉 Firebase inicializado exitosamente. Modo Live activo: ${!AppConfig.useMockData}');
  } catch (e) {
    AppConfig.firebaseInitialized = false;
    debugPrint('⚠️ Error al inicializar Firebase: $e');
    debugPrint('⚙️ Configuración de Firebase no encontrada. Iniciando en Modo Demo/Mock.');
    AppConfig.useMockData = true;
  }

  runApp(
    // ProviderScope is mandatory for Riverpod state management
    const ProviderScope(
      child: EcoPanicoApp(),
    ),
  );
}

class EcoPanicoApp extends ConsumerWidget {
  const EcoPanicoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch mock mode switch to reload state if developer toggles it in UI
    ref.watch(mockModeStateProvider);

    return MaterialApp(
      title: 'Eco Pánico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.alert,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
      ),
      home: const AuthSwitcher(),
    );
  }
}

class AuthSwitcher extends ConsumerStatefulWidget {
  const AuthSwitcher({super.key});

  @override
  ConsumerState<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends ConsumerState<AuthSwitcher> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Keep splash animation visible for 2 seconds to wow the user
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashPage();
    }

    final authState = ref.watch(authViewModelProvider);

    if (authState.isLoading) {
      return const SplashPage();
    }

    if (authState.user == null) {
      return const LoginPage();
    }

    if (AppConfig.requireEmailVerification && !authState.isEmailVerified) {
      return const EmailVerificationPage();
    }

    // Fully authenticated and verified user
    return const HomeShell();
  }
}
