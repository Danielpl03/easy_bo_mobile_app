# Configuración de Autenticación - Easy BO Mobile App

## Descripción

Este documento describe cómo configurar el sistema de autenticación para la aplicación Easy BO Mobile App, que utiliza la tabla `usuarios` existente en tu base de datos.

## Características Implementadas

- ✅ Inicio de sesión con nombre de usuario y contraseña
- ✅ Registro de nuevos usuarios
- ✅ Gestión de perfil de usuario
- ✅ Cambio de contraseña
- ✅ Cerrar sesión
- ✅ Persistencia de sesión
- ✅ Protección de rutas
- ✅ Manejo de errores amigable
- ✅ Soporte para roles de usuario
- ✅ Hash MD5 para contraseñas (compatible con sistemas legacy)

## Configuración en Supabase

### 1. Actualizar la tabla usuarios existente

Ejecuta el script SQL `sql/update_usuarios_table.sql` en el SQL Editor de Supabase para agregar campos adicionales:

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
  password text NOT NULL,
  rol text NOT NULL,
  email text,                    -- Campo opcional agregado
  ultimo_acceso timestamp,       -- Campo opcional agregado
  activo boolean DEFAULT true,   -- Campo opcional agregado
  created_at timestamp DEFAULT NOW(),
  updated_at timestamp DEFAULT NOW(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario)
);
```

### 3. Campos requeridos vs opcionales

**Campos requeridos (existentes):**
- `id_usuario`: ID único del usuario
- `nombre`: Nombre de usuario para login
- `password`: Contraseña hasheada (MD5)
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
│   └── custom_auth_service.dart        # Servicio de autenticación personalizado
├── presentation/
│   ├── providers/
│   │   └── auth_provider.dart          # Provider de estado de auth
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
- La contraseña se hashea con MD5 antes de comparar
- Validación de campos en tiempo real
- Manejo de errores amigable
- Redirección automática después del éxito

### 3. Protección de Rutas
- Todas las rutas excepto `/login` requieren autenticación
- Redirección automática basada en el estado de auth

## Uso en la App

### Login
```dart
final authProvider = context.read<AuthProvider>();
bool success = await authProvider.signIn(nombreUsuario, password);
```

### Registro
```dart
final authProvider = context.read<AuthProvider>();
bool success = await authProvider.signUp(
  nombre: nombreUsuario,
  password: password,
  rol: 'usuario',
  email: email, // opcional
);
```

### Verificar estado de autenticación
```dart
final authProvider = context.watch<AuthProvider>();
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
final authService = CustomAuthService();
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

### Seguridad
- Hash MD5 para contraseñas (compatible con sistemas existentes)
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
3. **Mantiene compatibilidad** con contraseñas existentes
4. **Agrega campos opcionales** sin afectar funcionalidad

## Próximas Mejoras

- [ ] Autenticación con Google
- [ ] Recuperación de contraseña
- [ ] Verificación de email
- [ ] Autenticación biométrica
- [ ] Roles y permisos más granulares
- [ ] Historial de sesiones
- [ ] Migración a hash más seguro (bcrypt)

## Troubleshooting

### Error: "Usuario no encontrado"
- Verifica que el nombre de usuario exista en la tabla
- Asegúrate de que el usuario esté activo

### Error: "Contraseña incorrecta"
- Verifica que la contraseña sea correcta
- El sistema usa hash MD5 para compatibilidad

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
- Hash MD5 para compatibilidad con sistemas legacy 