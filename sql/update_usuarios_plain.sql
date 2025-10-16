-- Agregar campos adicionales a la tabla usuarios existente (versión texto plano)
-- Estos campos son opcionales y no afectan la funcionalidad existente

-- Agregar campo email (opcional)
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Agregar campo último acceso
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS ultimo_acceso TIMESTAMP WITH TIME ZONE;

-- Agregar campo activo
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;

-- Agregar campo created_at
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Agregar campo updated_at
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_usuarios_nombre ON usuarios(nombre);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);

-- Función para actualizar el timestamp de updated_at
CREATE OR REPLACE FUNCTION update_usuarios_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear trigger para actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_usuarios_updated_at_trigger ON usuarios;
CREATE TRIGGER update_usuarios_updated_at_trigger
    BEFORE UPDATE ON usuarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_usuarios_updated_at();

-- Comentarios sobre la estructura
COMMENT ON TABLE public.usuarios IS 'Tabla de usuarios del sistema (texto plano)';
COMMENT ON COLUMN public.usuarios.id_usuario IS 'ID único del usuario';
COMMENT ON COLUMN public.usuarios.nombre IS 'Nombre de usuario para login';
COMMENT ON COLUMN public.usuarios.password IS 'Contraseña en texto plano (temporal)';
COMMENT ON COLUMN public.usuarios.rol IS 'Rol del usuario (admin, usuario, etc.)';
COMMENT ON COLUMN public.usuarios.email IS 'Email del usuario (opcional)';
COMMENT ON COLUMN public.usuarios.ultimo_acceso IS 'Fecha y hora del último acceso';
COMMENT ON COLUMN public.usuarios.activo IS 'Indica si el usuario está activo';
COMMENT ON COLUMN public.usuarios.created_at IS 'Fecha de creación del registro';
COMMENT ON COLUMN public.usuarios.updated_at IS 'Fecha de última actualización'; 