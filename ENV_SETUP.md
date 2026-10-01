# Configuración de Variables de Entorno

## Descripción
Este proyecto utiliza variables de entorno para almacenar de forma segura las llaves de Supabase, evitando exponer información sensible en el código fuente. El sistema soporta múltiples configuraciones de bases de datos mediante claves de configuración.

## Sistema de Configuración Múltiple

El sistema permite conectarse a múltiples bases de datos Supabase usando claves de configuración. Esto es útil cuando necesitas trabajar con diferentes empresas o entornos.

### Cómo Funciona

1. **Configuración por Defecto (sin clave):**
   - Variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_STORAGE_URL`

2. **Configuración con Clave (ej: 'la_calzada'):**
   - Variables: `SUPABASE_LA_CALZADA_URL`, `SUPABASE_LA_CALZADA_ANON_KEY`, `SUPABASE_LA_CALZADA_SERVICE_ROLE_KEY`, `SUPABASE_LA_CALZADA_STORAGE_URL`

3. **Configuración con Clave Personalizada (ej: 'empresa_x'):**
   - Variables: `SUPABASE_EMPRESA_X_URL`, `SUPABASE_EMPRESA_X_ANON_KEY`, etc.

## Archivos Creados/Modificados

### Archivos Nuevos:
- `.env` - Contiene las variables de entorno reales (NO se sube a Git)
- `.env.example` - Plantilla con los nombres de variables requeridas
- `ENV_SETUP.md` - Este archivo de documentación

### Archivos Modificados:
- `pubspec.yaml` - Agregado flutter_dotenv y shared_preferences como dependencias
- `lib/config/supabase_config.dart` - Modificado para usar sistema de claves de configuración
- `.gitignore` - Agregado .env para evitar commits accidentales

## Configuración Inicial

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Edita el archivo .env con tus valores reales:**
   
   **Ejemplo con configuración única (default):**
   ```
   SUPABASE_URL=tu_url_de_supabase_aqui
   SUPABASE_ANON_KEY=tu_clave_anonima_aqui
   SUPABASE_SERVICE_ROLE_KEY=tu_clave_de_servicio_aqui
   SUPABASE_STORAGE_URL=tu_url_de_storage_aqui
   ```
   
   **Ejemplo con múltiples configuraciones:**
   ```
   # Configuración por defecto
   SUPABASE_URL=url_por_defecto
   SUPABASE_ANON_KEY=anon_key_por_defecto
   SUPABASE_SERVICE_ROLE_KEY=service_key_por_defecto
   SUPABASE_STORAGE_URL=storage_url_por_defecto
   
   # Configuración para La Calzada
   SUPABASE_LA_CALZADA_URL=url_la_calzada
   SUPABASE_LA_CALZADA_ANON_KEY=anon_key_la_calzada
   SUPABASE_LA_CALZADA_SERVICE_ROLE_KEY=service_key_la_calzada
   SUPABASE_LA_CALZADA_STORAGE_URL=storage_url_la_calzada
   
   # Configuración para otra empresa
   SUPABASE_EMPRESA_X_URL=url_empresa_x
   SUPABASE_EMPRESA_X_ANON_KEY=anon_key_empresa_x
   SUPABASE_EMPRESA_X_SERVICE_ROLE_KEY=service_key_empresa_x
   SUPABASE_EMPRESA_X_STORAGE_URL=storage_url_empresa_x
   ```

3. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

## Uso en el Código

### Inicialización Básica (usa configuración guardada o default)

```dart
await SupabaseConfig.initialize();
```

### Inicialización con Clave Específica

```dart
// Establecer la clave de configuración al inicializar
await SupabaseConfig.initialize(configKey: 'la_calzada');
```

### Cambiar la Configuración en Tiempo de Ejecución

```dart
// Establecer una nueva clave de configuración
await SupabaseConfig.setConfigKey('empresa_x');

// Reinicializar Supabase con la nueva configuración
// Nota: Esto requiere reiniciar la conexión de Supabase
await SupabaseConfig.initialize(configKey: 'empresa_x');
```

### Obtener la Clave de Configuración Actual

```dart
final currentKey = await SupabaseConfig.getConfigKey();
print('Configuración actual: ${currentKey ?? 'default'}');
```

### Resetear a Configuración por Defecto

```dart
await SupabaseConfig.setConfigKey(null); // o 'default'
```

## Notas sobre los Nombres de Variables

- Las claves se normalizan automáticamente:
  - Espacios y guiones se convierten en guiones bajos
  - Todo se convierte a mayúsculas
  - Ejemplo: `'la calzada'` → `'LA_CALZADA'`
  
- Para usar una configuración con clave `'mi_empresa'`, las variables deben ser:
  - `SUPABASE_MI_EMPRESA_URL`
  - `SUPABASE_MI_EMPRESA_ANON_KEY`
  - `SUPABASE_MI_EMPRESA_SERVICE_ROLE_KEY`
  - `SUPABASE_MI_EMPRESA_STORAGE_URL`

## Persistencia

La clave de configuración se guarda automáticamente en `SharedPreferences`, por lo que la aplicación recordará la última configuración utilizada entre sesiones.

## Seguridad

- ✅ Las llaves privadas ya no están expuestas en el código
- ✅ El archivo `.env` está en `.gitignore`
- ✅ Se incluye validación de variables requeridas
- ✅ Se proporciona plantilla `.env.example` para nuevos desarrolladores
- ✅ La configuración se persiste de forma segura en el dispositivo

## Notas Importantes

- **NUNCA** subas el archivo `.env` al repositorio
- **SIEMPRE** mantén actualizado el archivo `.env.example`
- Si cambias las variables de entorno, reinicia la aplicación
- El sistema valida que todas las variables requeridas estén presentes al inicializar
- La clave de configuración se guarda automáticamente y se reutiliza en el siguiente inicio
