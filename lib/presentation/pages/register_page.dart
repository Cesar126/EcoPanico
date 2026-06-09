import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customCommunityController = TextEditingController();

  String? _selectedPhotoUrl;
  String _selectedCommunity = 'Los Ceibos (Sector Central)';
  bool _showCustomCommunityInput = false;

  final List<String> _communities = [
    'Los Ceibos (Sector Central)',
    'Los Ceibos (Sector Polideportivo)',
    'Los Ceibos (Sector Avenida)',
    'Yacucalle',
    'Caranqui',
    'La Florida',
    'La Victoria',
    'El Retorno',
    'Otro / Personalizado',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _houseNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _customCommunityController.dispose();
    super.dispose();
  }

  void _selectMockProfilePicture() {
    // Show a dialog letting the user pick from a set of beautiful avatar URLs (simulating image picker)
    final avatars = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elige una foto de perfil', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPhotoUrl = avatars[index]);
                    Navigator.pop(context);
                  },
                  child: ClipOval(
                    child: Image.network(avatars[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final String finalCommunity = _selectedCommunity == 'Otro / Personalizado'
          ? _customCommunityController.text.trim()
          : _selectedCommunity;

      ref.read(authViewModelProvider.notifier).register(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            houseNumber: _houseNumberController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            photoUrl: _selectedPhotoUrl,
            community: finalCommunity.isEmpty ? 'Los Ceibos' : finalCommunity,
          );
      
      // Navigate back on successful registration (the auth flow switch handles routing)
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Registro de Vecinos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para registrarte en la red comunitaria de Los Ceibos.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Picture Picker Trigger
                Center(
                  child: GestureDetector(
                    onTap: _selectMockProfilePicture,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedPhotoUrl != null ? NetworkImage(_selectedPhotoUrl!) : null,
                          child: _selectedPhotoUrl == null
                              ? const Icon(Icons.person_outline, size: 54, color: AppColors.secondary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Full name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Nombre Completo', Icons.person_outline),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Teléfono Celular', Icons.phone_android_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu número de teléfono' : null,
                ),
                const SizedBox(height: 16),
                // Address
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Dirección de Residencia', Icons.home_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu dirección' : null,
                ),
                const SizedBox(height: 16),
                // House Number
                TextFormField(
                  controller: _houseNumberController,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Número de Casa o Lote', Icons.numbers_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el número de tu vivienda' : null,
                ),
                const SizedBox(height: 16),
                // Comunidad / Barrio / Sector Selector
                DropdownButtonFormField<String>(
                  value: _selectedCommunity,
                  style: const TextStyle(color: AppColors.textDark),
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Comunidad / Barrio / Sector', Icons.group_outlined),
                  items: _communities.map((comm) {
                    return DropdownMenuItem<String>(
                      value: comm,
                      child: Text(comm),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCommunity = value ?? 'Los Ceibos (Sector Central)';
                      _showCustomCommunityInput = _selectedCommunity == 'Otro / Personalizado';
                    });
                  },
                ),
                if (_showCustomCommunityInput) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customCommunityController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _inputDecoration('Especifica tu Comunidad / Barrio', Icons.edit_location_alt_outlined),
                    validator: (value) {
                      if (_showCustomCommunityInput && (value == null || value.trim().isEmpty)) {
                        return 'Ingresa tu comunidad o barrio';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDecoration('Contraseña', Icons.lock_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Submit button
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
                          'REGISTRARSE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.secondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
    );
  }
}
