# Configuración de Autenticación con Texto Plano - Easy BO Mobile App

## Descripción

Este documento describe cómo configurar el sistema de autenticación para la aplicación Easy BO Mobile App usando contraseñas en texto plano. **Esta implementación es temporal y debe migrarse a hash más adelante por seguridad.**

## ⚠️ ADVERTENCIA DE SEGURIDAD

**Esta implementación usa contraseñas en texto plano por compatibilidad con sistemas existentes. Esto es una vulnerabilidad de seguridad y debe migrarse a hash (MD5, bcrypt, etc.) lo antes posible.**

## Características Implementadas

- ✅ Inicio de sesión con nombre de usuario y contraseña (texto plano)
- ✅ Registro de nuevos usuarios
- ✅ Gestión de perfil de usuario
- ✅ Cambio de contraseña
- ✅ Cerrar sesión
- ✅ Persistencia de sesión
- ✅ Protección de rutas
- ✅ Manejo de errores amigable
- ✅ Soporte para roles de usuario
- ⚠️ **Contraseñas en texto plano (temporal)**

## Configuración en Supabase

### 1. Actualizar la tabla usuarios existente

Ejecuta el script SQL `sql/update_usuarios_plain.sql` en el SQL Editor de Supabase:

```sql
-- Agregar campos adicionales a la tabla usuarios existente
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS email TEXT;

ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS ultimo_acceso TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;
```

### 2. Estructura de la tabla usuarios

La tabla `usuarios` debe tener la siguiente estructura:

```sql
CREATE TABLE public.usuarios (
  id_usuario integer NOT NULL,
  nombre text NOT NULL,
  password text NOT NULL,           -- ⚠️ Texto plano (temporal)
  rol text NOT NULL,
  email text,                       -- Campo opcional agregado
  ultimo_acceso timestamp,          -- Campo opcional agregado
  activo boolean DEFAULT true,      -- Campo opcional agregado
  created_at timestamp DEFAULT NOW(),
  updated_at timestamp DEFAULT NOW(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario)
);
```

### 3. Campos requeridos vs opcionales

**Campos requeridos (existentes):**
- `id_usuario`: ID único del usuario
- `nombre`: Nombre de usuario para login
- `password`: Contraseña en texto plano ⚠️
- `rol`: Rol del usuario (admin, usuario, etc.)

**Campos opcionales (agregados):**
- `email`: Email del usuario
- `ultimo_acceso`: Fecha del último acceso
- `activo`: Estado del usuario
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

## Estructura de Archivos

```
lib/
├── models/
│   └── usuario.dart                    # Modelo de usuario con Hive
├── services/
│   └── plain_auth_service.dart         # Servicio de autenticación (texto plano)
├── presentation/
│   ├── providers/
│   │   └── plain_auth_provider.dart    # Provider de estado de auth
│   └── screens/
│       ├── login_screen.dart           # Pantalla de login/registro
│       └── profile_screen.dart         # Pantalla de perfil
└── config/
    └── app_router.dart                 # Router con protección de rutas
```

## Flujo de Autenticación

### 1. Inicio de la App
- La app verifica si hay una sesión activa
- Si no hay sesión, redirige a `/login`
- Si hay sesión, redirige a `/` (home)

### 2. Login/Registro
- El usuario ingresa su nombre de usuario y contraseña
- **La contraseña se compara directamente en texto plano** ⚠️
- Validación de campos en tiempo real
- Manejo de errores amigable
- Redirección automática después del éxito

### 3. Protección de Rutas
- Todas las rutas excepto `/login` requieren autenticación
- Redirección automática basada en el estado de auth

## Uso en la App

### Login
```dart
final authProvider = context.read<PlainAuthProvider>();
bool success = await authProvider.signIn(nombreUsuario, password);
```

### Registro
```dart
final authProvider = context.read<PlainAuthProvider>();
bool success = await authProvider.signUp(
  nombre: nombreUsuario,
  password: password,
  rol: 'usuario',
  email: email, // opcional
);
```

### Verificar estado de autenticación
```dart
final authProvider = context.watch<PlainAuthProvider>();
if (authProvider.isAuthenticated) {
  // Usuario autenticado
}
```

