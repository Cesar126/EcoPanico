import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    await ref.read(authViewModelProvider.notifier).checkVerification();
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verifica tu cuenta',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textLight,
                    ),
                    children: [
                      const TextSpan(text: 'Hemos enviado un enlace de confirmación al correo de registro de '),
                      TextSpan(
                        text: authState.user?.fullName ?? 'vecino',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const TextSpan(text: '.\n\nPor favor revisa tu bandeja de entrada o spam y pulsa el enlace.'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_checking)
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))
                else ...[
                  ElevatedButton.icon(
                    onPressed: _checkStatus,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('YA VERIFIQUE MI CORREO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Simulated resend
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace enviado nuevamente.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_outlined, color: AppColors.primary),
                    label: const Text('REENVIAR ENLACE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () {
                    ref.read(authViewModelProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.exit_to_app, color: AppColors.alert),
                  label: const Text('SALIR / INICIAR CON OTRO CORREO', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
