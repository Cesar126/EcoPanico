import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authViewModelProvider.notifier).recoverPassword(_emailController.text.trim());
      if (mounted && ref.read(authViewModelProvider).errorMessage == null) {
        setState(() => _success = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Recuperar Acceso', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: _success ? _buildSuccessView() : _buildFormView(authState),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingresa tu correo registrado y te enviaremos las instrucciones para restablecer tu contraseña.',
            style: TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: authState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 54),
              elevation: 2,
            ),
            child: authState.isLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : const Text(
                    'ENVIAR CORREO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Correo Enviado!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Revisa tu bandeja de entrada. Te hemos enviado las instrucciones para cambiar tu contraseña.',
          style: TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 54),
          ),
          child: const Text('VOLVER AL INICIO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
