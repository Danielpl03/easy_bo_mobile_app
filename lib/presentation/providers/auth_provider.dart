import 'package:easy_bo_mobile_app/models/usuario.dart';
import 'package:easy_bo_mobile_app/services/custom_auth_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final CustomAuthService _authService = CustomAuthService();
  
  Usuario? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  // Inicializar el provider
  Future<void> initialize() async {
    print('[AuthProvider] Inicializando...');
    _isLoading = true;
    notifyListeners();
    print('[AuthProvider] notifyListeners() tras set loading true');
    
    try {
      await _authService.initialize();
      await _checkAuthState();
    } catch (e) {
      _errorMessage = 'Error al inicializar la autenticación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[AuthProvider] notifyListeners() tras set loading false');
    }
  }

  // Verificar estado de autenticación
  Future<void> _checkAuthState() async {
    print('[AuthProvider] _checkAuthState() llamado');
    final isAuth = await _authService.isUserAuthenticated();
    print('[AuthProvider] isUserAuthenticated: ${isAuth}');
    _isAuthenticated = isAuth;
    print('[AuthProvider] _isAuthenticated actualizado: ${_isAuthenticated}');
    if (isAuth) {
      _currentUser = await _authService.getCurrentUser();
      print('[AuthProvider] Usuario autenticado: ${_currentUser}');
    }
    notifyListeners();
    print('[AuthProvider] notifyListeners() tras _checkAuthState');
  }

  // Iniciar sesión
  Future<bool> signIn(String nombre, String password) async {
    print('[AuthProvider] signIn llamado');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    print('[AuthProvider] notifyListeners() tras set loading true');

    try {
      await _authService.signIn(nombre, password);
      await _checkAuthState();
      print('[AuthProvider] Resultado de _checkAuthState: isAuthenticated=${_isAuthenticated}');
      return _isAuthenticated;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('[AuthProvider] Error en signIn: ${_errorMessage}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[AuthProvider] notifyListeners() tras set loading false');
    }
  }

  // Registrar nuevo usuario
  Future<bool> signUp({
    required String nombre,
    required String password,
    required String rol,
    String? email,
  }) async {
    print('[AuthProvider] signUp llamado');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    print('[AuthProvider] notifyListeners() tras set loading true');

    try {
      await _authService.signUp(
        nombre: nombre,
        password: password,
        rol: rol,
        email: email,
      );
      await _checkAuthState();
      print('[AuthProvider] Resultado de _checkAuthState: isAuthenticated=${_isAuthenticated}');
      return _isAuthenticated;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('[AuthProvider] Error en signUp: ${_errorMessage}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[AuthProvider] notifyListeners() tras set loading false');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    print('[AuthProvider] signOut llamado');
    _isLoading = true;
    notifyListeners();
    print('[AuthProvider] notifyListeners() tras set loading true');

    try {
      await _authService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      print('[AuthProvider] Sesión cerrada');
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
      print('[AuthProvider] Error en signOut: ${_errorMessage}');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[AuthProvider] notifyListeners() tras set loading false');
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile({
    String? nombre,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateProfile(
        nombre: nombre,
      );
      
      // Actualizar el usuario actual
      _currentUser = await _authService.getCurrentUser();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar perfil: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(newPassword);
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar contraseña: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Obtener mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Invalid login credentials')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    } else if (error.toString().contains('Email not confirmed')) {
      return 'Por favor confirma tu email antes de iniciar sesión.';
    } else if (error.toString().contains('User already registered')) {
      return 'El usuario ya está registrado.';
    } else if (error.toString().contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else if (error.toString().contains('Invalid email')) {
      return 'El formato del email no es válido.';
    } else if (error.toString().contains('Network')) {
      return 'Error de conexión. Verifica tu conexión a internet.';
    } else {
      return 'Error inesperado: $error';
    }
  }
} 