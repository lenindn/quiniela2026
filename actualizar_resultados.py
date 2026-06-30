"""
Quiniela Mundial 2026 — Script de actualización automática de resultados
Fuente: football-data.org (API gratuita)
Ejecutar: python actualizar_resultados.py
Programar: GitHub Actions cada 2 horas (ver .github/workflows/actualizar.yml)
"""

import os
import sys
import json
import requests
from datetime import datetime, timezone
from supabase import create_client, Client

# ============================================================
# CONFIGURACIÓN
# ============================================================
SUPABASE_URL         = os.environ.get('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')
FOOTBALL_API_KEY     = os.environ.get('FOOTBALL_API_KEY', '')

FOOTBALL_API_BASE = 'https://api.football-data.org/v4'
COMPETITION_CODE  = 'WC'   # FIFA World Cup en football-data.org
SEASON            = 2026

# Sistema de puntos (debe coincidir con index.html)
PUNTOS = {
    'grupos':       {'resultado': 2,  'exacto': 5 },
    'r32':          {'resultado': 3,  'exacto': 8 },
    'r16':          {'resultado': 5,  'exacto': 12},
    'cuartos':      {'resultado': 7,  'exacto': 17},
    'semis':        {'resultado': 10, 'exacto': 25},
    'tercer_lugar': {'resultado': 10, 'exacto': 25},
    'final':        {'resultado': 15, 'exacto': 35},
}
BONUS_CAMPEON = 20

# Mapeo de estado FIFA → estado interno
STATUS_MAP = {
    'SCHEDULED': 'pendiente',
    'TIMED':     'pendiente',
    'IN_PLAY':   'en_curso',
    'PAUSED':    'en_curso',
    'FINISHED':  'finalizado',
    'SUSPENDED': 'pendiente',
    'POSTPONED': 'pendiente',
    'CANCELLED': 'pendiente',
    'AWARDED':   'finalizado',
}

# Mapeo de fase FIFA → fase interna
# NOTA: GROUP_STAGE se maneja 100% manual (carga de resultados desde admin).
# Los partidos de grupos en la BD no tienen api_id -> si se incluyera aqui,
# el script los insertaria como duplicados en vez de actualizarlos. Por eso
# se omite a proposito; el script solo actua desde 16avos (r32) en adelante.
FASE_MAP = {
    'LAST_32':        'r32',
    'LAST_16':        'r16',
    'QUARTER_FINALS': 'cuartos',
    'SEMI_FINALS':    'semis',
    'THIRD_PLACE':    'tercer_lugar',
    'FINAL':          'final',
}

# Mapeo de nombres de equipo de la API (ingles) -> nombres usados en la BD
# (espanol, deben coincidir EXACTO con equipo_local/equipo_visita de grupos
# para que el bracket y los nombres se vean consistentes en toda la app).
EQUIPO_MAP = {
    'Mexico':                 'México',
    'South Africa':           'Sudáfrica',
    'South Korea':            'Corea del Sur',
    'Czech Republic':         'Chequia',
    'Canada':                 'Canadá',
    'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
    'Bosnia-Herzegovina':     'Bosnia y Herzegovina',  # nombre real devuelto por la API para r32
    'Qatar':                  'Qatar',
    'Switzerland':            'Suiza',
    'Brazil':                 'Brasil',
    'Morocco':                'Marruecos',
    'Haiti':                  'Haití',
    'Scotland':               'Escocia',
    'United States':          'Estados Unidos',
    'Paraguay':               'Paraguay',
    'Australia':              'Australia',
    'Turkey':                 'Turquía',
    'Germany':                'Alemania',
    'Curacao':                'Curazao',
    "Ivory Coast":             'Costa de Marfil',
    "Côte d'Ivoire":           'Costa de Marfil',
    'Ecuador':                'Ecuador',
    'Netherlands':            'Países Bajos',
    'Japan':                  'Japón',
    'Sweden':                 'Suecia',
    'Tunisia':                'Túnez',
    'Belgium':                'Bélgica',
    'Egypt':                  'Egipto',
    'Iran':                   'Irán',
    'New Zealand':             'Nueva Zelanda',
    'Spain':                  'España',
    'Cape Verde':             'Cabo Verde',
    'Cape Verde Islands':     'Cabo Verde',  # nombre alterno devuelto por la API para r32
    'Saudi Arabia':           'Arabia Saudita',
    'Uruguay':                'Uruguay',
    'France':                 'Francia',
    'Senegal':                'Senegal',
    'Iraq':                   'Irak',
    'Norway':                 'Noruega',
    'Argentina':              'Argentina',
    'Algeria':                'Argelia',
    'Austria':                'Austria',
    'Jordan':                 'Jordania',
    'Portugal':               'Portugal',
    'DR Congo':               'RD Congo',
    'Congo DR':               'RD Congo',  # nombre alterno devuelto por la API para r32
    'Uzbekistan':             'Uzbekistán',
    'Colombia':               'Colombia',
    'England':                'Inglaterra',
    'Croatia':                'Croacia',
    'Ghana':                  'Ghana',
    'Panama':                 'Panamá',
}

