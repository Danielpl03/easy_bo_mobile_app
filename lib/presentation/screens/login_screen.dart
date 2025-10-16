import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo y título
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Easy BO',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Inicia sesión en tu cuenta'
                          : 'Crea tu cuenta',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Campo de nombre de usuario (siempre visible)
                TextFormField(
                  controller: _nombreController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre de usuario';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campos adicionales solo para registro
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Por favor ingresa un email válido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Botón de acción
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          authProvider.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                                style: const TextStyle(fontSize: 16),
                              ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Mensaje de error
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 24),

                // Cambiar entre login y registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                        context.read<AuthProvider>().clearError();
                      },
                      child: Text(
                        _isLogin ? 'Regístrate' : 'Inicia sesión',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Olvidé mi contraseña
                if (_isLogin)
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperación de contraseña
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Función de recuperación de contraseña próximamente',
                          ),
                        ),
                      );
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    print('📱 [LoginScreen] _handleSubmit llamado');
    print('📱 [LoginScreen] Validando formulario...');

    if (!_formKey.currentState!.validate()) {
      print('📱 [LoginScreen] ❌ Validación del formulario falló');
      return;
    }

    print('📱 [LoginScreen] ✅ Validación del formulario exitosa');
    print('📱 [LoginScreen] Modo: ${_isLogin ? "Login" : "Registro"}');
    print('📱 [LoginScreen] Nombre: ${_nombreController.text.trim()}');
    print(
      '📱 [LoginScreen] Password: ${_passwordController.text.length} caracteres',
    );

    final authProvider = context.read<AuthProvider>();
    print('📱 [LoginScreen] AuthProvider obtenido');

    bool success;

    if (_isLogin) {
      print('📱 [LoginScreen] Iniciando proceso de login...');
      success = await authProvider.signIn(
        _nombreController.text.trim(),
        _passwordController.text,
      );
      print('📱 [LoginScreen] Resultado del login: $success');
    } else {
      print('📱 [LoginScreen] Iniciando proceso de registro...');
      success = await authProvider.signUp(
        nombre: _nombreController.text.trim(),
        password: _passwordController.text,
        rol: 'usuario', // Rol por defecto
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
      );
      print('📱 [LoginScreen] Resultado del registro: $success');
    }

    print('📱 [LoginScreen] Success: $success, Mounted: $mounted');
    if (success && mounted) {
      print(
        '📱 [LoginScreen] ✅ Navegación exitosa - El router se encargará de la navegación',
      );
      // No navegar manualmente, GoRouter redirige automáticamente
      // context.go('/');
    } else {
      print(
        '📱 [LoginScreen] ❌ Navegación falló - Success: $success, Mounted: $mounted',
      );
    }
  }
}
