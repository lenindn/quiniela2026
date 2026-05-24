-- ============================================================
-- Limpia partidos duplicados donde el orden local/visita
-- del dato de prueba está invertido vs el calendario oficial.
-- Migra los pronósticos al partido oficial y elimina el viejo.
-- ============================================================

DO $$
DECLARE
  viejo   RECORD;
  nuevo_id INT;
BEGIN
  -- Buscar pares donde existen ambas versiones (A vs B y B vs A)
  -- "viejo" = el que tiene estadio NULL (dato de prueba sin fecha oficial)
  FOR viejo IN
    SELECT p1.id, p1.equipo_local, p1.equipo_visita, p1.grupo
    FROM partidos p1
    JOIN partidos p2
      ON  p2.equipo_local  = p1.equipo_visita
      AND p2.equipo_visita = p1.equipo_local
      AND p2.grupo         = p1.grupo
      AND p2.id            <> p1.id
    WHERE p1.estadio IS NULL   -- el de prueba no tiene estadio
  LOOP
    -- Obtener el id del partido oficial (el que sí tiene estadio)
    SELECT id INTO nuevo_id
    FROM partidos
    WHERE equipo_local  = viejo.equipo_visita
      AND equipo_visita = viejo.equipo_local
      AND grupo         = viejo.grupo
      AND estadio IS NOT NULL;

    IF nuevo_id IS NOT NULL THEN
      -- Reasignar pronósticos al partido oficial
      -- (invertir goles porque los equipos están al revés)
      UPDATE pronosticos
      SET partido_id   = nuevo_id,
          goles_local  = goles_visita,
          goles_visita = goles_local
      WHERE partido_id = viejo.id;

      -- Eliminar el partido duplicado de prueba
      DELETE FROM partidos WHERE id = viejo.id;

      RAISE NOTICE 'Corregido: % vs % Grupo %',
        viejo.equipo_local, viejo.equipo_visita, viejo.grupo;
    END IF;
  END LOOP;
END $$;
