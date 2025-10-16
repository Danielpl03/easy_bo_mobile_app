import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';

class CustomAuthService {
  static final CustomAuthService _instance = CustomAuthService._internal();
  factory CustomAuthService() => _instance;
  CustomAuthService._internal();

  final SupabaseClient _client = SupabaseConfig.client;
  Usuario? _currentUser;
  bool _isLoading = false;

  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // Inicializar el servicio
  Future<void> initialize() async {
    print('🔐 [CustomAuthService] Inicializando servicio...');
    await _loadUserFromStorage();
    print('🔐 [CustomAuthService] Servicio inicializado.');
  }

  // Cargar usuario desde almacenamiento local
  Future<void> _loadUserFromStorage() async {
    print('🔐 [CustomAuthService] Cargando usuario desde almacenamiento local...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = json.decode(userJson);
        _currentUser = Usuario.fromJson(userData);
        print('🔐 [CustomAuthService] Usuario cargado desde storage: ${_currentUser?.nombre}');
      } else {
        print('🔐 [CustomAuthService] No se encontró usuario en storage.');
      }
    } catch (e) {
      print('🔐 [CustomAuthService] Error loading user from storage: $e');
    }
  }

  // Guardar usuario en almacenamiento local
  Future<void> _saveUserToStorage(Usuario? user) async {
    print('🔐 [CustomAuthService] Guardando usuario en almacenamiento local...');
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString('current_user', json.encode(user.toJson()));
        print('🔐 [CustomAuthService] Usuario ${user.nombre} guardado en storage.');
      } else {
        await prefs.remove('current_user');
        print('🔐 [CustomAuthService] Usuario eliminado de storage.');
      }
    } catch (e) {
      print('🔐 [CustomAuthService] Error saving user to storage: $e');
    }
  }

  // Iniciar sesión
  Future<bool> signIn(String nombre, String password) async {
    print('🔐 [CustomAuthService] Intentando signIn para: ${nombre}');
    _isLoading = true;
    try {
      // Buscar usuario por nombre
      print('🔐 [CustomAuthService] Buscando usuario en Supabase...');
      final response = await _client
          .from('usuarios')
          .select()
          .eq('nombre', nombre)
          .maybeSingle();

      if (response == null) {
        print('🔐 [CustomAuthService] Usuario ${nombre} no encontrado.');
        return false;
      }
      print('🔐 [CustomAuthService] Usuario encontrado en Supabase: ${response}');
      final usuario = Usuario.fromJson(response);
      // Verificar contraseña con bcrypt
      print('🔐 [CustomAuthService] Verificando contraseña...');
      final isValid = BCrypt.checkpw(password, usuario.password);
      if (!isValid) {
        print('🔐 [CustomAuthService] Contraseña inválida para ${nombre}');
        return false;
      }
      print('🔐 [CustomAuthService] Contraseña verificada. Usuario autenticado: ${usuario.nombre}');
      _currentUser = usuario;
      await _saveUserToStorage(_currentUser);
      // Actualizar último acceso
      await _updateLastAccess(_currentUser!.idUsuario);
      print('🔐 [CustomAuthService] Último acceso actualizado y signIn exitoso.');
      return true;
    } catch (e) {
      print('🔐 [CustomAuthService] Error signing in: $e');
      return false;
    } finally {
      _isLoading = false;
      print('🔐 [CustomAuthService] isLoading set to false');
    }
  }

  // Actualizar último acceso
  Future<void> _updateLastAccess(int idUsuario) async {
    print('🔐 [CustomAuthService] Actualizando último acceso para idUsuario: ${idUsuario}');
    try {
      await _client
          .from('usuarios')
          .update({
            'ultimo_acceso': DateTime.now().toIso8601String(),
          })
          .eq('id_usuario', idUsuario);
      print('🔐 [CustomAuthService] Último acceso actualizado en Supabase.');
    } catch (e) {
      print('🔐 [CustomAuthService] Error updating last access: $e');
    }
  }

  // Registrar nuevo usuario
  Future<bool> signUp({
    required String nombre,
    required String password,
    required String rol,
    String? email,
  }) async {
    print('🔐 [CustomAuthService] Intentando signUp para: ${nombre}');
    _isLoading = true;
    try {
      // Hashear la contraseña con bcrypt
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      print('🔐 [CustomAuthService] Contraseña hasheada.');
      // Verificar si el usuario ya existe
      final existingUser = await _client
          .from('usuarios')
          .select()
          .eq('nombre', nombre)
          .maybeSingle();
      if (existingUser != null) {
        print('🔐 [CustomAuthService] Error: El usuario ${nombre} ya existe.');
        throw Exception('El usuario ya existe');
      }
      // Obtener el siguiente ID de usuario
      final maxIdResult = await _client
          .from('usuarios')
          .select('id_usuario')
          .order('id_usuario', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextId = (maxIdResult?['id_usuario'] ?? 0) + 1;
      print('🔐 [CustomAuthService] Siguiente ID de usuario: ${nextId}');
      // Insertar nuevo usuario
      final response = await _client
          .from('usuarios')
          .insert({
            'id_usuario': nextId,
            'nombre': nombre,
            'password': hashedPassword,
            'rol': rol,
            'email': email,
            'ultimo_acceso': DateTime.now().toIso8601String(),
            'activo': true,
          })
          .select()
          .single();
      print('🔐 [CustomAuthService] Usuario ${nombre} registrado exitosamente.');
      _currentUser = Usuario.fromJson(response);
      await _saveUserToStorage(_currentUser);
      return true;
    } catch (e) {
      print('🔐 [CustomAuthService] Error signing up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      print('🔐 [CustomAuthService] isLoading set to false');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    print('🔐 [CustomAuthService] Intentando signOut...');
    _isLoading = true;
    try {
      _currentUser = null;
      await _saveUserToStorage(null);
      print('🔐 [CustomAuthService] Sesión cerrada y usuario eliminado de storage.');
    } catch (e) {
      print('🔐 [CustomAuthService] Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      print('🔐 [CustomAuthService] isLoading set to false');
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword(String newPassword) async {
    print('🔐 [CustomAuthService] Intentando cambiar contraseña...');
    if (_currentUser == null) {
      print('🔐 [CustomAuthService] No hay usuario autenticado para cambiar contraseña.');
      return false;
    }
    try {
      // Hashear la nueva contraseña con bcrypt
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      print('🔐 [CustomAuthService] Nueva contraseña hasheada.');
      await _client
          .from('usuarios')
          .update({
            'password': hashedPassword,
          })
          .eq('id_usuario', _currentUser!.idUsuario);
      _currentUser = _currentUser!.copyWith(password: hashedPassword);
      await _saveUserToStorage(_currentUser);
      print('🔐 [CustomAuthService] Contraseña cambiada exitosamente para ${_currentUser!.nombre}');
      return true;
    } catch (e) {
      print('🔐 [CustomAuthService] Error changing password: $e');
      return false;
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateProfile({
    String? nombre,
    String? email,
  }) async {
    print('🔐 [CustomAuthService] Intentando actualizar perfil...');
    if (_currentUser == null) {
      print('🔐 [CustomAuthService] No hay usuario autenticado para actualizar perfil.');
      return false;
    }
    
    try {
      final updateData = <String, dynamic>{};
      if (nombre != null) updateData['nombre'] = nombre;
      if (email != null) updateData['email'] = email;
      
      if (updateData.isNotEmpty) {
        print('🔐 [CustomAuthService] Datos a actualizar: ${updateData}');
        await _client
            .from('usuarios')
            .update(updateData)
            .eq('id_usuario', _currentUser!.idUsuario);
        
        _currentUser = _currentUser!.copyWith(
          nombre: nombre,
          email: email,
        );
        
        await _saveUserToStorage(_currentUser);
        print('🔐 [CustomAuthService] Perfil actualizado exitosamente para ${_currentUser!.nombre}');
      } else {
        print('🔐 [CustomAuthService] No hay datos para actualizar.');
      }
      
      return true;
    } catch (e) {
      print('🔐 [CustomAuthService] Error updating profile: $e');
      return false;
    }
  }

  // Verificar si el usuario está autenticado
  Future<bool> isUserAuthenticated() async {
    print('🔐 [CustomAuthService] Verificando si usuario está autenticado. CurrentUser: ${_currentUser != null}');
    return _currentUser != null;
  }

  // Obtener el usuario actual
  Future<Usuario?> getCurrentUser() async {
    print('🔐 [CustomAuthService] Obteniendo usuario actual. CurrentUser: ${_currentUser}');
    return _currentUser;
  }

  // Verificar si el usuario tiene un rol específico
  bool hasRole(String role) {
    print('🔐 [CustomAuthService] Verificando rol ${role} para usuario ${_currentUser?.nombre}. Rol actual: ${_currentUser?.rol}');
    return _currentUser?.rol.toLowerCase() == role.toLowerCase();
  }

  // Verificar si el usuario es administrador
  bool get isAdmin {
    print('🔐 [CustomAuthService] Verificando si es administrador.');
    return hasRole('admin') || hasRole('master');
  }
} 