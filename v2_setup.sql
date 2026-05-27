-- ============================================================
-- Setup para index_v2.html — Quiniela por Fases
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- 1. Columna para activación de participante por fase
--    NULL = activo en todas las fases (valor por defecto)
--    {"grupos": false} = inactivo en la fase de grupos, activo en el resto
ALTER TABLE participantes
  ADD COLUMN IF NOT EXISTS fases_activas JSONB DEFAULT NULL;

-- ============================================================
-- 2. Textos de pote/premio por fase en la tabla config
--    El admin los edita desde el panel Admin → "Premios por Fase"
--    pero también puedes insertarlos aquí con valores iniciales
-- ============================================================
INSERT INTO config (clave, valor) VALUES
  ('pote_grupos',       'Premio por anunciar'),
  ('pote_r32',          'Premio por anunciar'),
  ('pote_r16',          'Premio por anunciar'),
  ('pote_cuartos',      'Premio por anunciar'),
  ('pote_semis',        'Premio por anunciar'),
  ('pote_tercer_lugar', 'Premio por anunciar'),
  ('pote_final',        'Premio por anunciar')
ON CONFLICT (clave) DO NOTHING;

-- ============================================================
-- Verificación
-- ============================================================
-- SELECT clave, valor FROM config WHERE clave LIKE 'pote_%' ORDER BY clave;
-- SELECT id, nombre, fases_activas FROM participantes LIMIT 10;
