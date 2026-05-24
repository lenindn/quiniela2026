-- ============================================================
-- QUINIELA MUNDIAL 2026 — Schema Supabase
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

-- TABLAS
CREATE TABLE IF NOT EXISTS participantes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre TEXT NOT NULL,
    whatsapp TEXT NOT NULL UNIQUE,
    fecha_registro TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS partidos (
    id SERIAL PRIMARY KEY,
    numero INTEGER,
    fase TEXT NOT NULL CHECK (fase IN ('grupos','r32','r16','cuartos','semis','tercer_lugar','final')),
    grupo TEXT,
    equipo_local TEXT NOT NULL,
    equipo_visita TEXT NOT NULL,
    fecha_partido TIMESTAMPTZ,
    sede TEXT,
    goles_local INTEGER,
    goles_visita INTEGER,
    avanza_local BOOLEAN,  -- solo eliminatorias: true=local avanzó
    estado TEXT DEFAULT 'pendiente' CHECK (estado IN ('pendiente','en_curso','finalizado')),
    fuente TEXT DEFAULT 'pendiente',
    api_id TEXT
);

CREATE TABLE IF NOT EXISTS pronosticos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    participante_id UUID REFERENCES participantes(id) ON DELETE CASCADE,
    partido_id INTEGER REFERENCES partidos(id),
    goles_local INTEGER NOT NULL CHECK (goles_local >= 0),
    goles_visita INTEGER NOT NULL CHECK (goles_visita >= 0),
    puntos INTEGER DEFAULT 0,
    calculado BOOLEAN DEFAULT false,
    fecha_registro TIMESTAMPTZ DEFAULT now(),
    UNIQUE(participante_id, partido_id)
);

