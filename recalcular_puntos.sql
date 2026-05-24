-- ============================================================
-- Recalcula puntos de TODOS los pronósticos de partidos finalizados
-- Respeta el sistema de puntos por fase:
--   grupos:       exacto=5,  resultado=2
--   r32:          exacto=8,  resultado=3
--   r16:          exacto=12, resultado=5
--   cuartos:      exacto=17, resultado=7
--   semis:        exacto=25, resultado=10
--   tercer_lugar: exacto=25, resultado=10
--   final:        exacto=35, resultado=15
-- Ejecutar en: Supabase > SQL Editor
-- ⚠️ Usar solo como fallback; el botón "Recalcular" en Admin es más preciso.
-- ============================================================

UPDATE pronosticos pr
SET
  puntos = CASE pa.fase

    WHEN 'grupos' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 5
        WHEN SIGN(pr.goles_local - pr.goles_visita) = SIGN(pa.goles_local - pa.goles_visita) THEN 2
        ELSE 0
      END

    WHEN 'r32' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 8
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 3
        ELSE 0
      END

    WHEN 'r16' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 12
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 5
        ELSE 0
      END

    WHEN 'cuartos' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 17
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 7
        ELSE 0
      END

    WHEN 'semis' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 25
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 10
        ELSE 0
      END

    WHEN 'tercer_lugar' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 25
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 10
        ELSE 0
      END

    WHEN 'final' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita
          AND pa.goles_local <> pa.goles_visita THEN 35
        WHEN (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 15
        ELSE 0
      END

    ELSE 0
  END,
  calculado = true
FROM partidos pa
WHERE pr.partido_id = pa.id
  AND pa.estado     = 'finalizado'
  AND pa.goles_local  IS NOT NULL
  AND pa.goles_visita IS NOT NULL;

-- ============================================================
-- Premiar al campeón (ejecutar solo cuando la Final esté finalizada)
-- Reemplaza 'Equipo Campeón' con el nombre exacto del ganador.
-- ============================================================
-- UPDATE pronostico_campeon SET puntos = 20 WHERE equipo = 'Equipo Campeón';
-- UPDATE pronostico_campeon SET puntos = 0  WHERE equipo <> 'Equipo Campeón';