def traducir_equipo(nombre: str) -> str:
    return EQUIPO_MAP.get(nombre, nombre)

# ============================================================
# CLIENTE SUPABASE
# ============================================================
def get_supabase() -> Client:
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        print('ERROR: Variables SUPABASE_URL y SUPABASE_SERVICE_KEY requeridas.')
        sys.exit(1)
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ============================================================
# API FOOTBALL-DATA.ORG
# ============================================================
def fetch_matches() -> list:
    if not FOOTBALL_API_KEY:
        print('WARN: FOOTBALL_API_KEY no configurada. Saltando fetch de API.')
        return []

    url = f'{FOOTBALL_API_BASE}/competitions/{COMPETITION_CODE}/matches'
    headers = {'X-Auth-Token': FOOTBALL_API_KEY}
    params  = {'season': SEASON}

    try:
        resp = requests.get(url, headers=headers, params=params, timeout=30)
        resp.raise_for_status()
        # football-data.org no manda 'charset' en el Content-Type del JSON; sin esto
        # requests adivina mal la codificacion y los nombres con tilde quedan corruptos
        # (mojibake, ej. "Sudáfrica" -> "SudÃ¡frica").
        data = json.loads(resp.content.decode('utf-8'))
        return data.get('matches', [])
    except requests.HTTPError as e:
        print(f'ERROR HTTP al consultar API: {e} — {resp.text[:200]}')
        return []
    except Exception as e:
        print(f'ERROR al consultar API: {e}')
        return []

def parse_match(m: dict) -> dict | None:
    """Convierte un partido de la API al formato interno."""
    stage = m.get('stage', '')
    fase  = FASE_MAP.get(stage)
    if not fase:
        return None  # Etapa no reconocida

    status      = m.get('status', 'SCHEDULED')
    estado      = STATUS_MAP.get(status, 'pendiente')
    home        = m.get('homeTeam') or {}
    away        = m.get('awayTeam') or {}
    score       = m.get('score', {})

    # En fases eliminatorias, mientras los cruces no esten definidos (grupos
    # sin terminar), la API devuelve homeTeam/awayTeam con name=None (la
    # llave existe, el valor es null). Sin este chequeo se insertarian
    # partidos "None vs None" en la BD. Se descartan hasta que la API
    # confirme los dos equipos del cruce.
    if not home.get('name') or not away.get('name'):
        return None

    # ?? REGLA DE PUNTUACI?N: usar marcador de 90 MINUTOS (regularTime), NO fullTime.
    # fullTime puede incluir goles de pr?rroga, lo cual cambiar?a el marcador que
    # los usuarios pronosticaron. Los goles de pr?rroga y penales NO cuentan para
    # el marcador ? solo definen qui?n avanza (campo avanza_local).
    # Cuando se active este script en producci?n, verificar que la API devuelva
    # regularTime correctamente (algunos endpoints usan fullTime para todo).
    # fullTime NO es confiable como respaldo en vivo: se observo en produccion
    # que la API puede reportar goles de tiempo extra dentro de extraTime aun
    # cuando el marcador real (regla: solo cuentan los 90 min) seguia sin ese
    # gol -- usar fullTime como respaldo inflaba el marcador con datos falsos.
    # Por seguridad solo se usa regularTime; si no esta disponible (partido en
    # vivo, aun sin terminar oficialmente) no se actualiza el marcador y se
    # conserva el ultimo valor conocido (ver 'goles_local'/'goles_visita' en
    # sync_matches, que ya hacen ese fallback al valor existente cuando viene None).
    rt_score    = score.get('regularTime') or {}
    gl_real     = rt_score.get('home')
    gv_real     = rt_score.get('away')
    winner      = score.get('winner')  # HOME_TEAM / AWAY_TEAM / DRAW / null

    # Penales (informativo, no afecta puntos). La API los da en score.penalties.
    pen_score   = score.get('penalties') or {}
    pen_local   = pen_score.get('home')
    pen_visita  = pen_score.get('away')

    group_raw   = m.get('group', '')
    grupo       = group_raw.replace('GROUP_', '').strip() if group_raw else None

    # Minuto en vivo (solo presente mientras estado es IN_PLAY/PAUSED). La API
    # lo devuelve en el nivel raiz del partido, no dentro de "score".
    minuto      = m.get('minute') if estado == 'en_curso' else None

    avanza_local = None
    if estado == 'finalizado' and fase != 'grupos' and winner:
        if winner == 'HOME_TEAM':
            avanza_local = True
        elif winner == 'AWAY_TEAM':
            avanza_local = False
        # DRAW no debería ocurrir en eliminatorias finalizadas

    # Guardia: la API a veces marca FINISHED antes de poblar regularTime.
    # Si el marcador de 90' aún no está disponible, tratar como en_curso
    # para no congelar un resultado incorrecto. El siguiente poll lo cerrará
    # cuando regularTime ya esté completo.
    if estado == 'finalizado' and (gl_real is None or gv_real is None):
        estado       = 'en_curso'
        avanza_local = None

    return {
        'api_id':         str(m.get('id', '')),
        'fase':           fase,
        'grupo':          grupo,
        'equipo_local':   traducir_equipo(home.get('name', home.get('shortName', 'TBD'))),
        'equipo_visita':  traducir_equipo(away.get('name', away.get('shortName', 'TBD'))),
        'fecha_partido':  m.get('utcDate'),
        'sede':           m.get('venue', ''),
        'goles_local':    gl_real,
        'goles_visita':   gv_real,
        'minuto':         minuto,
        'avanza_local':   avanza_local,
        'penales_local':  pen_local,
        'penales_visita': pen_visita,
        'estado':         estado,
        'fuente':         'automatico' if estado == 'finalizado' else 'pendiente',
    }

