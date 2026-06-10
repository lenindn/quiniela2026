-- ============================================================
-- Genera el mensaje de WhatsApp con el estado actual de picks
-- de un grupo, listo para copiar y pegar.
-- Ejecutar en: Supabase > SQL Editor
-- Cambiar 'san-jose-89' si usas esta consulta para otro grupo.
-- ============================================================

WITH grp AS (
  SELECT id, nombre FROM grupos_quiniela
  WHERE slug = 'san-jose-89' OR id = 'san-jose-89' LIMIT 1
),
orden_fases(fase, orden, label) AS (
  VALUES ('grupos',1,'Fase de Grupos'), ('r32',2,'Ronda de 32'), ('r16',3,'Octavos'),
         ('cuartos',4,'Cuartos de Final'), ('semis',5,'Semifinales'),
         ('tercer_lugar',6,'Tercer Puesto'), ('final',7,'Gran Final')
),
fase_actual AS (
  SELECT f.id, f.fecha_cierre, o.label
  FROM fases f
  JOIN orden_fases o ON o.fase = f.id
  WHERE f.abierta = true AND (f.fecha_cierre IS NULL OR f.fecha_cierre > now())
  ORDER BY o.orden LIMIT 1
),
total_partidos AS (
  SELECT count(*) AS total FROM partidos WHERE fase = (SELECT id FROM fase_actual)
),
participantes_grupo AS (
  SELECT id FROM participantes WHERE grupo_quiniela = (SELECT id FROM grp)
),
picks AS (
  SELECT pr.participante_id, count(DISTINCT pr.partido_id) AS n
  FROM pronosticos pr JOIN partidos pa ON pa.id = pr.partido_id
  WHERE pa.fase = (SELECT id FROM fase_actual)
  GROUP BY pr.participante_id
),
contadores AS (
  SELECT
    (SELECT count(*) FROM participantes_grupo) AS inscritos,
    count(*) FILTER (WHERE COALESCE(p.n,0) >= (SELECT total FROM total_partidos)) AS listos,
    count(*) FILTER (WHERE COALESCE(p.n,0) > 0 AND COALESCE(p.n,0) < (SELECT total FROM total_partidos)) AS incompletos,
    count(*) FILTER (WHERE COALESCE(p.n,0) = 0) AS sin_picks
  FROM participantes_grupo pg
  LEFT JOIN picks p ON p.participante_id = pg.id
)
SELECT
  '📢 *¡Hola Quiniela ' || (SELECT nombre FROM grp) || '!* ⚽🏆' || E'\n\n'
  || 'Antes que nada, *¡muchas gracias a todos los que ya se inscribieron y llenaron sus pronósticos!* 🙌 El entusiasmo se siente, y eso es lo que hace divertida esta quiniela.' || E'\n\n'
  || '📊 *Estado actual de la ' || (SELECT label FROM fase_actual) || ':*' || E'\n'
  || '- ✅ Inscritos: *' || c.inscritos || '*' || E'\n'
  || '- 🟢 Listos (picks completos): *' || c.listos || '*' || E'\n'
  || '- 🟡 Incompletos: *' || c.incompletos || '*' || E'\n'
  || '- 🔴 Sin picks aún: *' || c.sin_picks || '*' || E'\n\n'
  || '⏰ *Recordatorio importante:*' || E'\n'
  || 'El cierre de la ' || (SELECT label FROM fase_actual) || ' es el '
  || to_char((SELECT fecha_cierre FROM fase_actual) AT TIME ZONE 'America/Mexico_City', 'DD/MM') || ' a las '
  || to_char((SELECT fecha_cierre FROM fase_actual) AT TIME ZONE 'Europe/Madrid', 'HH24:MI') || ' (hora España) / '
  || to_char((SELECT fecha_cierre FROM fase_actual) AT TIME ZONE 'America/Mexico_City', 'HH24:MI') || ' (hora México).' || E'\n\n'
  || 'Si aún no te has registrado o no completaste tus pronósticos, ¡este es el momento! Una vez cerrada la fase, *no se podrán modificar ni agregar picks*. 🔒' || E'\n\n'
  || '👉 Entra aquí: https://lenindn.github.io/quiniela2026/v2.html?g=san-jose-89' || E'\n\n'
  || '¡Mucha suerte a todos y que gane el mejor pronosticador! 🍀⚽'
  AS mensaje_whatsapp
FROM contadores c;
