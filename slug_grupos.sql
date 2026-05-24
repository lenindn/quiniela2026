-- ============================================================
-- Agrega links amigables a los grupos de quiniela
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

ALTER TABLE grupos_quiniela ADD COLUMN IF NOT EXISTS slug TEXT;

ALTER TABLE grupos_quiniela
  ADD CONSTRAINT grupos_quiniela_slug_uq UNIQUE (slug);
