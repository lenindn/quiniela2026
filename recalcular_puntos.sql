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
--
-- REGLA PENALES (fases KO):
--   Exacto  = marcador 90 exacto (incluye empates que van a penales)
--   Resultado = empate real + empate pred. (fue a penales)
--           O no-empate real + ganador correcto (avanza_local)
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
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 8
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 3
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 3
        ELSE 0
      END

    WHEN 'r16' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 12
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 5
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 5
        ELSE 0
      END

    WHEN 'cuartos' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 17
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 7
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 7
        ELSE 0
      END

    WHEN 'semis' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 25
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 10
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 10
        ELSE 0
      END

    WHEN 'tercer_lugar' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 25
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 10
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 10
        ELSE 0
      END

    WHEN 'final' THEN
      CASE
        WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN 35
        WHEN pa.goles_local = pa.goles_visita AND pr.goles_local = pr.goles_visita THEN 15
        WHEN pa.goles_local <> pa.goles_visita AND (pr.goles_local > pr.goles_visita) = pa.avanza_local THEN 15
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