-- ============================================================
-- MIGRACIÓN: Sistema multi-grupo
-- Ejecutar DESPUÉS de schema.sql en Supabase > SQL Editor
-- ============================================================

-- Tabla de grupos de quiniela (uno por grupo de WhatsApp)
CREATE TABLE IF NOT EXISTS grupos_quiniela (
    id TEXT PRIMARY KEY,           -- código corto: 'liceo', 'trabajo', etc.
    nombre TEXT NOT NULL,          -- nombre largo: 'Peluches Salesinos'
    icono    TEXT DEFAULT '⚽',       -- emoji fallback (si no hay logo)
    color    TEXT DEFAULT '#1a5c2a',  -- color hex del grupo
    logo_url  TEXT DEFAULT NULL,        -- URL pública del logo (Supabase Storage)
    creado_en TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE grupos_quiniela ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read_grupos_quiniela"   ON grupos_quiniela FOR SELECT USING (true);
CREATE POLICY "insert_grupos_quiniela" ON grupos_quiniela FOR INSERT WITH CHECK (true);
CREATE POLICY "update_grupos_quiniela" ON grupos_quiniela FOR UPDATE USING (true);
CREATE POLICY "delete_grupos_quiniela" ON grupos_quiniela FOR DELETE USING (true);

-- Agregar columna grupo_quiniela a participantes
ALTER TABLE participantes
    ADD COLUMN IF NOT EXISTS grupo_quiniela TEXT REFERENCES grupos_quiniela(id);

-- ============================================================
-- STORAGE BUCKET (ejecutar en Supabase > Storage > New bucket)
-- Nombre del bucket: logos-grupos
-- Tipo: Public
-- Limit de archivo: 2 MB
-- Tipos permitidos: image/jpeg, image/png, image/webp, image/gif
-- ============================================================
-- Política de storage para subida pública (ejecutar en SQL Editor):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('logos-grupos', 'logos-grupos', true);
-- CREATE POLICY "logos_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos-grupos');
-- CREATE POLICY "logos_read"   ON storage.objects FOR SELECT USING (bucket_id = 'logos-grupos');
-- CREATE POLICY "logos_update" ON storage.objects FOR UPDATE USING (bucket_id = 'logos-grupos');
-- ============================================================

-- NOTA: Un WhatsApp = un solo grupo (restricción UNIQUE(whatsapp) existente se mantiene)
-- Si en el futuro quieres permitir el mismo número en varios grupos, ejecutar:
--   ALTER TABLE participantes DROP CONSTRAINT participantes_whatsapp_key;
--   ALTER TABLE participantes ADD CONSTRAINT participantes_wa_grupo_unique UNIQUE(whatsapp, grupo_quiniela);
