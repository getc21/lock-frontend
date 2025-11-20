import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        Get.offAllNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= AppSizes.tabletBreakpoint;
    
    // Observar estado de autenticación
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 450 : double.infinity,
              ),
              child: Card(
                elevation: 8,
                shadowColor: AppColors.shadow,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing48),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                          ),
                          child: const Icon(
                            Icons.spa,
                            color: AppColors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing24),
                        
                        // Title
                        const Text(
                          'BellezApp',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        const Text(
                          'Panel de Administración',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing48),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario o Correo electrónico',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su usuario o correo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.spacing20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.spacing32),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.buttonLarge,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text('Iniciar Sesión'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        
                        // Forgot Password
                        TextButton(
                          onPressed: () {
                            // TODO: Implementar recuperación de contraseña
                          },
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
