-- ============================================================
-- FIFA MUNDIAL 2026 - Calendario Oficial (VERSIÓN SEGURA)
-- Preserva pronósticos existentes.
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- PASO 1: Agregar columnas (no afecta datos existentes)
ALTER TABLE partidos ADD COLUMN IF NOT EXISTS estadio TEXT;
ALTER TABLE partidos ADD COLUMN IF NOT EXISTS ciudad  TEXT;

-- PASO 2: Agregar restricción única para evitar duplicados
-- (si ya existe la constraint, ignorar el error)
ALTER TABLE partidos
  ADD CONSTRAINT partidos_equipos_grupo_uq
  UNIQUE (equipo_local, equipo_visita, grupo);

-- ============================================================
-- PASO 3: UPSERT — actualiza si el partido ya existe,
-- inserta si no existe. NO toca goles ni estado.
-- ============================================================
INSERT INTO partidos
  (numero, fase, grupo, equipo_local, equipo_visita, fecha_partido, estadio, ciudad, estado)
VALUES

-- GRUPO A
(1, 'grupos','A','México',        'Sudáfrica',    '2026-06-11T19:00:00Z','Estadio Azteca',         'Ciudad de México','pendiente'),
(2, 'grupos','A','Corea del Sur', 'Chequia',      '2026-06-12T02:00:00Z','Estadio Akron',          'Guadalajara',     'pendiente'),
(3, 'grupos','A','Chequia',       'Sudáfrica',    '2026-06-18T16:00:00Z','Mercedes-Benz Stadium',  'Atlanta',         'pendiente'),
(4, 'grupos','A','México',        'Corea del Sur','2026-06-19T01:00:00Z','Estadio Akron',          'Guadalajara',     'pendiente'),
(5, 'grupos','A','Chequia',       'México',       '2026-06-25T01:00:00Z','Estadio Azteca',         'Ciudad de México','pendiente'),
(6, 'grupos','A','Sudáfrica',     'Corea del Sur','2026-06-25T01:00:00Z','Estadio BBVA',           'Monterrey',       'pendiente'),

-- GRUPO B
(7, 'grupos','B','Canadá',              'Bosnia y Herzegovina','2026-06-12T19:00:00Z','BMO Field',       'Toronto',       'pendiente'),
(8, 'grupos','B','Qatar',               'Suiza',               '2026-06-13T19:00:00Z','Levi''s Stadium', 'San Francisco', 'pendiente'),
(9, 'grupos','B','Suiza',               'Bosnia y Herzegovina','2026-06-18T19:00:00Z','SoFi Stadium',    'Los Ángeles',   'pendiente'),
(10,'grupos','B','Canadá',              'Qatar',               '2026-06-18T22:00:00Z','BC Place',        'Vancouver',     'pendiente'),
(11,'grupos','B','Suiza',               'Canadá',              '2026-06-24T19:00:00Z','BC Place',        'Vancouver',     'pendiente'),
(12,'grupos','B','Bosnia y Herzegovina','Qatar',               '2026-06-24T19:00:00Z','Lumen Field',     'Seattle',       'pendiente'),

-- GRUPO C
(13,'grupos','C','Brasil',    'Marruecos','2026-06-13T22:00:00Z','MetLife Stadium',         'Nueva York',   'pendiente'),
(14,'grupos','C','Haití',     'Escocia',  '2026-06-14T01:00:00Z','Gillette Stadium',        'Boston',       'pendiente'),
(15,'grupos','C','Escocia',   'Marruecos','2026-06-19T22:00:00Z','Gillette Stadium',        'Boston',       'pendiente'),
(16,'grupos','C','Brasil',    'Haití',    '2026-06-20T00:30:00Z','Lincoln Financial Field', 'Philadelphia', 'pendiente'),
(17,'grupos','C','Marruecos', 'Haití',    '2026-06-24T22:00:00Z','Mercedes-Benz Stadium',  'Atlanta',      'pendiente'),
(18,'grupos','C','Escocia',   'Brasil',   '2026-06-24T22:00:00Z','Hard Rock Stadium',       'Miami',        'pendiente'),