CREATE TABLE IF NOT EXISTS pronostico_campeon (
    participante_id UUID REFERENCES participantes(id) ON DELETE CASCADE PRIMARY KEY,
    equipo TEXT NOT NULL,
    puntos INTEGER DEFAULT 0,
    fecha_registro TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fases (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    abierta BOOLEAN DEFAULT false,
    fecha_cierre TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS config (
    clave TEXT PRIMARY KEY,
    valor TEXT
);

-- ROW LEVEL SECURITY (permisivo para quiniela de amigos)
ALTER TABLE participantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE partidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pronosticos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pronostico_campeon ENABLE ROW LEVEL SECURITY;
ALTER TABLE fases ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_participantes"  ON participantes FOR SELECT USING (true);
CREATE POLICY "insert_participantes" ON participantes FOR INSERT WITH CHECK (true);

CREATE POLICY "read_partidos"   ON partidos FOR SELECT USING (true);
CREATE POLICY "update_partidos" ON partidos FOR UPDATE USING (true);
CREATE POLICY "insert_partidos" ON partidos FOR INSERT WITH CHECK (true);

CREATE POLICY "read_pronosticos"   ON pronosticos FOR SELECT USING (true);
CREATE POLICY "insert_pronosticos" ON pronosticos FOR INSERT WITH CHECK (true);
CREATE POLICY "update_pronosticos" ON pronosticos FOR UPDATE USING (true);

CREATE POLICY "read_campeon"   ON pronostico_campeon FOR SELECT USING (true);
CREATE POLICY "insert_campeon" ON pronostico_campeon FOR INSERT WITH CHECK (true);
CREATE POLICY "update_campeon" ON pronostico_campeon FOR UPDATE USING (true);

CREATE POLICY "read_fases"   ON fases FOR SELECT USING (true);
CREATE POLICY "update_fases" ON fases FOR UPDATE USING (true);

CREATE POLICY "read_config"   ON config FOR SELECT USING (true);
CREATE POLICY "update_config" ON config FOR UPDATE USING (true);

-- DATOS INICIALES
INSERT INTO fases (id, nombre, abierta, fecha_cierre) VALUES
    ('grupos',       'Fase de Grupos',   true,  '2026-06-11 22:00:00+00'),
    ('r32',          'Ronda de 32',      false, null),
    ('r16',          'Octavos de Final', false, null),
    ('cuartos',      'Cuartos de Final', false, null),
    ('semis',        'Semifinales',      false, null),
    ('tercer_lugar', 'Tercer Lugar',     false, null),
    ('final',        'Final',            false, null)
ON CONFLICT (id) DO NOTHING;

INSERT INTO config (clave, valor) VALUES
    ('admin_pin',      '2026'),
    ('torneo_nombre',  'Mundial FIFA 2026'),
    ('campeon_real',   '')
ON CONFLICT (clave) DO NOTHING;

-- FASE DE GRUPOS: 72 PARTIDOS
-- Grupo A: México, Sudáfrica, Corea del Sur, Chequia
INSERT INTO partidos (numero, fase, grupo, equipo_local, equipo_visita) VALUES
(1,  'grupos','A','México',           'Sudáfrica'),
(2,  'grupos','A','Corea del Sur',    'Chequia'),
(3,  'grupos','A','México',           'Corea del Sur'),
(4,  'grupos','A','Chequia',          'Sudáfrica'),
(5,  'grupos','A','México',           'Chequia'),
(6,  'grupos','A','Sudáfrica',        'Corea del Sur'),
-- Grupo B: Canadá, Bosnia y Herzegovina, Qatar, Suiza
(7,  'grupos','B','Canadá',           'Bosnia y Herzegovina'),
(8,  'grupos','B','Qatar',            'Suiza'),
(9,  'grupos','B','Canadá',           'Qatar'),
(10, 'grupos','B','Suiza',            'Bosnia y Herzegovina'),
(11, 'grupos','B','Canadá',           'Suiza'),
(12, 'grupos','B','Bosnia y Herzegovina','Qatar'),
-- Grupo C: Brasil, Marruecos, Haití, Escocia
(13, 'grupos','C','Brasil',           'Marruecos'),
(14, 'grupos','C','Haití',            'Escocia'),
(15, 'grupos','C','Brasil',           'Haití'),
(16, 'grupos','C','Escocia',          'Marruecos'),
(17, 'grupos','C','Brasil',           'Escocia'),
(18, 'grupos','C','Marruecos',        'Haití'),
-- Grupo D: Estados Unidos, Paraguay, Australia, Turquía
(19, 'grupos','D','Estados Unidos',   'Paraguay'),
(20, 'grupos','D','Australia',        'Turquía'),
(21, 'grupos','D','Estados Unidos',   'Australia'),
(22, 'grupos','D','Turquía',          'Paraguay'),
(23, 'grupos','D','Estados Unidos',   'Turquía'),
(24, 'grupos','D','Paraguay',         'Australia'),
-- Grupo E: Alemania, Curazao, Costa de Marfil, Ecuador
(25, 'grupos','E','Alemania',         'Curazao'),
(26, 'grupos','E','Costa de Marfil',  'Ecuador'),
(27, 'grupos','E','Alemania',         'Costa de Marfil'),
(28, 'grupos','E','Ecuador',          'Curazao'),
(29, 'grupos','E','Alemania',         'Ecuador'),
(30, 'grupos','E','Curazao',          'Costa de Marfil'),
-- Grupo F: Países Bajos, Japón, Suecia, Túnez
(31, 'grupos','F','Países Bajos',     'Japón'),
(32, 'grupos','F','Suecia',           'Túnez'),
(33, 'grupos','F','Países Bajos',     'Suecia'),
(34, 'grupos','F','Túnez',            'Japón'),
(35, 'grupos','F','Países Bajos',     'Túnez'),
(36, 'grupos','F','Japón',            'Suecia'),
-- Grupo G: Bélgica, Egipto, Irán, Nueva Zelanda
(37, 'grupos','G','Bélgica',          'Egipto'),
(38, 'grupos','G','Irán',             'Nueva Zelanda'),
(39, 'grupos','G','Bélgica',          'Irán'),
(40, 'grupos','G','Nueva Zelanda',    'Egipto'),
(41, 'grupos','G','Bélgica',          'Nueva Zelanda'),
(42, 'grupos','G','Egipto',           'Irán'),
-- Grupo H: España, Cabo Verde, Arabia Saudita, Uruguay
(43, 'grupos','H','España',           'Cabo Verde'),
(44, 'grupos','H','Arabia Saudita',   'Uruguay'),
(45, 'grupos','H','España',           'Arabia Saudita'),
(46, 'grupos','H','Uruguay',          'Cabo Verde'),
(47, 'grupos','H','España',           'Uruguay'),
(48, 'grupos','H','Cabo Verde',       'Arabia Saudita'),
-- Grupo I: Francia, Senegal, Irak, Noruega
(49, 'grupos','I','Francia',          'Senegal'),
(50, 'grupos','I','Irak',             'Noruega'),
(51, 'grupos','I','Francia',          'Irak'),
(52, 'grupos','I','Noruega',          'Senegal'),
(53, 'grupos','I','Francia',          'Noruega'),
(54, 'grupos','I','Senegal',          'Irak'),
-- Grupo J: Argentina, Argelia, Austria, Jordania
(55, 'grupos','J','Argentina',        'Argelia'),
(56, 'grupos','J','Austria',          'Jordania'),
(57, 'grupos','J','Argentina',        'Austria'),
(58, 'grupos','J','Jordania',         'Argelia'),
(59, 'grupos','J','Argentina',        'Jordania'),
(60, 'grupos','J','Argelia',          'Austria'),
-- Grupo K: Portugal, RD Congo, Uzbekistán, Colombia
(61, 'grupos','K','Portugal',         'RD Congo'),
(62, 'grupos','K','Uzbekistán',       'Colombia'),
(63, 'grupos','K','Portugal',         'Uzbekistán'),
(64, 'grupos','K','Colombia',         'RD Congo'),
(65, 'grupos','K','Portugal',         'Colombia'),
(66, 'grupos','K','RD Congo',         'Uzbekistán'),
-- Grupo L: Inglaterra, Croacia, Ghana, Panamá
(67, 'grupos','L','Inglaterra',       'Croacia'),
(68, 'grupos','L','Ghana',            'Panamá'),
(69, 'grupos','L','Inglaterra',       'Ghana'),
(70, 'grupos','L','Panamá',           'Croacia'),
(71, 'grupos','L','Inglaterra',       'Panamá'),
(72, 'grupos','L','Croacia',          'Ghana');