# ============================================================
# SINCRONIZACIÓN CON SUPABASE
# ============================================================
def sync_matches(sb: Client, api_matches: list) -> list:
    """Actualiza partidos en Supabase. Retorna lista de partidos finalizados nuevos."""
    if not api_matches:
        return []

    # Cargar partidos actuales de la DB
    res = sb.table('partidos').select('*').execute()
    db_partidos = {str(p.get('api_id', '')): p for p in (res.data or []) if p.get('api_id')}
    db_numero   = {p.get('numero'): p for p in (res.data or [])}

    recien_finalizados = []

    for m in api_matches:
        parsed = parse_match(m)
        if not parsed:
            continue

        api_id   = parsed['api_id']
        existing = db_partidos.get(api_id)

        if existing:
            # Actualizar si cambio el estado, el resultado, o si esta en vivo
            # (el minuto cambia en cada poll aunque el marcador no se mueva).
            necesita_update = (
                existing.get('estado') != parsed['estado'] or
                (parsed['goles_local'] is not None and existing.get('goles_local') != parsed['goles_local']) or
                parsed['estado'] == 'en_curso'
            )
            if necesita_update:

                was_not_final = existing.get('estado') != 'finalizado'
                is_now_final  = parsed['estado'] == 'finalizado'

                updates = {
                    # Si la API devuelve el marcador vacio momentaneamente (ej. hueco de
                    # datos a media partida), no machacar un resultado ya conocido con null.
                    'goles_local':    parsed['goles_local'] if parsed['goles_local'] is not None else existing.get('goles_local'),
                    'goles_visita':   parsed['goles_visita'] if parsed['goles_visita'] is not None else existing.get('goles_visita'),
                    'minuto':         parsed['minuto'],
                    'avanza_local':   parsed['avanza_local'],
                    'penales_local':  parsed['penales_local'],
                    'penales_visita': parsed['penales_visita'],
                    'estado':         parsed['estado'],
                    'fuente':         parsed['fuente'],
                    'fecha_partido':  parsed['fecha_partido'],
                    'sede':           parsed.get('sede', existing.get('sede', '')),
                }
                # No sobreescribir resultado manual con resultado de API si ya estaba finalizado
                if existing.get('fuente') == 'manual' and existing.get('estado') == 'finalizado':
                    print(f'  SKIP: {existing["equipo_local"]} vs {existing["equipo_visita"]} — resultado manual, no se sobreescribe.')
                    continue

                sb.table('partidos').update(updates).eq('api_id', api_id).execute()
                print(f'  UPD: {existing["equipo_local"]} vs {existing["equipo_visita"]} — {parsed["estado"]}')

                if was_not_final and is_now_final:
                    recien_finalizados.append({**existing, **updates})

        else:
            # Partido nuevo (generalmente fases eliminatorias)
            print(f'  INSERT: {parsed["equipo_local"]} vs {parsed["equipo_visita"]} ({parsed["fase"]})')
            res2 = sb.table('partidos').insert(parsed).execute()
            if res2.data:
                db_partidos[api_id] = res2.data[0]

    return recien_finalizados