-- GRUPO D
(19,'grupos','D','Estados Unidos','Paraguay',      '2026-06-13T01:00:00Z','SoFi Stadium',    'Los Ángeles',  'pendiente'),
(20,'grupos','D','Australia',     'Turquía',       '2026-06-14T04:00:00Z','BC Place',        'Vancouver',    'pendiente'),
(21,'grupos','D','Estados Unidos','Australia',     '2026-06-19T19:00:00Z','Lumen Field',     'Seattle',      'pendiente'),
(22,'grupos','D','Turquía',       'Paraguay',      '2026-06-20T03:00:00Z','Levi''s Stadium', 'San Francisco','pendiente'),
(23,'grupos','D','Turquía',       'Estados Unidos','2026-06-26T02:00:00Z','SoFi Stadium',    'Los Ángeles',  'pendiente'),
(24,'grupos','D','Paraguay',      'Australia',     '2026-06-26T02:00:00Z','Levi''s Stadium', 'San Francisco','pendiente'),

-- GRUPO E
(25,'grupos','E','Alemania',        'Curazao',        '2026-06-14T17:00:00Z','NRG Stadium',             'Houston',      'pendiente'),
(26,'grupos','E','Costa de Marfil', 'Ecuador',        '2026-06-14T23:00:00Z','Lincoln Financial Field', 'Philadelphia', 'pendiente'),
(27,'grupos','E','Alemania',        'Costa de Marfil','2026-06-20T20:00:00Z','BMO Field',               'Toronto',      'pendiente'),
(28,'grupos','E','Ecuador',         'Curazao',        '2026-06-21T03:00:00Z','Arrowhead Stadium',       'Kansas City',  'pendiente'),
(29,'grupos','E','Ecuador',         'Alemania',       '2026-06-25T20:00:00Z','MetLife Stadium',         'Nueva York',   'pendiente'),
(30,'grupos','E','Curazao',         'Costa de Marfil','2026-06-25T20:00:00Z','Lincoln Financial Field', 'Philadelphia', 'pendiente'),

-- GRUPO F
(31,'grupos','F','Países Bajos','Japón',        '2026-06-14T20:00:00Z','AT&T Stadium',     'Dallas',      'pendiente'),
(32,'grupos','F','Suecia',      'Túnez',        '2026-06-15T02:00:00Z','Estadio BBVA',    'Monterrey',   'pendiente'),
(33,'grupos','F','Países Bajos','Suecia',       '2026-06-20T17:00:00Z','NRG Stadium',     'Houston',     'pendiente'),
(34,'grupos','F','Túnez',       'Japón',        '2026-06-21T04:00:00Z','Estadio BBVA',    'Monterrey',   'pendiente'),
(35,'grupos','F','Japón',       'Suecia',       '2026-06-25T23:00:00Z','AT&T Stadium',    'Dallas',      'pendiente'),
(36,'grupos','F','Túnez',       'Países Bajos', '2026-06-25T23:00:00Z','Arrowhead Stadium','Kansas City', 'pendiente'),

-- GRUPO G
(37,'grupos','G','Bélgica',      'Egipto',       '2026-06-15T19:00:00Z','BC Place',     'Vancouver',  'pendiente'),
(38,'grupos','G','Irán',         'Nueva Zelanda','2026-06-16T01:00:00Z','SoFi Stadium', 'Los Ángeles','pendiente'),
(39,'grupos','G','Bélgica',      'Irán',         '2026-06-21T19:00:00Z','SoFi Stadium', 'Los Ángeles','pendiente'),
(40,'grupos','G','Nueva Zelanda','Egipto',       '2026-06-22T01:00:00Z','BC Place',     'Vancouver',  'pendiente'),
(41,'grupos','G','Egipto',       'Irán',         '2026-06-27T03:00:00Z','Lumen Field',  'Seattle',    'pendiente'),
(42,'grupos','G','Nueva Zelanda','Bélgica',      '2026-06-27T03:00:00Z','BC Place',     'Vancouver',  'pendiente'),

-- GRUPO H
(43,'grupos','H','España',        'Cabo Verde',    '2026-06-15T16:00:00Z','Mercedes-Benz Stadium','Atlanta',     'pendiente'),
(44,'grupos','H','Arabia Saudita','Uruguay',       '2026-06-15T22:00:00Z','Hard Rock Stadium',    'Miami',       'pendiente'),
(45,'grupos','H','España',        'Arabia Saudita','2026-06-21T16:00:00Z','Mercedes-Benz Stadium','Atlanta',     'pendiente'),
(46,'grupos','H','Uruguay',       'Cabo Verde',    '2026-06-21T22:00:00Z','Hard Rock Stadium',    'Miami',       'pendiente'),
(47,'grupos','H','Cabo Verde',    'Arabia Saudita','2026-06-27T00:00:00Z','NRG Stadium',          'Houston',     'pendiente'),
(48,'grupos','H','Uruguay',       'España',        '2026-06-27T00:00:00Z','Estadio Akron',        'Guadalajara', 'pendiente'),