### Obtener usuario actual
```dart
final user = authProvider.currentUser;
print(user?.nombreCompleto);
print(user?.rol);
```

### Verificar roles
```dart
final authService = PlainAuthService();
if (authService.hasRole('admin')) {
  // Usuario es administrador
}
```

### Cerrar sesión
```dart
await authProvider.signOut();
```

## Características Adicionales

### Persistencia de Sesión
- La sesión se mantiene entre reinicios de la app
- Uso de SharedPreferences para almacenamiento local
- Sincronización automática con la base de datos

### Manejo de Errores
- Mensajes de error amigables
- Validación de campos
- Indicadores de carga
- Feedback visual

### Seguridad (Limitada)
- ⚠️ **Contraseñas en texto plano** (vulnerabilidad)
- Validación de contraseñas
- Protección de rutas
- Limpieza automática de datos

### Roles y Permisos
- Sistema de roles integrado
- Verificación de permisos
- Roles predefinidos: admin, usuario, etc.

## Migración desde Supabase Auth

Si anteriormente usabas Supabase Auth, el nuevo sistema:

1. **No requiere** Supabase Auth
2. **Usa tu tabla usuarios existente**
3. **Mantiene compatibilidad** con contraseñas existentes en texto plano
4. **Agrega campos opcionales** sin afectar funcionalidad

## Plan de Migración a Hash

### Fase 1: Implementación Actual (Texto Plano)
- ✅ Sistema funcional con texto plano
- ✅ Compatibilidad con datos existentes
- ✅ Pruebas y validación

### Fase 2: Migración a Hash (Futuro)
- [ ] Implementar hash MD5 o bcrypt
- [ ] Script de migración de contraseñas
- [ ] Actualizar servicios de autenticación
- [ ] Migrar usuarios existentes
- [ ] Validar seguridad

### Fase 3: Mejoras de Seguridad
- [ ] Implementar salt único por usuario
- [ ] Migrar a bcrypt o Argon2
- [ ] Implementar rate limiting
- [ ] Logs de auditoría
- [ ] Políticas de contraseñas

## Próximas Mejoras

- [ ] **MIGRACIÓN A HASH** (Prioridad alta)
- [ ] Autenticación con Google
- [ ] Recuperación de contraseña
- [ ] Verificación de email
- [ ] Autenticación biométrica
- [ ] Roles y permisos más granulares
- [ ] Historial de sesiones

## Troubleshooting

### Error: "Usuario no encontrado"
- Verifica que el nombre de usuario exista en la tabla
- Asegúrate de que el usuario esté activo

### Error: "Contraseña incorrecta"
- Verifica que la contraseña sea correcta
- El sistema usa texto plano temporalmente

### Error: "El usuario ya existe"
- El nombre de usuario ya está en uso
- Usa otro nombre de usuario o intenta iniciar sesión

### Error: "Network"
- Verifica tu conexión a internet
- Revisa la configuración de Supabase

## Notas de Desarrollo

- La app usa Hive para almacenamiento local
- Supabase se usa solo como base de datos (no Auth)
- El router usa GoRouter con redirección automática
- Provider se usa para gestión de estado
- Los errores se manejan de forma amigable
- ⚠️ **Contraseñas en texto plano (temporal)**

## Archivos de Implementación

### Servicios
- `lib/services/plain_auth_service.dart` - Servicio de autenticación
- `lib/presentation/providers/plain_auth_provider.dart` - Provider de estado

### Pantallas
- `lib/presentation/screens/login_screen.dart` - Pantalla de login
- `lib/presentation/screens/profile_screen.dart` - Pantalla de perfil

### Configuración
- `lib/config/app_router.dart` - Router con protección
- `sql/update_usuarios_plain.sql` - Script SQL para actualizar tabla

## Comandos de Prueba

```bash
# Ejecutar la aplicación
flutter run

# Analizar código
flutter analyze

# Generar archivos de Hive
flutter packages pub run build_runner build
```

## Recordatorio de Seguridad

⚠️ **IMPORTANTE**: Esta implementación usa contraseñas en texto plano por compatibilidad. Debes migrar a hash lo antes posible para proteger la seguridad de los usuarios. 