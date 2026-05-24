-- ============================================================
-- Soporte multi-grupo: un participante puede estar en varios grupos
-- con picks independientes por grupo.
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- 1. Quitar el unique constraint de solo whatsapp (si existe)
ALTER TABLE participantes DROP CONSTRAINT IF EXISTS participantes_whatsapp_key;

-- 2. Agregar unique constraint en (whatsapp + grupo_quiniela)
--    Permite el mismo número en grupos distintos, pero no duplicados en el mismo grupo
ALTER TABLE participantes
  ADD CONSTRAINT participantes_whatsapp_grupo_uq
  UNIQUE (whatsapp, grupo_quiniela);