-- GRUPO I
(49,'grupos','I','Francia', 'Senegal','2026-06-16T19:00:00Z','MetLife Stadium',        'Nueva York',  'pendiente'),
(50,'grupos','I','Irak',    'Noruega','2026-06-16T22:00:00Z','Gillette Stadium',       'Boston',      'pendiente'),
(51,'grupos','I','Francia', 'Irak',   '2026-06-22T21:00:00Z','Lincoln Financial Field','Philadelphia','pendiente'),
(52,'grupos','I','Noruega', 'Senegal','2026-06-23T00:00:00Z','MetLife Stadium',        'Nueva York',  'pendiente'),
(53,'grupos','I','Noruega', 'Francia','2026-06-26T19:00:00Z','Gillette Stadium',       'Boston',      'pendiente'),
(54,'grupos','I','Senegal', 'Irak',   '2026-06-26T19:00:00Z','BMO Field',             'Toronto',     'pendiente'),

-- GRUPO J
(55,'grupos','J','Argentina','Argelia',   '2026-06-17T01:00:00Z','Arrowhead Stadium','Kansas City',  'pendiente'),
(56,'grupos','J','Austria',  'Jordania',  '2026-06-17T04:00:00Z','Levi''s Stadium',  'San Francisco','pendiente'),
(57,'grupos','J','Argentina','Austria',   '2026-06-22T17:00:00Z','AT&T Stadium',     'Dallas',       'pendiente'),
(58,'grupos','J','Jordania', 'Argelia',   '2026-06-23T03:00:00Z','Levi''s Stadium',  'San Francisco','pendiente'),
(59,'grupos','J','Argelia',  'Austria',   '2026-06-28T02:00:00Z','Arrowhead Stadium','Kansas City',  'pendiente'),
(60,'grupos','J','Jordania', 'Argentina', '2026-06-28T02:00:00Z','AT&T Stadium',     'Dallas',       'pendiente'),

-- GRUPO K
(61,'grupos','K','Portugal',   'RD Congo',  '2026-06-17T17:00:00Z','NRG Stadium',          'Houston',         'pendiente'),
(62,'grupos','K','Uzbekistán', 'Colombia',  '2026-06-18T02:00:00Z','Estadio Azteca',       'Ciudad de México','pendiente'),
(63,'grupos','K','Portugal',   'Uzbekistán','2026-06-23T17:00:00Z','NRG Stadium',          'Houston',         'pendiente'),
(64,'grupos','K','Colombia',   'RD Congo',  '2026-06-24T02:00:00Z','Estadio Akron',        'Guadalajara',     'pendiente'),
(65,'grupos','K','Colombia',   'Portugal',  '2026-06-27T23:30:00Z','Hard Rock Stadium',    'Miami',           'pendiente'),
(66,'grupos','K','RD Congo',   'Uzbekistán','2026-06-27T23:30:00Z','Mercedes-Benz Stadium','Atlanta',         'pendiente'),

-- GRUPO L
(67,'grupos','L','Inglaterra','Croacia',    '2026-06-17T20:00:00Z','AT&T Stadium',           'Dallas',       'pendiente'),
(68,'grupos','L','Ghana',     'Panamá',    '2026-06-17T23:00:00Z','BMO Field',              'Toronto',      'pendiente'),
(69,'grupos','L','Inglaterra','Ghana',     '2026-06-23T20:00:00Z','Gillette Stadium',       'Boston',       'pendiente'),
(70,'grupos','L','Panamá',    'Croacia',   '2026-06-23T23:00:00Z','BMO Field',              'Toronto',      'pendiente'),
(71,'grupos','L','Panamá',    'Inglaterra','2026-06-27T21:00:00Z','MetLife Stadium',        'Nueva York',   'pendiente'),
(72,'grupos','L','Croacia',   'Ghana',     '2026-06-27T21:00:00Z','Lincoln Financial Field','Philadelphia', 'pendiente')

ON CONFLICT (equipo_local, equipo_visita, grupo) DO UPDATE SET
  numero        = EXCLUDED.numero,
  fase          = EXCLUDED.fase,
  fecha_partido = EXCLUDED.fecha_partido,
  estadio       = EXCLUDED.estadio,
  ciudad        = EXCLUDED.ciudad;
-- ✅ NO actualiza: goles_local, goles_visita, avanza_local, estado, fuente
-- Los pronósticos existentes quedan intactos.
