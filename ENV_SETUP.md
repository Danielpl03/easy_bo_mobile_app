# Configuración de Variables de Entorno

## Descripción
Este proyecto ahora utiliza variables de entorno para almacenar de forma segura las llaves de Supabase, evitando exponer información sensible en el código fuente.

## Archivos Creados/Modificados

### Archivos Nuevos:
- `.env` - Contiene las variables de entorno reales (NO se sube a Git)
- `.env.example` - Plantilla con los nombres de variables requeridas
- `ENV_SETUP.md` - Este archivo de documentación

### Archivos Modificados:
- `pubspec.yaml` - Agregado flutter_dotenv como dependencia
- `lib/config/supabase_config.dart` - Modificado para usar variables de entorno
- `.gitignore` - Agregado .env para evitar commits accidentales

## Configuración Inicial

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Edita el archivo .env con tus valores reales:**
   ```
   SUPABASE_URL=tu_url_de_supabase_aqui
   SUPABASE_ANON_KEY=tu_clave_anonima_aqui
   SUPABASE_SERVICE_ROLE_KEY=tu_clave_de_servicio_aqui
   SUPABASE_STORAGE_URL=tu_url_de_storage_aqui
   ```

3. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

## Seguridad

- ✅ Las llaves privadas ya no están expuestas en el código
- ✅ El archivo `.env` está en `.gitignore`
- ✅ Se incluye validación de variables requeridas
- ✅ Se proporciona plantilla `.env.example` para nuevos desarrolladores

## Uso en el Código

El archivo `supabase_config.dart` ahora carga automáticamente las variables de entorno:

```dart
// Las variables se cargan automáticamente desde .env
static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
```

## Notas Importantes

- **NUNCA** subas el archivo `.env` al repositorio
- **SIEMPRE** mantén actualizado el archivo `.env.example`
- Si cambias las variables de entorno, reinicia la aplicación
- El sistema valida que todas las variables requeridas estén presentes al inicializar
