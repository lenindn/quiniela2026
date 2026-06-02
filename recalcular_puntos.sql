-- ============================================================
-- Recalcula puntos de TODOS los pronósticos de partidos finalizados
-- Sistema de puntos por fase:
--   grupos:       exacto=5,  resultado=2
--   r32:          exacto=8,  resultado=3
--   r16:          exacto=12, resultado=5
--   cuartos:      exacto=17, resultado=7
--   semis:        exacto=25, resultado=10
--   tercer_lugar: exacto=25, resultado=10
--   final:        exacto=35, resultado=15
--
-- REGLA UNIFICADA (reglamento oficial):
--   Todas las fases se calculan IGUAL usando el marcador de 90 minutos.
--   La prórroga y los penales NO cuentan. Si un partido se define en
--   penales, el resultado oficial es EMPATE (mismo trato que grupos).
--   El campo avanza_local solo sirve para el bracket, NO para puntos.
--   - Marcador exacto  -> puntos de exacto
--   - Misma dirección (gana local / gana visita / empate) -> puntos de resultado
-- ============================================================

UPDATE pronosticos pr
SET
  puntos = CASE
    WHEN pr.goles_local = pa.goles_local AND pr.goles_visita = pa.goles_visita THEN
      CASE pa.fase
        WHEN 'grupos'       THEN 5
        WHEN 'r32'          THEN 8
        WHEN 'r16'          THEN 12
        WHEN 'cuartos'      THEN 17
        WHEN 'semis'        THEN 25
        WHEN 'tercer_lugar' THEN 25
        WHEN 'final'        THEN 35
        ELSE 0
      END
    WHEN SIGN(pr.goles_local - pr.goles_visita) = SIGN(pa.goles_local - pa.goles_visita) THEN
      CASE pa.fase
        WHEN 'grupos'       THEN 2
        WHEN 'r32'          THEN 3
        WHEN 'r16'          THEN 5
        WHEN 'cuartos'      THEN 7
        WHEN 'semis'        THEN 10
        WHEN 'tercer_lugar' THEN 10
        WHEN 'final'        THEN 15
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