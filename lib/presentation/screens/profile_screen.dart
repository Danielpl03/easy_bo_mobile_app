import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    print('[ProfileScreen] Cargando datos de usuario...');
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      print('[ProfileScreen] Usuario encontrado: ${authProvider.currentUser!.nombre}');
      _nombreController.text = authProvider.currentUser!.nombre;
    } else {
      print('[ProfileScreen] No hay usuario autenticado');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                  if (!_isEditing) {
                    _loadUserData();
                  }
                },
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            print('[ProfileScreen] Esperando usuario...');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar y información básica
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.currentUser!.nombreCompleto,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.currentUser!.email ?? 'Sin email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Información del usuario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información Personal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo de nombre
                          TextFormField(
                            controller: _nombreController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isEditing && (value == null || value.isEmpty)) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo de email (solo lectura)
                          TextFormField(
                            initialValue: authProvider.currentUser!.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            
                            // Cambiar contraseña
                            Text(
                              'Cambiar Contraseña',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Nueva contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                                if (_isEditing && value != null && value.isNotEmpty) {
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Confirmar nueva contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_isEditing && _passwordController.text.isNotEmpty) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  if (_isEditing) ...[
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  // Botón de cerrar sesión
                  OutlinedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignOut,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                  
                  // Mensaje de error
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSave() async {
    print('[ProfileScreen] Guardando cambios de perfil...');
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    bool success = true;
    // Actualizar perfil
    if (_nombreController.text.trim() != authProvider.currentUser!.nombre) {
      print('[ProfileScreen] Actualizando nombre...');
      success = await authProvider.updateProfile(
        nombre: _nombreController.text.trim(),
      );
      print('[ProfileScreen] Resultado actualizar nombre: ${success}');
    }
    // Cambiar contraseña si se proporcionó
    if (success && _passwordController.text.isNotEmpty) {
      print('[ProfileScreen] Cambiando contraseña...');
      success = await authProvider.changePassword(_passwordController.text);
      print('[ProfileScreen] Resultado cambiar contraseña: ${success}');
    }
    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      print('[ProfileScreen] Perfil actualizado correctamente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleSignOut() async {
    print('[ProfileScreen] Cerrando sesión...');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      print('[ProfileScreen] Confirmado, cerrando sesión...');
      await context.read<AuthProvider>().signOut();
      print('[ProfileScreen] Sesión cerrada');
    }
  }
} 