# ============================================================
# CÁLCULO DE PUNTOS
# ============================================================
def calcular_puntos(partido: dict, pronostico: dict) -> int:
    """
    Calcula puntos segun la regla de penales (Option A):
    - Solo se usa el marcador de 90 minutos (regularTime)
    - Exacto: marcador exacto al 90' (incluyendo empates como 2-2 que van a penales)
    - Resultado KO: partido fue a penales (empate 90') -> cualquier empate cuenta
                    partido se definio en 90' -> ganador correcto cuenta
    Sincronizado con calcularPuntos() en v2.html
    """
    fase = partido.get('fase', 'grupos')
    pts  = PUNTOS.get(fase, PUNTOS['grupos'])
    gl_r = partido.get('goles_local')
    gv_r = partido.get('goles_visita')
    gl_p = pronostico.get('goles_local')
    gv_p = pronostico.get('goles_visita')

    if gl_r is None or gv_r is None:
        return 0

    # TODAS las fases usan la misma logica: marcador al final de los 90 minutos.
    # Reglamento: prorroga y penales NO cuentan. Si va a penales, el resultado
    # oficial es EMPATE (mismo trato que grupos). avanza_local solo se usa para
    # el bracket/generar fases, NO para puntos.
    def res(gl, gv):
        if gl > gv: return 'L'
        if gl < gv: return 'V'
        return 'E'
    if gl_p == gl_r and gv_p == gv_r:
        return pts['exacto']
    if res(gl_p, gv_p) == res(gl_r, gv_r):
        return pts['resultado']
    return 0

def actualizar_puntos_partido(sb: Client, partido: dict):
    """Recalcula puntos de todos los pronósticos de un partido finalizado."""
    pid = partido.get('id')
    if not pid:
        return

    res = sb.table('pronosticos').select('*').eq('partido_id', pid).execute()
    prons = res.data or []
    print(f'  Calculando {len(prons)} pronósticos para partido {pid}...')

    for pr in prons:
        puntos = calcular_puntos(partido, pr)
        sb.table('pronosticos').update({
            'puntos':    puntos,
            'calculado': True,
        }).eq('id', pr['id']).execute()

def actualizar_bonus_campeon(sb: Client):
    """Aplica bonus de 20 pts si el campeón ya se conoce."""
    cfg = sb.table('config').select('valor').eq('clave', 'campeon_real').execute()
    if not cfg.data or not cfg.data[0].get('valor'):
        return  # Campeón no definido aún

    campeon_real = cfg.data[0]['valor'].strip()
    print(f'  Campeón real: {campeon_real}')

    res = sb.table('pronostico_campeon').select('*').execute()
    for c in (res.data or []):
        puntos = BONUS_CAMPEON if c.get('equipo') == campeon_real else 0
        sb.table('pronostico_campeon').update({'puntos': puntos}).eq('participante_id', c['participante_id']).execute()

# ============================================================
# FLUJO PRINCIPAL
# ============================================================
def main():
    print(f'=== Quiniela Mundial 2026 — {datetime.now(timezone.utc).isoformat()} ===')

    sb = get_supabase()
    print('Conectado a Supabase ✓')

    # 1. Obtener partidos de la API
    print('\n[1/4] Consultando football-data.org...')
    api_matches = fetch_matches()
    print(f'  {len(api_matches)} partidos obtenidos.')

    # 2. Sincronizar con Supabase
    print('\n[2/4] Sincronizando partidos...')
    recien_finalizados = sync_matches(sb, api_matches)
    print(f'  {len(recien_finalizados)} partidos recién finalizados.')

    # 3. Calcular puntos de partidos recién finalizados
    print('\n[3/4] Calculando puntos...')
    if recien_finalizados:
        for partido in recien_finalizados:
            actualizar_puntos_partido(sb, partido)
    else:
        print('  Sin cambios nuevos.')

    # 4. Bonus campeón
    print('\n[4/4] Verificando bonus campeón...')
    actualizar_bonus_campeon(sb)

    print('\n=== Completado ✓ ===')

if __name__ == '__main__':
    main()
