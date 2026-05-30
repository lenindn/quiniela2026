-- ============================================================
-- Modulo de Actividad -- Quiniela Mundial 2026
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- 1. Tabla
CREATE TABLE IF NOT EXISTS actividad (
  id              BIGSERIAL PRIMARY KEY,
  participante_id UUID REFERENCES participantes(id) ON DELETE SET NULL,
  nombre          TEXT NOT NULL,
  grupo           TEXT,
  accion          TEXT NOT NULL,
  detalle         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_actividad_created ON actividad(created_at DESC);

-- 2. RLS: anon puede INSERT, nadie puede SELECT directamente
ALTER TABLE actividad ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_insert_actividad" ON actividad;
CREATE POLICY "anon_insert_actividad" ON actividad
  FOR INSERT TO anon WITH CHECK (true);

-- 3. RPC para que el admin lea los logs
CREATE OR REPLACE FUNCTION get_actividad(p_limit INT DEFAULT 200)
RETURNS TABLE(
  id              BIGINT,
  participante_id UUID,
  nombre          TEXT,
  grupo           TEXT,
  accion          TEXT,
  detalle         TEXT,
  created_at      TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.participante_id, a.nombre, a.grupo, a.accion, a.detalle, a.created_at
  FROM actividad a
  ORDER BY a.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Verificacion: SELECT * FROM get_actividad(10);