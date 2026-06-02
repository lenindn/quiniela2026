-- ============================================================
-- LIMPIAR DATOS DE PRUEBA — Quiniela Mundial 2026
-- ============================================================
-- ⚠️  EJECUTAR SOLO AL TERMINAR LA FASE DE PRUEBA, ANTES DE LANZAR.
-- ⚠️  NO ejecutar durante las pruebas. Borra pronósticos, resultados
--     y (opcionalmente) participantes de prueba.
--
-- NO toca la estructura: tablas, columnas, RPCs ni config se mantienen.
-- Ejecutar en: Supabase > SQL Editor
-- Hacer un backup/export antes por seguridad.
-- ============================================================

-- ── PASO 1: Borrar todos los pronósticos ──
DELETE FROM pronosticos;

-- ── PASO 2: Borrar registro de actividad ──
DELETE FROM actividad;

-- ── PASO 3: Resetear resultados de TODOS los partidos a pendiente ──
--    (mantiene los partidos pero limpia marcadores/estado)
UPDATE partidos
SET goles_local    = NULL,
    goles_visita   = NULL,
    avanza_local   = NULL,
    penales_local  = NULL,
    penales_visita = NULL,
    estado         = 'pendiente',
    fuente         = 'pendiente';

-- ── PASO 4 (OPCIONAL): Borrar partidos de fases eliminatorias ──
--    Úsalo si los cruces R32/octavos/etc. eran de prueba y quieres
--    que se generen de nuevo durante el torneo real.
--    La fase de grupos NO se borra (son los 72 partidos oficiales).
-- DELETE FROM partidos WHERE fase <> 'grupos';

-- ── PASO 5 (OPCIONAL): Borrar participantes de prueba ──
--    CUIDADO: esto elimina TODOS los participantes. Úsalo solo si
--    quieres empezar de cero con registros reales.
--    Si quieres conservar algunos, bórralos por grupo o por whatsapp.
-- DELETE FROM participantes;
--    O borrar solo de un grupo de prueba específico:
-- DELETE FROM participantes WHERE grupo_quiniela = (
--   SELECT id FROM grupos_quiniela WHERE slug = 'grupo-prueba'
-- );

-- ── PASO 6 (OPCIONAL): Borrar grupos de prueba ──
-- DELETE FROM grupos_quiniela WHERE slug IN ('grupo-prueba', 'familia-pedorra');

-- ============================================================
-- Verificación post-limpieza
-- ============================================================
-- SELECT count(*) AS pronosticos FROM pronosticos;
-- SELECT count(*) AS actividad   FROM actividad;
-- SELECT fase, count(*) FROM partidos GROUP BY fase ORDER BY fase;
-- SELECT count(*) AS participantes FROM participantes;
