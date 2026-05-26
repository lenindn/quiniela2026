-- ============================================================
-- Migración de participantes sin grupo asignado (grupo_quiniela = NULL)
-- Se usa cuando la quiniela corrió sin soporte multi-grupo y luego
-- se ejecutó multigrupo.sql.
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- 1. VER cuántos participantes tienen grupo_quiniela = NULL
SELECT id, nombre, whatsapp, grupo_quiniela
FROM participantes
WHERE grupo_quiniela IS NULL
ORDER BY id;

-- ============================================================
-- 2. ASIGNAR todos los participantes sin grupo a UN grupo específico
--    ⚠️ Reemplaza el número 10 con el ID real de tu grupo.
--    Para conocer los IDs de tus grupos: SELECT id, nombre FROM grupos_quiniela;
-- ============================================================
-- UPDATE participantes
-- SET grupo_quiniela = 10    -- ← cambia 10 por el ID real
-- WHERE grupo_quiniela IS NULL;

-- ============================================================
-- 3. Si tienes VARIOS grupos y quieres asignar participantes específicos:
-- ============================================================
-- UPDATE participantes SET grupo_quiniela = 10 WHERE whatsapp IN ('521234567890', '584141234567');
-- UPDATE participantes SET grupo_quiniela = 20 WHERE whatsapp IN ('521112223333');

-- ============================================================
-- 4. Verificar resultado final
-- ============================================================
-- SELECT p.id, p.nombre, p.whatsapp, gq.nombre AS grupo
-- FROM participantes p
-- LEFT JOIN grupos_quiniela gq ON gq.id = p.grupo_quiniela
-- ORDER BY gq.nombre, p.nombre;
